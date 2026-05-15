from sqlalchemy.orm import Session
from fastapi import HTTPException, UploadFile
from app.auth import models
from app.utils.s3 import get_s3_config  # type: ignore
import uuid
import traceback


def create_verification(db: Session, user_id: str, ine_front: UploadFile, ine_back: UploadFile, selfie: UploadFile):
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
            import io
            from PIL import Image
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
            return f"https://{bucket_name}.s3.amazonaws.com/{key}"

        ine_front_url = upload_image(ine_front, "ine_front")
        ine_back_url = upload_image(ine_back, "ine_back")
        selfie_url = upload_image(selfie, "selfie")

        face_similarity = compare_faces_rekognition(bucket_name, ine_front_url, selfie_url)

    except Exception as e:
        print(f"Error subiendo archivos: {traceback.format_exc()}")
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
            verification.status = models.VerificationStatus.APPROVED
            user.is_identity_verified = True
            status_text = "aprobada automáticamente"
        elif face_similarity < 80:
            verification.status = models.VerificationStatus.REJECTED
            verification.rejection_reason = "Las fotos no coinciden. Asegúrate de que la selfie sea de la misma persona que la INE."
            status_text = "rechazada automáticamente"

    db.add(verification)
    db.commit()
    db.refresh(verification)

    return {
        "id": verification.id,
        "status": verification.status.value,
        "face_similarity": verification.face_similarity,
        "message": f"Verificación {status_text}",
        "needs_review": verification.status == models.VerificationStatus.PENDING
    }


def compare_faces_rekognition(bucket_name: str, source_url: str, target_url: str) -> float | None:
    import boto3
    import os
    from urllib.parse import urlparse

    try:
        access_key = os.getenv('AWS_ACCESS_KEY_ID', '').replace('"', '').replace("'", '').strip()
        secret_key = os.getenv('AWS_SECRET_ACCESS_KEY', '').replace('"', '').replace("'", '').strip()
        region = os.getenv('AWS_REGION', 'us-east-1').replace('"', '').replace("'", '').strip()

        if not access_key or not secret_key:
            print("AWS Rekognition: credenciales no configuradas.")
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
            return response['FaceMatches'][0]['Similarity']
        return 0.0

    except Exception as e:
        print(f"Rekognition error: {e}")
        return None


def get_verification_status(db: Session, user_id: str):
    verification = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.user_id == user_id
    ).order_by(models.IdentityVerification.created_at.desc()).first()

    user = db.query(models.User).filter(models.User.id == user_id).first()

    return {
        "is_identity_verified": bool(user.is_identity_verified) if user else False,
        "has_pending_verification": verification is not None and verification.status == models.VerificationStatus.PENDING,
        "verification": {
            "id": verification.id,
            "status": verification.status.value,
            "face_similarity": verification.face_similarity,
            "rejection_reason": verification.rejection_reason,
            "created_at": verification.created_at.isoformat() if verification and verification.created_at else None,
        } if verification else None
    }


def get_pending_verifications_admin(db: Session):
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
            "status": v.status.value,
            "face_similarity": v.face_similarity,
            "created_at": v.created_at.isoformat() if v.created_at else None,
        })
    return result


def approve_verification_admin(db: Session, verification_id: str, admin_id: str):
    verification = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.id == verification_id
    ).first()
    if not verification:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    user = db.query(models.User).filter(models.User.id == verification.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    verification.status = models.VerificationStatus.APPROVED
    verification.reviewed_by = admin_id
    verification.reviewed_at = None
    from datetime import datetime
    verification.reviewed_at = datetime.utcnow()
    user.is_identity_verified = True

    db.commit()
    return {"message": "Verificación aprobada", "status": "approved"}


def reject_verification_admin(db: Session, verification_id: str, admin_id: str, reason: str):
    verification = db.query(models.IdentityVerification).filter(
        models.IdentityVerification.id == verification_id
    ).first()
    if not verification:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    verification.status = models.VerificationStatus.REJECTED
    verification.rejection_reason = reason
    verification.reviewed_by = admin_id
    from datetime import datetime
    verification.reviewed_at = datetime.utcnow()

    db.commit()
    return {"message": "Verificación rechazada", "status": "rejected"}
