import io
import os
import uuid
import logging
from datetime import datetime
from urllib.parse import urlparse
from typing import Optional, List, Dict, Any

from PIL import Image
from sqlalchemy.orm import Session
from fastapi import HTTPException, UploadFile
import boto3

from app.auth import models
from app.utils.s3 import get_s3_config, get_s3_public_url
from app.services.notifications.service import create_in_app_notification

logger = logging.getLogger(__name__)


def _get_status_value(verification: Any) -> str:
    """Obtiene el valor string del estado de forma segura ante analizadores de tipos."""
    status = getattr(verification, "status", None)
    if hasattr(status, "value"):
        return str(status.value)
    return str(status) if status else "pending"


def create_verification(db: Session, user_id: str, ine_front: UploadFile, ine_back: UploadFile, selfie: UploadFile) -> Dict[str, Any]:
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    existing = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.user_id == user_id,
        models.IdentityVerification.status == models.VerificationStatus.PENDING
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Ya tienes una verificación pendiente. Espera a que sea revisada.")

    try:
        s3_client, bucket_name = get_s3_config()

        def upload_image(file: UploadFile, prefix: str) -> str:
            image_data = file.file.read()
            image = Image.open(io.BytesIO(image_data))
            if image.mode in ("RGBA", "P"):
                image = image.convert("RGB")
            compressed = io.BytesIO()
            image.save(compressed, format='JPEG', optimize=True, quality=70)
            compressed.seek(0)
            file.file.seek(0)
            key = f"verifications/{user_id}/{prefix}_{uuid.uuid4()}.jpg"
            s3_client.upload_fileobj(compressed, bucket_name, key, ExtraArgs={"ContentType": "image/jpeg"})
            return get_s3_public_url(key)

        ine_front_url = upload_image(ine_front, "ine_front")
        ine_back_url = upload_image(ine_back, "ine_back")
        selfie_url = upload_image(selfie, "selfie")

        face_similarity = compare_faces_rekognition(bucket_name, ine_front_url, selfie_url)

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error al procesar las imágenes de verificación: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error al procesar las imágenes: {str(e)}")

    verification = models.IdentityVerification(
        id=str(uuid.uuid4()),
        user_id=user_id,
        ine_front_url=ine_front_url,
        ine_back_url=ine_back_url,
        selfie_url=selfie_url,
        face_similarity=face_similarity,
    )

    status_text = "pendiente"
    if face_similarity is not None:
        if face_similarity >= 95:
            setattr(verification, "status", models.VerificationStatus.APPROVED)
            setattr(user, "is_identity_verified", True)
            status_text = "aprobada automáticamente"
        elif face_similarity < 80:
            setattr(verification, "status", models.VerificationStatus.REJECTED)
            setattr(verification, "rejection_reason", "Las fotos no coinciden. Asegúrate de que la selfie sea de la misma persona que la INE.")
            status_text = "rechazada automáticamente"

    db.add(verification)
    db.commit()
    db.refresh(verification)

    is_pending = getattr(verification, "status", None) == models.VerificationStatus.PENDING

    return {
        "id": verification.id,
        "status": _get_status_value(verification),
        "face_similarity": verification.face_similarity,
        "message": f"Verificación {status_text}",
        "needs_review": is_pending
    }


def compare_faces_rekognition(bucket_name: str, source_url: str, target_url: str) -> Optional[float]:
    """
    Compara rostros usando AWS Rekognition si las credenciales de AWS nativas están configuradas.
    Si se usa Cloudflare R2 o no hay credenciales de AWS Rekognition, omite la comparación automática.
    """
    try:
        access_key = os.getenv('AWS_ACCESS_KEY_ID', '').replace('"', '').replace("'", '').strip()
        secret_key = os.getenv('AWS_SECRET_ACCESS_KEY', '').replace('"', '').replace("'", '').strip()
        region = os.getenv('AWS_REGION', 'us-east-1').replace('"', '').replace("'", '').strip()
        endpoint_url = os.getenv('AWS_ENDPOINT_URL', os.getenv('S3_ENDPOINT_URL', '')).strip()

        # Rekognition es un servicio de AWS. Si se usa Cloudflare R2 (endpoint externo o region auto),
        # no se puede consultar Rekognition nativo de AWS contra objetos de R2.
        if endpoint_url or region == 'auto' or not access_key or not secret_key:
            logger.info("Rekognition omitido: almacenamiento externo (R2) o faltan credenciales AWS.")
            return None

        client = boto3.client(
            'rekognition',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region
        )

        source_key = urlparse(source_url).path.lstrip('/')
        target_key = urlparse(target_url).path.lstrip('/')
        
        response = client.compare_faces(
            SourceImage={'S3Object': {'Bucket': bucket_name, 'Name': source_key}},
            TargetImage={'S3Object': {'Bucket': bucket_name, 'Name': target_key}},
            SimilarityThreshold=80
        )

        if response.get('FaceMatches'):
            similarity = float(response['FaceMatches'][0]['Similarity'])
            return similarity
        else:
            return 0.0

    except Exception as e:
        logger.warning("No se pudo ejecutar la comparación facial automática con Rekognition: %s", e)
        return None


def get_verification_status(db: Session, user_id: str) -> Dict[str, Any]:
    verification = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.user_id == user_id
    ).order_by(models.IdentityVerification.created_at.desc()).first()

    user = db.query(models.User).filter(models.User.id == user_id).first()
    is_pending = getattr(verification, "status", None) == models.VerificationStatus.PENDING if verification else False

    return {
        "is_identity_verified": bool(getattr(user, "is_identity_verified", False)) if user else False,
        "has_pending_verification": is_pending,
        "verification": {
            "id": verification.id,
            "status": _get_status_value(verification),
            "face_similarity": verification.face_similarity,
            "rejection_reason": verification.rejection_reason,
            "created_at": verification.created_at.isoformat() if verification and verification.created_at else None,
        } if verification else None
    }


def get_pending_verifications_admin(db: Session) -> List[Dict[str, Any]]:
    verifications = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.status == models.VerificationStatus.PENDING
    ).order_by(models.IdentityVerification.created_at.asc()).all()

    result = []
    for v in verifications:
        user = db.query(models.User).filter(models.User.id == v.user_id).first()
        result.append({
            "id": v.id,
            "user_id": v.user_id,
            "user_name": user.full_name if user else "Desconocido",
            "user_email": user.email if user else "",
            "ine_front_url": v.ine_front_url,
            "ine_back_url": v.ine_back_url,
            "selfie_url": v.selfie_url,
            "status": _get_status_value(v),
            "face_similarity": v.face_similarity,
            "created_at": v.created_at.isoformat() if v.created_at else None,
        })
    return result


def approve_verification_admin(db: Session, verification_id: str, admin_id: str) -> Dict[str, Any]:
    verification = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.id == verification_id
    ).first()
    if not verification:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    user = db.query(models.User).filter(models.User.id == verification.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    setattr(verification, "status", models.VerificationStatus.APPROVED)
    setattr(verification, "reviewed_by", admin_id)
    setattr(verification, "reviewed_at", datetime.utcnow())
    setattr(user, "is_identity_verified", True)

    db.commit()

    create_in_app_notification(
        db,
        user_id=str(user.id),
        title="Identidad Verificada",
        body="Tu verificación de identidad ha sido aprobada. Ya apareces como usuario verificado.",
        notification_type="verification_approved",
        reference_id=str(verification.id),
        target_role="client"
    )

    return {"message": "Verificación aprobada", "status": "approved"}


def reject_verification_admin(db: Session, verification_id: str, admin_id: str, reason: str) -> Dict[str, Any]:
    verification = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.id == verification_id
    ).first()
    if not verification:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    setattr(verification, "status", models.VerificationStatus.REJECTED)
    setattr(verification, "rejection_reason", reason)
    setattr(verification, "reviewed_by", admin_id)
    setattr(verification, "reviewed_at", datetime.utcnow())

    db.commit()

    create_in_app_notification(
        db,
        user_id=str(verification.user_id),
        title="Verificación Rechazada",
        body=f"Tu verificación fue rechazada. Motivo: {reason}. Puedes intentarlo de nuevo desde tu perfil.",
        notification_type="verification_rejected",
        reference_id=str(verification.id),
        target_role="client"
    )

    return {"message": "Verificación rechazada", "status": "rejected"}
