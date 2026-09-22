import pytest
from unittest.mock import patch
from app.services.codeforces_service import CodeforcesService

@pytest.mark.asyncio
@patch('app.services.codeforces_service.httpx.AsyncClient.get')
async def test_get_upcoming_contests(mock_get):
    class MockResponse:
        def raise_for_status(self): pass
        def json(self): return {"status": "OK", "result": [{"id": 1, "phase": "BEFORE", "name": "Test Contest"}]}

    mock_get.return_value = MockResponse()
    contests = await CodeforcesService.get_upcoming_contests()
    assert len(contests) == 1
    assert contests[0]["name"] == "Test Contest"

@pytest.mark.asyncio
@patch('app.services.codeforces_service.httpx.AsyncClient.get')
async def test_get_rating_changes(mock_get):
    class MockResponse:
        def raise_for_status(self): pass
        def json(self): return {"status": "OK", "result": [{"handle": "tourist", "oldRating": 3800, "newRating": 3850}]}

    mock_get.return_value = MockResponse()
    changes = await CodeforcesService.get_contest_rating_changes(123)
    assert len(changes) == 1
    assert changes[0]["handle"] == "tourist"
