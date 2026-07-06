"""Voice agent routes: transcribe, chat, tts, and one-shot voice-turn."""
from __future__ import annotations

import base64
import json

import groq
from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, Request, UploadFile
from fastapi.responses import Response
from starlette.concurrency import run_in_threadpool

from ..config import settings
from ..main import limiter
from ..models.schemas import (
    ChatRequest,
    ChatResponse,
    TranscribeResponse,
    TTSRequest,
    VoiceTurnResponse,
)
from ..services.groq_service import get_service

router = APIRouter(prefix="/api", tags=["voice"])

SYSTEM_PROMPT = (
    "You are a helpful, concise voice assistant. "
    "Keep replies short, natural, and easy to speak aloud. "
    "Avoid markdown, code blocks, or long lists unless asked."
)

# Reject audio uploads larger than this to avoid tying up worker resources.
MAX_AUDIO_BYTES = 10 * 1024 * 1024  # 10 MB


async def require_api_key(x_api_key: str = Header(default="")):
    """Require a matching X-API-Key header when APP_API_KEY is configured."""
    if settings.app_api_key and x_api_key != settings.app_api_key:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


def _handle_groq_error(exc: Exception, action: str) -> HTTPException:
    """Map Groq SDK exceptions to sensible HTTP status codes."""
    if isinstance(exc, groq.RateLimitError):
        return HTTPException(status_code=429, detail=f"{action} rate limited upstream: {exc}")
    if isinstance(exc, (groq.APITimeoutError, groq.APIConnectionError)):
        return HTTPException(status_code=504, detail=f"{action} timed out upstream: {exc}")
    if isinstance(exc, groq.APIStatusError):
        return HTTPException(status_code=502, detail=f"{action} failed upstream: {exc}")
    return HTTPException(status_code=500, detail=f"{action} failed: {exc}")


@router.post("/transcribe", response_model=TranscribeResponse, dependencies=[Depends(require_api_key)])
@limiter.limit(settings.rate_limit)
async def transcribe(request: Request, audio: UploadFile = File(...)):
    """Speech-to-text via Groq Whisper."""
    try:
        data = await audio.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty audio upload")
        if len(data) > MAX_AUDIO_BYTES:
            raise HTTPException(status_code=413, detail="Audio upload too large")
        result = await run_in_threadpool(
            get_service().transcribe, data, filename=audio.filename or "audio.wav"
        )
        return TranscribeResponse(**result)
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_groq_error(exc, "Transcription") from exc


@router.post("/chat", response_model=ChatResponse, dependencies=[Depends(require_api_key)])
@limiter.limit(settings.rate_limit)
async def chat(request: Request, req: ChatRequest):
    """LLM chat completion via Groq."""
    try:
        messages = [m.model_dump() for m in req.messages]
        if not any(m["role"] == "system" for m in messages):
            messages.insert(0, {"role": "system", "content": SYSTEM_PROMPT})
        result = await run_in_threadpool(
            get_service().chat,
            messages=messages,
            temperature=req.temperature,
            max_tokens=req.max_tokens,
        )
        return ChatResponse(**result)
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_groq_error(exc, "Chat") from exc


@router.post("/tts", dependencies=[Depends(require_api_key)])
@limiter.limit(settings.rate_limit)
async def tts(request: Request, req: TTSRequest):
    """Text-to-speech via Groq PlayAI. Returns raw audio/wav."""
    try:
        audio_bytes = await run_in_threadpool(get_service().synthesize, req.text, voice=req.voice)
        return Response(content=audio_bytes, media_type="audio/wav")
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_groq_error(exc, "TTS") from exc


@router.post("/voice-turn", response_model=VoiceTurnResponse, dependencies=[Depends(require_api_key)])
@limiter.limit(settings.rate_limit)
async def voice_turn(
    request: Request,
    audio: UploadFile = File(...),
    history: str = Form("[]"),
):
    """One-shot pipeline: audio in -> transcript + reply + audio out (base64).

    `history` is a JSON string of prior [{role, content}, ...] messages.
    """
    try:
        svc = get_service()

        # 1. STT
        audio_bytes = await audio.read()
        if not audio_bytes:
            raise HTTPException(status_code=400, detail="Empty audio upload")
        if len(audio_bytes) > MAX_AUDIO_BYTES:
            raise HTTPException(status_code=413, detail="Audio upload too large")

        stt = await run_in_threadpool(svc.transcribe, audio_bytes, filename=audio.filename or "audio.wav")
        user_text = stt["text"].strip()
        if not user_text:
            raise HTTPException(status_code=400, detail="No speech detected")

        # 2. LLM
        try:
            prior = json.loads(history) if history else []
            if not isinstance(prior, list):
                prior = []
        except json.JSONDecodeError:
            prior = []

        messages = [{"role": "system", "content": SYSTEM_PROMPT}, *prior, {"role": "user", "content": user_text}]
        chat_res = await run_in_threadpool(svc.chat, messages=messages, temperature=0.7, max_tokens=512)
        reply_text = chat_res["reply"].strip()

        # 3. TTS
        audio_out = await run_in_threadpool(svc.synthesize, reply_text)
        audio_b64 = base64.b64encode(audio_out).decode("ascii")

        return VoiceTurnResponse(
            transcript=user_text,
            reply=reply_text,
            audio_base64=audio_b64,
            audio_mime="audio/wav",
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise _handle_groq_error(exc, "Voice turn") from exc
