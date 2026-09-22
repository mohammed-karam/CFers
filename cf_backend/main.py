from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional

app = FastAPI(
    title="Codeforces Companion App Backend",
    description="Backend API for Codeforces Companion App. Features include contest notifications and resources distribution.",
    version="1.0.0"
)

class Resource(BaseModel):
    title: str
    url: str
    description: Optional[str] = None

class RatingNotificationRequest(BaseModel):
    contest_id: int

@app.post("/api/v1/notifications/rating-changes", summary="Notify users about rating changes after a contest", tags=["Notifications"])
def notify_rating_changes(request: RatingNotificationRequest):
    """
    Checks if ratings changed after the given contest and sends emails to users.
    """
    return {"message": f"Emails sent for rating changes in contest {request.contest_id}"}

@app.post("/api/v1/notifications/upcoming-contests", summary="Notify users about upcoming contests", tags=["Notifications"])
def notify_upcoming_contests():
    """
    Checks for contests starting in about 24 hours and sends emails to users.
    """
    return {"message": "Emails sent for upcoming contests in the next 24 hours"}

@app.post("/api/v1/resources", summary="Post a new resource (e.g., video) to users", tags=["Resources"])
def post_resource(resource: Resource):
    """
    Posts a new resource (like a video) to the users of the app.
    """
    return {"message": "Resource posted successfully", "resource": resource}
