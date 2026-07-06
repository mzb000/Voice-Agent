"""Groq service layer: STT (Whisper), LLM (Llama), TTS (PlayAI).

Blocking Groq SDK calls are retried with backoff on transient errors. Route
handlers are responsible for running these methods off the asyncio event
loop (see routes/voice.py, which wraps calls with run_in_threadpool).
"""
from __future__ import annotations

import io
from typing import List, Dict, Optional

import groq
from groq import Groq
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential

from ..config import settings

RETRYABLE_ERRORS = (
    groq.APIConnectionError,
    groq.APITimeoutError,
    groq.InternalServerError,
    groq.RateLimitError,
)

_retry = retry(
    reraise=True,
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=0.5, min=0.5, max=4),
    retry=retry_if_exception_type(RETRYABLE_ERRORS),
)


class GroqService:
    def __init__(self) -> None:
        if not settings.groq_api_key:
            raise RuntimeError("GROQ_API_KEY is not set. Copy .env.example to .env and fill it.")
        self.client = Groq(api_key=settings.groq_api_key)

    # ---------- Speech-to-Text ----------
    @_retry
    def transcribe(self, audio_bytes: bytes, filename: str = "audio.wav") -> Dict:
        """Return {'text', 'language', 'duration'}."""
        buf = io.BytesIO(audio_bytes)
        buf.name = filename
        result = self.client.audio.transcriptions.create(
            file=(filename, buf.read()),
            model=settings.stt_model,
            response_format="verbose_json",
        )
        # Groq SDK returns an object; normalize to dict
        return {
            "text": getattr(result, "text", "") or "",
            "language": getattr(result, "language", None),
            "duration": getattr(result, "duration", None),
        }

    # ---------- LLM Chat ----------
    @_retry
    def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> Dict:
        completion = self.client.chat.completions.create(
            model=settings.llm_model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        reply = completion.choices[0].message.content or ""
        usage = None
        if getattr(completion, "usage", None):
            usage = {
                "prompt_tokens": completion.usage.prompt_tokens,
                "completion_tokens": completion.usage.completion_tokens,
                "total_tokens": completion.usage.total_tokens,
            }
        return {"reply": reply, "usage": usage}

    # ---------- Text-to-Speech ----------
    @_retry
    def synthesize(self, text: str, voice: Optional[str] = None) -> bytes:
        """Return raw WAV audio bytes."""
        response = self.client.audio.speech.create(
            model=settings.tts_model,
            voice=voice or settings.tts_voice,
            input=text,
            response_format="wav",
        )
        # groq SDK: response has .read() / .content depending on version
        if hasattr(response, "read"):
            return response.read()
        if hasattr(response, "content"):
            return response.content
        # fallback: iterate bytes
        return b"".join(response.iter_bytes()) if hasattr(response, "iter_bytes") else bytes(response)


groq_service = GroqService() if settings.groq_api_key else None


def get_service() -> GroqService:
    global groq_service
    if groq_service is None:
        groq_service = GroqService()
    return groq_service
