from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from app.core.roles import Role
from typing import Optional

# 1. Esquema Base para datos comunes
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = Field(None, max_length=100)

# 2. Esquema para Registro (Input)
class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    role: Role = Role.CLIENT # Por defecto es usuario normal

    @field_validator("password")
    @classmethod
    def password_length(cls, v: str):
        # Validación de los 72 bytes para compatibilidad con bcrypt
        if len(v.encode("utf-8")) > 72:
            raise ValueError("La contraseña no puede exceder los 72 bytes")
        return v

# 3. Esquema para Respuesta (Output)
class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True) # Reemplaza a class Config en V2

    id: int
    role: Role
    is_active: bool

# 4. Esquema para Login
class UserLogin(BaseModel):
    email: EmailStr # Mejor usar EmailStr aquí también para validar formato
    password: str

# 5. Esquema para el Token JWT
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"