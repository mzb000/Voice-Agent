from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")
    groq_api_key: str = ""
    stt_model: str = "whisper-large-v3-turbo"
    llm_model: str = "llama-3.3-70b-versatile"
    tts_model: str = "canopylabs/orpheus-v1-english"
    tts_voice: str = "tara"

    host: str = "0.0.0.0"
    port: int = 8000
    cors_origins: str = "http://localhost:8000,http://127.0.0.1:8000"

    # Client auth + rate limiting
    app_api_key: str = ""
    rate_limit: str = "20/minute"

settings = Settings()
