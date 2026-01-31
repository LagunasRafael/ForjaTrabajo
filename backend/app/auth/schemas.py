from pydantic import BaseModel, EmailStr,validator ,field_validator

class UserBase(BaseModel):
    email: EmailStr
    full_name: str | None = None

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str | None = None

    @validator("password")
    def password_length(cls, v: str):
        if len(v.encode("utf-8")) > 72:
            raise ValueError("Password must be 72 bytes or less")
        return v
    #d

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str | None
    role: str
    is_active: bool

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

