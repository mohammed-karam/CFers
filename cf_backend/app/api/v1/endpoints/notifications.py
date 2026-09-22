from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.database import get_db
from app.schemas.notification import ContestNotificationRequest
from app.schemas.response import ApiResponse
from app.services.notification_service import NotificationService

router = APIRouter()

@router.post("/rating-changes", response_model=ApiResponse)
async def notify_rating_changes(request: ContestNotificationRequest, db: AsyncSession = Depends(get_db)):
    success, msg = await NotificationService.process_rating_changes(db, request.contest_id)
    return ApiResponse(success=success, message=msg)

@router.post("/upcoming-contests", response_model=ApiResponse)
async def notify_upcoming_contests(db: AsyncSession = Depends(get_db)):
    success, msg = await NotificationService.process_upcoming_contests(db)
    return ApiResponse(success=success, message=msg)
