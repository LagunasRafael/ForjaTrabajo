from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from app.core.roles import Role
from typing import Optional
from datetime import datetime

# 1. Esquema Base: Solo datos que COMPARTEN todos (Registro y Respuesta)
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=15)
    latitude: Optional[float] = Field(None)
    longitude: Optional[float] = Field(None)
    city: Optional[str] = Field(None, max_length=100)
    class Config:
        from_attributes = True

# 2. Esquema para Registro: NO pedimos ID porque lo genera el servidor
class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    role: Optional[Role] = Role.CLIENT 
    phone: str = Field(..., min_length=10, max_length=20)

    @field_validator("password")
    @classmethod
    def password_length(cls, v: str):
        if len(v.encode("utf-8")) > 72:
            raise ValueError("La contraseña no puede exceder los 72 bytes")
        return v

# 3. Esquema para Respuesta: Aquí SÍ mostramos el ID y otros datos internos
class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: str 
    profile_picture_url: Optional[str] = None
    
    role: str 
    is_active: bool
    is_email_verified: bool
    is_identity_verified: bool = False
    verification_code: Optional[str] = None
    created_at: Optional[datetime] = None

# Nuevos esquemas para la verificación
class VerifyCodeRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6)

class ResendCodeRequest(BaseModel):
    email: EmailStr

# 4. Esquema para Login
class UserLogin(BaseModel):
    email: EmailStr 
    password: str

# 5. Esquema para el Token JWT
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse

class TokenRefresh(BaseModel):
    refresh_token: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    is_banned: Optional[bool] = None
    phone: Optional[str] = None

class LocationUpdate(BaseModel):
    latitude: float
    longitude: float
    city: str

class FcmTokenUpdate(BaseModel):
    fcm_token: str

# Schema para que un Admin cree usuarios desde el panel web
class AdminCreateUser(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone: Optional[str] = Field(None, max_length=20)
    password: str = Field(..., min_length=8)
    role: Role = Role.CLIENT

    @field_validator("password")
    @classmethod
    def password_length(cls, v: str):
        if len(v.encode("utf-8")) > 72:
            raise ValueError("La contraseña no puede exceder los 72 bytes")
        return v

# Schemas para Recuperación de Contraseña
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8)

    @field_validator("new_password")
    @classmethod
    def password_length(cls, v: str):
        if len(v.encode("utf-8")) > 72:
            raise ValueError("La contraseña no puede exceder los 72 bytes")
        return v

# Schemas para Verificación de Identidad
class IdentityVerificationResponse(BaseModel):
    id: str
    user_id: str
    ine_front_url: str
    ine_back_url: str
    selfie_url: str
    status: str
    rejection_reason: Optional[str] = None
    face_similarity: Optional[float] = None
    created_at: datetime
    reviewed_at: Optional[datetime] = None
    user_name: Optional[str] = None

    class Config:
        from_attributes = True

class IdentityVerificationListResponse(BaseModel):
    id: str
    user_id: str
    user_name: str
    user_email: str
    ine_front_url: str
    ine_back_url: str
    selfie_url: str
    status: str
    face_similarity: Optional[float] = None
    created_at: datetime

    class Config:
        from_attributes = True

class RejectVerificationRequest(BaseModel):
    reason: str = Field(..., min_length=5, max_length=500)