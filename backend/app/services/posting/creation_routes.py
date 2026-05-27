from fastapi import APIRouter, Depends, Form, File, UploadFile
from sqlalchemy.orm import Session
from typing import Optional, List

from app.db.database import get_db
from app.auth.security import check_role
from app.core.roles import Role
from app.services import schemas
from app.services.posting.creation_service import create_service, update_service_images
from app.utils.s3 import upload_service_evidence_to_s3

router = APIRouter()


@router.post("/", response_model=schemas.Service)
async def create_service_route(
    title: str = Form(...),
    description: str = Form(...),
    category_id: str = Form(...),
    base_price: float = Form(0.0),
    summary: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    exact_address: Optional[str] = Form(None),
    files: Optional[List[UploadFile]] = File(None),
    db: Session = Depends(get_db),
    current_user = Depends(check_role([Role.CLIENT, Role.ADMIN]))
):
    service_data = schemas.ServiceCreate(
        title=title, description=description, summary=summary,
        base_price=base_price, category_id=category_id,
        latitude=latitude, longitude=longitude, exact_address=exact_address,
        image_urls=[]
    )

    new_service = create_service(db, service_data, client_id=current_user.id)

    if files and len(files) > 0:
        image_urls = []
        for file in files:
            url = await upload_service_evidence_to_s3(file, new_service.id)
            if url:
                image_urls.append(url)
        new_service = update_service_images(db, new_service.id, image_urls)

    return new_service
