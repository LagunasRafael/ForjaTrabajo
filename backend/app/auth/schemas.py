from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from app.core.roles import Role
from typing import Optional

# 1. Esquema Base: Solo datos que COMPARTEN todos (Registro y Respuesta)
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = Field(None, max_length=100)

# 2. Esquema para Registro: NO pedimos ID porque lo genera el servidor
class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    role: Optional[Role] = Role.CLIENT 

    @field_validator("password")
    @classmethod
    def password_length(cls, v: str):
        if len(v.encode("utf-8")) > 72:
            raise ValueError("La contraseña no puede exceder los 72 bytes")
        return v

# 3. Esquema para Respuesta: Aquí SÍ mostramos el ID y otros datos internos
class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    # --- CORRECCIÓN CRÍTICA ---
    # Cambiamos int a str para soportar el UUID de 36 caracteres
    id: str 
    
    # Usamos str para el rol para evitar errores de validación con el Enum de la BD
    role: str 
    is_active: bool

# 4. Esquema para Login
class UserLogin(BaseModel):
    email: EmailStr 
    password: str

# 5. Esquema para el Token JWT
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse