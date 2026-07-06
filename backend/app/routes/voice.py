"""Voice agent routes: transcribe, chat, tts, and one-shot voice-turn."""
from __future__ import annotations

import base64
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.responses import Response

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


@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe(audio: UploadFile = File(...)):
    """Speech-to-text via Groq Whisper."""
    try:
        data = await audio.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty audio upload")
        result = get_service().transcribe(data, filename=audio.filename or "audio.wav")
        return TranscribeResponse(**result)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {exc}") from exc


@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """LLM chat completion via Groq."""
    try:
        messages = [m.model_dump() for m in req.messages]
        if not any(m["role"] == "system" for m in messages):
            messages.insert(0, {"role": "system", "content": SYSTEM_PROMPT})
        result = get_service().chat(
            messages=messages,
            temperature=req.temperature,
            max_tokens=req.max_tokens,
        )
        return ChatResponse(**result)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Chat failed: {exc}") from exc


@router.post("/tts")
async def tts(req: TTSRequest):
    """Text-to-speech via Groq PlayAI. Returns raw audio/wav."""
    try:
        audio_bytes = get_service().synthesize(req.text, voice=req.voice)
        return Response(content=audio_bytes, media_type="audio/wav")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"TTS failed: {exc}") from exc


@router.post("/voice-turn", response_model=VoiceTurnResponse)
async def voice_turn(
    audio: UploadFile = File(...),
    history: str = Form("[]"),
):
    """One-shot pipeline: audio in -> transcript + reply + audio out (base64).

    `history` is a JSON string of prior [{role, content}, ...] messages.
    """
    import json

    try:
        svc = get_service()

        # 1. STT
        audio_bytes = await audio.read()
        stt = svc.transcribe(audio_bytes, filename=audio.filename or "audio.wav")
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
        chat_res = svc.chat(messages=messages, temperature=0.7, max_tokens=512)
        reply_text = chat_res["reply"].strip()

        # 3. TTS
        audio_out = svc.synthesize(reply_text)
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
        raise HTTPException(status_code=500, detail=f"Voice turn failed: {exc}") from exc
