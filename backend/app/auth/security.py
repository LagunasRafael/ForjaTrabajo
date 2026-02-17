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
    user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if user is None or not user.is_active:
        raise credentials_exception

    return user

# --- VERIFICADOR DE ROLES ---
def check_role(allowed_roles: list[Role]):
    def role_checker(current_user: models.User = Depends(get_current_user)):
        # Convertimos a string por si el rol viene como Enum o Texto
        user_role = current_user.role if isinstance(current_user.role, str) else current_user.role.value
        
        # Verificamos si el rol del usuario está en la lista permitida
        # Asumiendo que allowed_roles es una lista de strings o Enums
        allowed_values = [r.value if hasattr(r, 'value') else r for r in allowed_roles]

        if user_role not in allowed_values:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos suficientes para esta acción"
            )
        return current_user
    return role_checker