import stripe
import logging
from fastapi import APIRouter, Request, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.core.config import STRIPE_WEBHOOK_SECRET
from . import models

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/stripe/webhook")
async def stripe_webhook(request: Request):
    """
    Endpoint para webhooks de Stripe.
    Stripe envía eventos asíncronos aquí (pagos fallidos, disputas, etc.).
    """
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    if not sig_header:
        raise HTTPException(status_code=400, detail="Firma webhook faltante")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Payload inválido")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Firma inválida")

    handler = EVENT_HANDLERS.get(event["type"])
    if handler:
        try:
            handler(event["data"]["object"])
        except Exception as e:
            logger.error(f"Error manejando evento {event['type']}: {e}", exc_info=True)
    else:
        logger.info(f"Evento no manejado: {event['type']}")

    return {"status": "ok"}


# -----------------------------------------------------------
# Manejadores de eventos
# -----------------------------------------------------------

def _handle_payment_intent_failed(payment_intent: dict):
    """El pago falló en Stripe (fondos insuficientes, tarjeta rechazada, etc.)."""
    pi_id = payment_intent["id"]
    db = SessionLocal()
    try:
        payment = db.query(models.Payment).filter(
            models.Payment.stripe_payment_intent_id == pi_id
        ).first()
        if payment and payment.status != models.PaymentStatus.FAILED:
            payment.status = models.PaymentStatus.FAILED
            db.commit()
            logger.info(f"Pago {payment.id} marcado como FAILED por webhook")
            _notify_payment_failed(db, payment)
    except Exception as e:
        logger.error(f"Error en webhook payment_intent.payment_failed: {e}")
        db.rollback()
    finally:
        db.close()


def _notify_payment_failed(db: Session, payment):
    """Notifica al cliente que su pago falló."""
    try:
        from app.services.notifications import service as notif_service
        from app.services.models import Contract, Job
        contract = db.query(Contract).filter(Contract.id == payment.contract_id).first()
        if contract and contract.job:
            job = contract.job
            service_title = "Servicio"
            if job.request and job.request.service:
                service_title = job.request.service.title
            notif_service.create_in_app_notification(
                db=db,
                user_id=str(job.client_id),
                title="Pago fallido",
                body=f"El pago por ${payment.amount} para '{service_title}' no pudo procesarse. Intenta de nuevo.",
                notification_type="payment_failed",
                reference_id=str(job.id),
            )
            logger.info(f"Notificación de pago fallido enviada al cliente {job.client_id}")
    except Exception as e:
        logger.error(f"Error notificando pago fallido: {e}")


def _handle_charge_dispute_created(dispute: dict):
    """Se creó una disputa/contracargo en Stripe."""
    pi_id = dispute.get("payment_intent")
    if not pi_id:
        return
    db = SessionLocal()
    try:
        payment = db.query(models.Payment).filter(
            models.Payment.stripe_payment_intent_id == pi_id
        ).first()
        if payment:
            logger.warning(
                f"Disputa creada para pago {payment.id} "
                f"(PaymentIntent: {pi_id})"
            )
    except Exception as e:
        logger.error(f"Error en webhook charge.dispute.created: {e}")
    finally:
        db.close()


def _handle_payment_intent_succeeded(payment_intent: dict):
    """
    El PaymentIntent se completó exitosamente en Stripe.
    Esto es un respaldo por si confirm-escrow nunca se llamó
    (ej. la app se cayó después del pago pero antes del callback).
    """
    pi_id = payment_intent["id"]
    if payment_intent.get("capture_method") == "manual" and payment_intent.get("status") == "requires_capture":
        db = SessionLocal()
        try:
            payment = db.query(models.Payment).filter(
                models.Payment.stripe_payment_intent_id == pi_id
            ).first()
            if payment and payment.status == models.PaymentStatus.PENDING:
                payment.status = models.PaymentStatus.HELD_IN_ESCROW
                contract = db.query(models.Contract).filter(
                    models.Contract.id == payment.contract_id
                ).first()
                if contract:
                    contract.status = "in_progress"
                db.commit()
                logger.info(
                    f"Webhook: Pago {payment.id} recuperado a HELD_IN_ESCROW "
                    f"(confirm-escrow no se llamó)"
                )
        except Exception as e:
            logger.error(f"Error en webhook payment_intent.succeeded: {e}")
            db.rollback()
        finally:
            db.close()


def _handle_charge_refunded(charge: dict):
    """Un reembolso se completó en Stripe."""
    pi_id = charge.get("payment_intent")
    if not pi_id:
        return
    db = SessionLocal()
    try:
        payment = db.query(models.Payment).filter(
            models.Payment.stripe_payment_intent_id == pi_id
        ).first()
        if payment and payment.status != models.PaymentStatus.REFUNDED:
            payment.status = models.PaymentStatus.REFUNDED
            contract = db.query(models.Contract).filter(
                models.Contract.id == payment.contract_id
            ).first()
            if contract:
                contract.status = "cancelled"
            db.commit()
            logger.info(f"Pago {payment.id} marcado como REFUNDED por charge.refunded")
    except Exception as e:
        logger.error(f"Error en webhook charge.refunded: {e}")
        db.rollback()
    finally:
        db.close()


def _handle_payment_intent_canceled(payment_intent: dict):
    """Un PaymentIntent fue cancelado en Stripe."""
    pi_id = payment_intent["id"]
    db = SessionLocal()
    try:
        payment = db.query(models.Payment).filter(
            models.Payment.stripe_payment_intent_id == pi_id
        ).first()
        if payment and payment.status not in (
            models.PaymentStatus.FAILED,
            models.PaymentStatus.REFUNDED,
        ):
            payment.status = models.PaymentStatus.FAILED
            db.commit()
            logger.info(f"Pago {payment.id} marcado como FAILED por payment_intent.canceled")
    except Exception as e:
        logger.error(f"Error en webhook payment_intent.canceled: {e}")
        db.rollback()
    finally:
        db.close()


def _handle_charge_dispute_closed(dispute: dict):
    """Una disputa se resolvió (won/lost)."""
    status = dispute.get("status")
    pi_id = dispute.get("payment_intent")
    if not pi_id:
        return
    db = SessionLocal()
    try:
        payment = db.query(models.Payment).filter(
            models.Payment.stripe_payment_intent_id == pi_id
        ).first()
        if not payment:
            return
        if status == "lost":
            payment.status = models.PaymentStatus.REFUNDED
            contract = db.query(models.Contract).filter(
                models.Contract.id == payment.contract_id
            ).first()
            if contract:
                contract.status = "cancelled"
            db.commit()
            logger.warning(f"Disputa PERDIDA para pago {payment.id} — reembolsado")
        elif status == "won":
            logger.info(f"Disputa GANADA para pago {payment.id} — todo en orden")
    except Exception as e:
        logger.error(f"Error en webhook charge.dispute.closed: {e}")
        db.rollback()
    finally:
        db.close()


EVENT_HANDLERS = {
    "payment_intent.payment_failed": _handle_payment_intent_failed,
    "payment_intent.succeeded": _handle_payment_intent_succeeded,
    "charge.dispute.created": _handle_charge_dispute_created,
    "charge.refunded": _handle_charge_refunded,
    "payment_intent.canceled": _handle_payment_intent_canceled,
    "charge.dispute.closed": _handle_charge_dispute_closed,
}
