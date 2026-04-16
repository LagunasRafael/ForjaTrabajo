from pydantic import BaseModel
from typing import Optional

class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    
class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: str  # Manejado como String para el UUID
    is_active: bool

    class Config:
        orm_mode = True

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None