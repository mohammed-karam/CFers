from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
from app.database.database import get_db
from app.models.resource import Resource
from app.schemas.resource import ResourceCreate, ResourceResponse
from app.schemas.response import ApiResponse
from app.api.v1.endpoints.users import get_current_user

router = APIRouter()

@router.post("", response_model=ApiResponse[ResourceResponse])
async def create_resource(resource_in: ResourceCreate, db: AsyncSession = Depends(get_db), current_user=Depends(get_current_user)):
    # Assuming only authenticated users can post resources
    resource = Resource(title=resource_in.title, url=resource_in.url, description=resource_in.description)
    db.add(resource)
    await db.commit()
    await db.refresh(resource)
    return ApiResponse(success=True, message="Resource created successfully", data=resource)

@router.get("", response_model=ApiResponse[List[ResourceResponse]])
async def get_resources(page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100), db: AsyncSession = Depends(get_db)):
    offset = (page - 1) * limit
    result = await db.execute(select(Resource).offset(offset).limit(limit))
    resources = result.scalars().all()
    return ApiResponse(success=True, message="Resources retrieved", data=list(resources))
