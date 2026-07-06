<div align="center">

# 🎙️ Voice Agent

### A production-ready mobile & web voice assistant — Flutter + FastAPI + Groq

Talk to an AI assistant in real time. Speech goes in, an LLM thinks, and a natural voice answers back — wrapped in a modern dark **glassmorphism** UI with reactive voice-orb animations.

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)
![Groq](https://img.shields.io/badge/Groq-Whisper·Llama·Orpheus-F55036)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

---

## ✨ Features

- 🗣️ **Full voice pipeline** — Speech-to-Text → LLM → Text-to-Speech in one round trip
- ⚡ **Powered by Groq** — Whisper (STT), Llama 3.3 70B (LLM), Orpheus (TTS), all blazing fast
- 🎨 **Glassmorphism dark UI** — frosted-glass cards, smooth entrance animations
- 🌀 **3 reactive voice orbs** — `blob`, `bars`, and `particles` visualizations driven by live mic amplitude (pure `CustomPainter`, no images)
- 🎚️ **Two interaction modes** — push-to-talk **and** voice-activity detection (auto-send on silence)
- 💬 **Chat transcript** — conversation bubbles with animations
- ⚙️ **Configurable backend URL** — set it in the in-app Settings screen (persisted)
- 📱 **Runs everywhere** — Android, iOS, and Web (browser) from one codebase

---

## 🏗️ Architecture

```
┌───────────────────────────┐         HTTP          ┌──────────────────────────┐
│      Flutter App          │  ───────────────────► │     FastAPI Backend      │
│  (Android · iOS · Web)    │                        │                          │
│                           │  ◄─────────────────── │   ┌──────────────────┐   │
│  • Mic capture            │      transcript +      │   │   Groq Cloud     │   │
│  • Voice-orb animations   │      reply + audio     │   │  Whisper (STT)   │   │
│  • Audio playback         │                        │   │  Llama  (LLM)    │   │
└───────────────────────────┘                        │   │  Orpheus (TTS)   │   │
                                                      │   └──────────────────┘   │
                                                      └──────────────────────────┘
```

---

## 📂 Repository layout

```
voice-agent/
├── backend/                 # FastAPI service
│   ├── app/
│   │   ├── main.py          # app factory, CORS, health
│   │   ├── config.py        # settings via .env
│   │   ├── routes/voice.py  # /api endpoints
│   │   ├── services/        # Groq service layer (STT · LLM · TTS)
│   │   └── models/          # Pydantic schemas
│   ├── requirements.txt
│   └── .env.example
│
└── flutter_app/             # Flutter mobile + web app
    ├── lib/
    │   ├── main.dart
    │   ├── screens/         # home, settings
    │   ├── services/        # api_client, audio_service (+ web/io platform shims)
    │   ├── state/           # AgentController (ChangeNotifier)
    │   ├── widgets/         # voice orbs, mic button, glass card
    │   └── theme/
    ├── android/  ios/  web/ # platform projects
    └── pubspec.yaml
```

---

## 🚀 Quick start

### Prerequisites
- **Python 3.10+** and **Flutter 3.19+**
- A free **Groq API key** → [console.groq.com](https://console.groq.com)

### 1. Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate         # Windows: .venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env              # then edit .env and paste your GROQ_API_KEY
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend is now at **http://127.0.0.1:8000** — open **/docs** for the interactive API.

### 2. Flutter app

```bash
cd flutter_app
flutter pub get
```

**Run on web (fastest to try on a PC):**
```bash
flutter run -d chrome
```

**Run on Android** (emulator or USB device):
```bash
flutter run
```

Then open the in-app **⚙️ Settings** and set the backend URL:
| Target | Backend URL |
|---|---|
| Web / desktop | `http://127.0.0.1:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Real device (same Wi-Fi) | `http://<your-computer-LAN-IP>:8000` |

---

## 🔌 API endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/transcribe` | Audio (multipart) → text (Whisper STT) |
| `POST` | `/api/chat` | `messages[]` → assistant reply (Llama LLM) |
| `POST` | `/api/tts` | `text` → WAV audio (Orpheus TTS) |
| `POST` | `/api/voice-turn` | **Full pipeline:** audio in → transcript + reply + audio out (base64) |
| `GET`  | `/health` | Health check |

---

## 🧩 Tech stack

**Backend:** FastAPI · Uvicorn · Pydantic · Groq SDK
**App:** Flutter · Provider · Dio · `record` · `just_audio` · `google_fonts` · `flutter_animate` · `glass_kit`
**AI (Groq):** `whisper-large-v3-turbo` · `llama-3.3-70b-versatile` · `canopylabs/orpheus-v1-english`

---

## 📝 Notes

- **TTS model terms:** Groq's Orpheus TTS model requires a one-time terms acceptance in your [Groq console](https://console.groq.com) before `/api/tts` works. STT and chat work out of the box.
- **Web audio:** on web, recording uses the browser's `getUserMedia` (blob-based) instead of file paths — handled transparently by the platform shims in `lib/services/`.
- **Never commit `.env`** — it holds your API key. Use `.env.example` as the template.

---

## 🗺️ Roadmap

- [ ] Streaming STT over WebSocket
- [ ] Barge-in (interrupt the assistant while it speaks)
- [ ] Persist conversation history
- [ ] Home-screen widgets (iOS / Android)

---

<div align="center">

**MIT Licensed** · Built with Flutter, FastAPI & Groq

</div>
