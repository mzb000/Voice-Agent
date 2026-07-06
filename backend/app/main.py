from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .routes.voice import router as voice_router


def create_app() -> FastAPI:
    app = FastAPI(
        title="Voice Agent API",
        version="0.1.0",
        description="FastAPI backend powering a Flutter voice agent, using Groq (Whisper + Llama + PlayAI).",
    )

    origins = [o.strip() for o in settings.cors_origins.split(",")] if settings.cors_origins else ["*"]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(voice_router)

    @app.get("/")
    async def root():
        return {
            "name": "Voice Agent API",
            "status": "ok",
            "endpoints": [
                "POST /api/transcribe   (multipart: audio)",
                "POST /api/chat         (json: messages[])",
                "POST /api/tts          (json: text)",
                "POST /api/voice-turn   (multipart: audio + history JSON)",
            ],
        }

    @app.get("/health")
    async def health():
        return {"status": "healthy"}

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host=settings.host, port=settings.port, reload=True)
