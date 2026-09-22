from fastapi import APIRouter, Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import jwt, JWTError
from app.database.database import get_db
from app.models.user import User
from app.schemas.user import DeviceToken
from app.schemas.response import ApiResponse
from app.core.config import settings
from app.core.exceptions import CredentialsException

router = APIRouter()
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security), db: AsyncSession = Depends(get_db)):
    try:
        payload = jwt.decode(credentials.credentials, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise CredentialsException()
    except JWTError:
        raise CredentialsException()
    
    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalars().first()
    if user is None:
        raise CredentialsException()
    return user

@router.post("/device-token", response_model=ApiResponse)
async def update_device_token(token_data: DeviceToken, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    current_user.fcm_token = token_data.token
    await db.commit()
    return ApiResponse(success=True, message="Device token updated")
