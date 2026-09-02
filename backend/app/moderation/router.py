from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import logging

from app.db.database import get_db
from app.auth.security import get_current_user, check_role
from app.core.roles import Role
from app.auth import models as auth_models
from app.services import models as service_models
from app.moderation import schemas

logger = logging.getLogger(__name__)

router = APIRouter()


def _enrich_report(report: service_models.Report, db: Session) -> dict:
    reporter = db.query(auth_models.User).filter(
        auth_models.User.id == report.reporter_id
    ).first()
    reported_user = db.query(auth_models.User).filter(
        auth_models.User.id == report.reported_user_id
    ).first() if report.reported_user_id else None
    admin = db.query(auth_models.User).filter(
        auth_models.User.id == report.admin_id
    ).first() if report.admin_id else None

    return {
        "id": report.id,
        "reporter_id": report.reporter_id,
        "reported_user_id": report.reported_user_id,
        "reported_service_id": report.reported_service_id,
        "reason": report.reason.value if hasattr(report.reason, 'value') else str(report.reason),
        "description": report.description,
        "status": report.status.value if hasattr(report.status, 'value') else str(report.status),
        "admin_id": report.admin_id,
        "admin_note": report.admin_note,
        "created_at": report.created_at,
        "resolved_at": report.resolved_at,
        "reporter_name": reporter.full_name if reporter else "Usuario",
        "reported_user_name": reported_user.full_name if reported_user else None,
        "admin_name": admin.full_name if admin else None,
    }


@router.post("/report")
def create_report(
    data: schemas.ReportCreate,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(get_current_user)
):
    try:
        if not data.reported_user_id and not data.reported_service_id:
            raise HTTPException(status_code=400, detail="Debes reportar un usuario o un servicio")

        if data.reported_service_id:
            service = db.query(service_models.Service).filter(
                service_models.Service.id == data.reported_service_id
            ).first()
            if not service:
                raise HTTPException(status_code=404, detail="Servicio no encontrado")
            if str(service.client_id) == str(current_user.id):
                raise HTTPException(status_code=400, detail="No puedes reportar tu propio servicio")
            if not data.reported_user_id:
                data.reported_user_id = str(service.client_id)

        if data.reported_user_id and str(data.reported_user_id) == str(current_user.id):
            raise HTTPException(status_code=400, detail="No puedes reportarte a ti mismo")

        try:
            reason_enum = service_models.ReportReason(data.reason)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Motivo no valido: {data.reason}")

        existing = db.query(service_models.Report).filter(
            service_models.Report.reporter_id == str(current_user.id),
            service_models.Report.reported_user_id == data.reported_user_id,
            service_models.Report.status == service_models.ReportStatus.PENDING
        ).first()

        if existing:
            raise HTTPException(status_code=409, detail="Ya reportaste a este usuario y esta pendiente de revision")

        report = service_models.Report(
            reporter_id=str(current_user.id),
            reported_user_id=data.reported_user_id,
            reported_service_id=data.reported_service_id,
            reason=reason_enum,
            description=data.description,
            status=service_models.ReportStatus.PENDING,
        )
        db.add(report)
        db.commit()
        db.refresh(report)

        if data.reported_service_id:
            service = db.query(service_models.Service).filter(
                service_models.Service.id == data.reported_service_id
            ).first()
            if service:
                service.is_reported = True
                db.commit()

        from app.admin.ws_manager import recalculate_and_broadcast
        recalculate_and_broadcast(db)

        return {"status": "success", "message": "Reporte enviado. Un administrador lo revisara."}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error creando reporte: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.get("/admin/reports")
def list_reports(
    status: str = None,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    query = db.query(service_models.Report).order_by(
        service_models.Report.created_at.desc()
    )
    if status:
        try:
            status_enum = service_models.ReportStatus(status)
            query = query.filter(service_models.Report.status == status_enum)
        except ValueError as e:
            logger.warning("Filtro de status inválido en reportes: %s", e)

    reports = query.all()
    return [_enrich_report(r, db) for r in reports]


@router.get("/admin/reports/{report_id}")
def get_report_detail(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    report = db.query(service_models.Report).filter(
        service_models.Report.id == report_id
    ).first()
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")

    result = _enrich_report(report, db)

    if report.reported_service_id:
        service = db.query(service_models.Service).filter(
            service_models.Service.id == report.reported_service_id
        ).first()
        if service:
            result["service"] = {
                "id": service.id,
                "title": service.title,
                "description": service.description,
                "is_active": service.is_active,
            }

    return result


@router.post("/admin/reports/{report_id}/resolve")
def resolve_report(
    report_id: str,
    data: schemas.ReportRespond,
    db: Session = Depends(get_db),
    current_user: auth_models.User = Depends(check_role([Role.ADMIN]))
):
    report = db.query(service_models.Report).filter(
        service_models.Report.id == report_id
    ).first()
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")

    if report.status != service_models.ReportStatus.PENDING:
        raise HTTPException(status_code=400, detail="Este reporte ya fue resuelto")

    action = data.action
    if action == "ban_user":
        if report.reported_user_id:
            user = db.query(auth_models.User).filter(
                auth_models.User.id == report.reported_user_id
            ).first()
            if user:
                user.is_banned = True
                user.is_active = False
            report.status = service_models.ReportStatus.RESOLVED_BANNED
    elif action == "ban_service":
        if report.reported_service_id:
            service = db.query(service_models.Service).filter(
                service_models.Service.id == report.reported_service_id
            ).first()
            if service:
                service.is_active = False
            report.status = service_models.ReportStatus.RESOLVED_SERVICE_BANNED
    elif action == "dismiss":
        report.status = service_models.ReportStatus.DISMISSED
    else:
        raise HTTPException(status_code=400, detail=f"Accion no valida: {action}")

    report.admin_id = str(current_user.id)
    report.admin_note = data.admin_note
    report.resolved_at = service_models.datetime.utcnow()

    if report.reported_service_id:
        pending = db.query(service_models.Report).filter(
            service_models.Report.reported_service_id == report.reported_service_id,
            service_models.Report.status == service_models.ReportStatus.PENDING
        ).count()
        if pending == 0:
            service = db.query(service_models.Service).filter(
                service_models.Service.id == report.reported_service_id
            ).first()
            if service:
                service.is_reported = False

    db.commit()
    db.refresh(report)

    from app.admin.ws_manager import recalculate_and_broadcast
    recalculate_and_broadcast(db)

    return {"status": "success", "message": "Reporte resuelto", "report": _enrich_report(report, db)}
