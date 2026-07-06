# Voice Agent — FastAPI Backend

Powers the Flutter voice agent app. Uses **Groq** for the full voice pipeline:

| Stage | Model                        |
| ----- | ---------------------------- |
| STT   | `whisper-large-v3-turbo`     |
| LLM   | `llama-3.3-70b-versatile`    |
| TTS   | `playai-tts` (voice `Fritz`) |

## Quick start

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# edit .env and set GROQ_API_KEY (get one free at https://console.groq.com/keys)

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open http://localhost:8000/docs for interactive API docs.

## Endpoints

### `POST /api/transcribe`
`multipart/form-data` — field `audio` (wav/mp3/m4a). Returns `{ text, language, duration }`.

### `POST /api/chat`
```json
{ "messages": [{ "role": "user", "content": "Hello" }] }
```
Returns `{ reply, usage }`.

### `POST /api/tts`
```json
{ "text": "Hello there", "voice": "Fritz-PlayAI" }
```
Returns raw `audio/wav` bytes.

### `POST /api/voice-turn`  ⭐ recommended for the Flutter app
One request = full turn. `multipart/form-data`:
- `audio` — the user's recorded audio
- `history` — JSON string of prior `[{role, content}]` messages

Returns:
```json
{
  "transcript": "user's spoken text",
  "reply": "assistant reply text",
  "audio_base64": "...wav bytes...",
  "audio_mime": "audio/wav"
}
```

## Project layout
```
backend/
├── app/
│   ├── main.py            # FastAPI app factory
│   ├── config.py          # Env-driven settings
│   ├── models/schemas.py  # Pydantic request/response models
│   ├── services/
│   │   └── groq_service.py  # STT + LLM + TTS wrappers
│   └── routes/
│       └── voice.py       # /api/* endpoints
├── requirements.txt
└── .env.example
```

## Next: Flutter app
The mobile app (iOS + Android) will:
1. Record mic audio (`record` package)
2. POST it to `/api/voice-turn` with conversation history
3. Play back the returned base64 WAV (`just_audio`)
4. Animate a glassmorphism voice orb reacting to mic amplitude & TTS playback

Say the word and we'll build it next.
