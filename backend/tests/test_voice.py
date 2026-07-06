"""Basic smoke tests for the Voice Agent API.

Run with: pytest (from the backend/ directory)
The Groq service is mocked so these tests never call the real API.
"""
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "healthy"}


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


@patch("app.routes.voice.get_service")
def test_chat_success(mock_get_service):
    mock_svc = MagicMock()
    mock_svc.chat.return_value = {"reply": "Hello there!", "usage": None}
    mock_get_service.return_value = mock_svc

    resp = client.post("/api/chat", json={"messages": [{"role": "user", "content": "hi"}]})
    assert resp.status_code == 200
    assert resp.json()["reply"] == "Hello there!"


def test_chat_rejects_bad_api_key(monkeypatch):
    from app.config import settings

    monkeypatch.setattr(settings, "app_api_key", "secret123")
    resp = client.post(
        "/api/chat",
        json={"messages": [{"role": "user", "content": "hi"}]},
        headers={"X-API-Key": "wrong"},
    )
    assert resp.status_code == 401
    monkeypatch.setattr(settings, "app_api_key", "")


@patch("app.routes.voice.get_service")
def test_transcribe_rejects_empty_audio(mock_get_service):
    resp = client.post(
        "/api/transcribe",
        files={"audio": ("empty.wav", b"", "audio/wav")},
    )
    assert resp.status_code == 400
