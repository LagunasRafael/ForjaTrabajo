from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.auth import models
from app.core.roles import Role # Importante para validaciones

# ⚠️ En producción, esto debe venir de una variable de entorno (.env)
SECRET_KEY = "TU_LLAVE_SUPER_SECRETA_DE_SISTEMAS" 
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# --- PASSWORDS ---
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# --- JWT ---
def create_access_token(data: dict):
    to_encode = data.copy()
    # datetime.utcnow() está deprecado en Python 3.12+, usamos timezone.utc
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# --- USUARIO ACTUAL ---
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar la sesión",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # Asegúrate de que en routes.py guardes el ID como string en el "sub"
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # Buscamos por ID directamente
    user = db.query(models.User).filter(models.User.id == int(user_id)).first()
    
    if user is None or not user.is_active:
        raise credentials_exception

    return user

# --- FASE 2: VERIFICADOR DE ROLES ---
def check_role(allowed_roles: list[Role]):
    """
    Dependencia para proteger rutas por rol.
    Uso: Depends(check_role([Role.admin, Role.worker]))
    """
    def role_checker(current_user: models.User = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos suficientes para esta acción"
            )
        return current_user
    return role_checker