from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    codeforces_handle: Optional[str] = None
    rating_notifications_enabled: bool = True
    contest_notifications_enabled: bool = True

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime

    model_config = {'from_attributes': True}

class DeviceToken(BaseModel):
    token: str
    platform: str
