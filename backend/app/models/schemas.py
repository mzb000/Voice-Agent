from typing import List, Optional
from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: str = Field(..., description="'system' | 'user' | 'assistant'")
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    temperature: float = 0.7
    max_tokens: int = 1024


class ChatResponse(BaseModel):
    reply: str
    usage: Optional[dict] = None


class TranscribeResponse(BaseModel):
    text: str
    language: Optional[str] = None
    duration: Optional[float] = None


class TTSRequest(BaseModel):
    text: str
    voice: Optional[str] = None


class VoiceTurnResponse(BaseModel):
    transcript: str
    reply: str
    audio_base64: str
    audio_mime: str = "audio/wav"
