from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.database.database import get_db
from app.models.user import User
from app.schemas.auth import Login, Token
from app.schemas.user import UserCreate, UserResponse
from app.schemas.response import ApiResponse
from app.core.security import verify_password, get_password_hash, create_access_token

router = APIRouter()

@router.post("/register", response_model=ApiResponse[UserResponse])
async def register(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pw = get_password_hash(user_in.password)
    user = User(
        email=user_in.email,
        hashed_password=hashed_pw,
        codeforces_handle=user_in.codeforces_handle,
        rating_notifications_enabled=user_in.rating_notifications_enabled,
        contest_notifications_enabled=user_in.contest_notifications_enabled
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return ApiResponse(success=True, message="User registered successfully", data=user)

@router.post("/login", response_model=ApiResponse[Token])
async def login(login_data: Login, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == login_data.email))
    user = result.scalars().first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    token = create_access_token({"sub": str(user.id)})
    return ApiResponse(success=True, message="Login successful", data=Token(access_token=token, token_type="bearer"))
