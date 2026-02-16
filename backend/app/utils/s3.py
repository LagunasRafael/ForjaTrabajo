import boto3
import uuid
from botocore.exceptions import NoCredentialsError
from fastapi import UploadFile
import os
from dotenv import load_dotenv

load_dotenv()

# Configuramos el cliente de Amazon
s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_REGION")
)

BUCKET_NAME = os.getenv("AWS_S3_BUCKET_NAME")

async def upload_file_to_s3(file: UploadFile) -> str:
    """
    Sube un archivo a S3 y devuelve la URL pública.
    """
    try:
        # Generamos un nombre único para que no se sobrescriban fotos
        file_extension = file.filename.split(".")[-1]
        unique_filename = f"jobs/{uuid.uuid4()}.{file_extension}"

        # Subimos el archivo directamente desde la memoria
        s3_client.upload_fileobj(
            file.file,
            BUCKET_NAME,
            unique_filename,
            ExtraArgs={"ContentType": file.content_type}
        )

        # Construimos la URL pública de la foto
        file_url = f"https://{BUCKET_NAME}.s3.{os.getenv('AWS_REGION')}.amazonaws.com/{unique_filename}"
        return file_url

    except Exception as e:
        print(f"Error subiendo a S3: {e}")
        raise e