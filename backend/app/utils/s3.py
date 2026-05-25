import boto3
import uuid
from botocore.exceptions import NoCredentialsError
from fastapi import UploadFile
from typing import Optional
import os
import io
from dotenv import load_dotenv, find_dotenv
from PIL import Image
from urllib.parse import urlparse
import traceback

# Eliminamos la carga global de credenciales porque falla en producción
# si las variables tienen comillas o se leen muy pronto.

def get_s3_config():
    """Obtiene y limpia las credenciales cada vez que se necesitan."""
    access_key = os.getenv('AWS_ACCESS_KEY_ID', '').replace('"', '').replace("'", '').strip()
    secret_key = os.getenv('AWS_SECRET_ACCESS_KEY', '').replace('"', '').replace("'", '').strip()
    region = os.getenv('AWS_REGION', 'us-east-1').replace('"', '').replace("'", '').strip()
    bucket_name = os.getenv('AWS_BUCKET_NAME', '').replace('"', '').replace("'", '').strip()
    
    if not access_key or not secret_key or not bucket_name:
        raise ValueError("Faltan credenciales de AWS o el nombre del Bucket en el entorno.")
        
    s3_client = boto3.client(
        's3',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name=region
    )
    return s3_client, bucket_name


async def upload_file_to_s3(file: UploadFile) -> str:
    try:
        s3_client, bucket_name = get_s3_config()

        # 1. Leemos el archivo original
        image_data = await file.read()
        
        # 2. Abrimos la imagen con Pillow
        image = Image.open(io.BytesIO(image_data))
        
        # Si la imagen es PNG, la pasamos a RGB
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")
        
        # 3. Comprimimos la imagen
        compressed_image_io = io.BytesIO()
        image.save(compressed_image_io, format='JPEG', optimize=True, quality=60) 
        compressed_image_io.seek(0) 
        
        # 4. Generamos nombre único
        file_extension = ".jpg"
        unique_filename = f"users/profile_{uuid.uuid4()}{file_extension}"
        
        # 5. Subimos a AWS S3
        print(f"🚀 Intentando subir a S3: {unique_filename}...")
        s3_client.upload_fileobj(
            compressed_image_io, 
            bucket_name,
            unique_filename,
            ExtraArgs={
                "ContentType": "image/jpeg",
            }
        )
        print("✅ ¡Subida exitosa a AWS S3!")
        
        # 6. Devolvemos la URL
        return f"https://{bucket_name}.s3.amazonaws.com/{unique_filename}"

    except Exception as e:
        # 🚨 AQUÍ ATRAPAMOS AL FANTASMA
        print("\n" + "="*50)
        print("💥 ERROR CRÍTICO AL SUBIR LA IMAGEN A S3 💥")
        print("="*50)
        print(traceback.format_exc()) # Esto imprime la línea exacta del fallo
        print("="*50 + "\n")
        raise e # Volvemos a lanzar el error para que FastAPI responda 500

def delete_old_file_from_s3(s3_url: str):
    try:
        s3_client, bucket_name = get_s3_config()
        # 1. Extraemos la "llave" (Key) exacta de la URL de S3
        # Ejemplo: Si la URL es https://bucket.s3.amazonaws.com/avatars/123.jpg
        # Esto extrae solo: "avatars/123.jpg"
        parsed_url = urlparse(s3_url)
        s3_key = parsed_url.path.lstrip('/') 
        
        # 2. Le disparamos a S3 para que lo borre
        s3_client.delete_object(Bucket=bucket_name, Key=s3_key)
        print(f"✅ Basura espacial eliminada de S3: {s3_key}")
        
    except Exception as e:
        print(f"❌ Error al intentar borrar de S3: {e}")

async def upload_service_evidence_to_s3(file: UploadFile, service_id: str) -> Optional[str]:
    """
    Sube una foto de evidencia a S3 en su propia carpeta por servicio.
    Ruta en S3: servicios/{service_id}/evidencias/{uuid}.jpg
    """
    try:
        s3_client, bucket_name = get_s3_config()

        # 1. Procesamiento de imagen (igual que antes)
        image_data = await file.read()
        image = Image.open(io.BytesIO(image_data))
        
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")
            
        compressed_image_io = io.BytesIO()
        # Calidad 70 es un buen balance para evidencias
        image.save(compressed_image_io, format='JPEG', optimize=True, quality=70) 
        compressed_image_io.seek(0) 

        # 2. Generamos la RUTA DINÁMICA
        file_extension = ".jpg"
        # 👇 LA MAGIA ESTÁ AQUÍ: Estructura de carpetas limpia
        s3_key = f"servicios/{service_id}/evidencias/foto_{uuid.uuid4()}{file_extension}"

        print(f"🚀 Subiendo evidencia a S3 en: {s3_key}...")
        
        # 3. Subimos a AWS
        s3_client.upload_fileobj(
            compressed_image_io, 
            bucket_name,
            s3_key,
            ExtraArgs={
                "ContentType": "image/jpeg",
            }
        )
        print("¡Imagenes cargadas exitosamente!")

        # 4. Devolvemos la URL pública
        return f"https://{bucket_name}.s3.amazonaws.com/{s3_key}"

    except Exception as e:
        print("💥 ERROR AL SUBIR EVIDENCIA A S3 💥")
        print(traceback.format_exc())
        return None # Retornamos None si falla, para que no truene todo el endpoint

async def upload_chat_media_to_s3(file: UploadFile, conversation_id: str) -> Optional[str]:
    """
    Sube un archivo de chat (imagen, video o audio) a S3.
    """
    try:
        s3_client, bucket_name = get_s3_config()
        
        filename = file.filename or "file"
        ext = os.path.splitext(filename)[1].lower()
        content_type = (file.content_type or "").lower()
        if not ext:
            # Fallback based on content type
            if "image" in content_type: ext = ".jpg"
            elif "video" in content_type: ext = ".mp4"
            elif "audio" in content_type: ext = ".m4a"
            elif "octet-stream" in content_type: ext = ".m4a"  # Fallback común de iOS/Android
            else: ext = ".m4a"  # Para audios grabados sin extensión conocida

        # Aseguramos que archivos de audio con extensiones conocidas tengan el content_type correcto
        audio_exts = [".m4a", ".mp3", ".ogg", ".wav", ".aac", ".opus"]
        if not content_type or content_type == "application/octet-stream":
            if ext in [".jpg", ".jpeg", ".png", ".webp"]: content_type = "image/jpeg"
            elif ext in [".mp4", ".mov", ".mkv"]: content_type = "video/mp4"
            elif ext in audio_exts: content_type = f"audio/{ext.lstrip('.')}"

        s3_key = f"chats/{conversation_id}/media_{uuid.uuid4()}{ext}"
        
        # 🟢 TRATAMIENTO PARA IMÁGENES (Compresión)
        if ext in [".jpg", ".jpeg", ".png", ".webp"]:
            image_data = await file.read()
            image = Image.open(io.BytesIO(image_data))
            
            if image.mode in ("RGBA", "P"):
                image = image.convert("RGB")
                
            compressed_image_io = io.BytesIO()
            image.save(compressed_image_io, format='JPEG', optimize=True, quality=65) 
            compressed_image_io.seek(0)
            
            s3_client.upload_fileobj(
                compressed_image_io, 
                bucket_name,
                s3_key,
                ExtraArgs={"ContentType": "image/jpeg"}
            )
        else:
            # 🔵 TRATAMIENTO PARA AUDIO/VIDEO (Subida directa)
            await file.seek(0)
            upload_content_type = content_type if content_type else "application/octet-stream"
            s3_client.upload_fileobj(
                file.file, 
                bucket_name,
                s3_key,
                ExtraArgs={"ContentType": upload_content_type}
            )

        return f"https://{bucket_name}.s3.amazonaws.com/{s3_key}"

    except Exception as e:
        print("💥 ERROR AL SUBIR MEDIA DE CHAT A S3 💥")
        print(traceback.format_exc())
        return None