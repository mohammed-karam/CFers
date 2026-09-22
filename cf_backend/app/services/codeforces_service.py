import httpx
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class CodeforcesService:
    @staticmethod
    async def get_contest_rating_changes(contest_id: int):
        url = f"{settings.CODEFORCES_BASE_URL}/contest.ratingChanges?contestId={contest_id}"
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                if data.get("status") == "OK":
                    return data.get("result", [])
                logger.error(f"CF API error: {data.get('comment')}")
                return None
            except Exception as e:
                logger.error(f"Error fetching rating changes: {e}")
                return None

    @staticmethod
    async def get_upcoming_contests():
        url = f"{settings.CODEFORCES_BASE_URL}/contest.list?gym=false"
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                if data.get("status") == "OK":
                    return [c for c in data.get("result", []) if c.get("phase") == "BEFORE"]
                logger.error(f"CF API error: {data.get('comment')}")
                return []
            except Exception as e:
                logger.error(f"Error fetching upcoming contests: {e}")
                return []
