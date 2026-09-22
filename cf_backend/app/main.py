import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from app.api.v1.api import api_router
from app.scheduler.jobs import start_scheduler
from app.database.database import engine, Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # For local dev without Alembic, we can auto-create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Starting background scheduler...")
    start_scheduler()
    yield
    logger.info("Shutting down...")

app = FastAPI(
    title="Codeforces Companion App Backend",
    description="Backend API for Codeforces Companion App. Features include contest notifications and resources distribution.",
    version="1.0.0",
    lifespan=lifespan
)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}")
    return JSONResponse(
        status_code=500,
        content={"success": False, "message": "Internal Server Error", "data": None},
    )

app.include_router(api_router, prefix="/api/v1")
