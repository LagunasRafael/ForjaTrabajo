import boto3
import uuid
from botocore.exceptions import NoCredentialsError
from fastapi import UploadFile
import os
import io
from dotenv import load_dotenv, find_dotenv
from PIL import Image
from urllib.parse import urlparse

# 1. Forzamos la búsqueda del archivo y vemos DÓNDE lo encuentra
ruta_env = find_dotenv()
print("👀 RUTA DEL ARCHIVO .ENV:", ruta_env)

# 2. Cargamos el archivo
load_dotenv(ruta_env)

# 3. Leemos las variables
AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# OJO AQUÍ: Asegúrate de que el nombre de la variable coincida con tu .env
BUCKET_NAME = os.getenv('AWS_BUCKET_NAME') 

# 4. IMPRIMIMOS LO QUE PYTHON VE (solo para encontrar el error)
print("🔑 ACCESS KEY CARGADA:", "SÍ" if AWS_ACCESS_KEY else "NO (Está vacía)")
print("🪣 BUCKET NAME CARGADO:", BUCKET_NAME)
# Configuramos el cliente de Amazon
s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_REGION', 'us-east-1')
)


async def upload_file_to_s3(file: UploadFile) -> str:

    # 🚨 Validación rápida para que sepas si el .env falló antes de procesar la imagen
    if not BUCKET_NAME or not AWS_ACCESS_KEY:
        raise ValueError("Faltan las credenciales de AWS en el archivo .env")

    # 1. Leemos el archivo original que subió el usuario
    image_data = await file.read()
    
    # 2. Abrimos la imagen con Pillow
    image = Image.open(io.BytesIO(image_data))
    
    # Si la imagen es PNG (tiene transparencia), la pasamos a RGB para poder hacerla JPEG
    if image.mode in ("RGBA", "P"):
        image = image.convert("RGB")
    
    # 3. Comprimimos la imagen en memoria (BytesIO)
    compressed_image_io = io.BytesIO()
    # quality=60 reduce muchísimo el peso casi sin perder nitidez visual
    # optimize=True le dice a Pillow que quite metadatos innecesarios
    image.save(compressed_image_io, format='JPEG', optimize=True, quality=60) 
    compressed_image_io.seek(0) # Regresamos el "cursor" al inicio del archivo
    
    # 4. Generamos un nombre único y seguro
    file_extension = ".jpg"
    unique_filename = f"users/profile_{uuid.uuid4()}{file_extension}"
    
    # 5. Subimos la versión COMPRIMIDA a AWS S3
    s3_client.upload_fileobj(
        compressed_image_io, # Mandamos el archivo ligero
        BUCKET_NAME,
        unique_filename,
        ExtraArgs={
            "ContentType": "image/jpeg",
            # "ACL": "public-read" # Descomenta esto si tu bucket permite archivos públicos
        }
    )
    
    # 6. Devolvemos la URL pública
    file_url = f"https://{BUCKET_NAME}.s3.amazonaws.com/{unique_filename}"
    return file_url

def delete_old_file_from_s3(s3_url: str):
    try:
        # 1. Extraemos la "llave" (Key) exacta de la URL de S3
        # Ejemplo: Si la URL es https://bucket.s3.amazonaws.com/avatars/123.jpg
        # Esto extrae solo: "avatars/123.jpg"
        parsed_url = urlparse(s3_url)
        s3_key = parsed_url.path.lstrip('/') 
        
        # 2. Le disparamos a S3 para que lo borre
        s3_client.delete_object(Bucket=BUCKET_NAME, Key=s3_key)
        print(f"✅ Basura espacial eliminada de S3: {s3_key}")
        
    except Exception as e:
        print(f"❌ Error al intentar borrar de S3: {e}")