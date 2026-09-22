from sqlalchemy import Column, Integer, String, Boolean, DateTime, func
from app.database.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    codeforces_handle = Column(String, index=True, nullable=True)
    is_active = Column(Boolean, default=True)
    rating_notifications_enabled = Column(Boolean, default=True)
    contest_notifications_enabled = Column(Boolean, default=True)
    fcm_token = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
