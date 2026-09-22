from pydantic import BaseModel

class ContestNotificationRequest(BaseModel):
    contest_id: int
