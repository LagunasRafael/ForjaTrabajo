import sys
import os

# Añadir el directorio raíz al path
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from app.db.database import SessionLocal
# Importar todos los modelos
from app.auth import models as auth_models
from app.services import models as service_models

def check_tokens():
    db: Session = SessionLocal()
    try:
        users = db.query(auth_models.User).all()
        print(f"Buscando tokens de {len(users)} usuarios...")
        for user in users:
            token_status = "TIENE TOKEN" if user.fcm_token else "SIN TOKEN"
            print(f"Usuario: {user.full_name} | Email: {user.email} | {token_status}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_tokens()
