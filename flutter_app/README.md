# Voice Agent — Flutter App (iOS + Android)

Modern dark + glassmorphism voice agent UI that talks to the FastAPI backend
in `../backend`. Powered by Groq (Whisper + Llama + PlayAI).

## Features

- **Push-to-Talk** *and* **Auto (voice-activity detection)** modes with a toggle
- **Three voice-orb visualizations**, switchable at runtime:
  - Morphing **Blob** with mic-reactive glow
  - Radial **Bars** (Siri-style)
  - 3D **Particle sphere**
- Full glassmorphism theme (blur, subtle strokes, gradient orb)
- Smooth entrance / message animations via `flutter_animate`
- Settings screen to configure the backend URL

## Requirements

- Flutter 3.19+
- iOS 13+ / Android SDK 23+
- A running instance of the FastAPI backend (see `../backend/README.md`)

## Setup

```bash
cd flutter_app
flutter pub get
```

Then follow the platform-specific instructions:

- **iOS** – `ios/Runner/Info.plist.additions.md`
- **Android** – `android/app/src/main/AndroidManifest.additions.md`

## Run

```bash
flutter run
```

The app defaults to `http://10.0.2.2:8000` (Android emulator → host machine).
Tap the ⚙️ icon to change the backend URL:
- **iOS simulator**: `http://127.0.0.1:8000`
- **Android emulator**: `http://10.0.2.2:8000`
- **Real device**: your computer's LAN IP, e.g. `http://192.168.1.10:8000`

## Architecture

```
lib/
├── main.dart                    # App entry, base URL from SharedPreferences
├── theme/app_theme.dart         # Dark palette, gradients
├── models/chat_message.dart
├── services/
│   ├── api_client.dart          # Dio client for the FastAPI backend
│   └── audio_service.dart       # record + just_audio (amplitude stream)
├── state/agent_controller.dart  # ChangeNotifier orchestrating STT→LLM→TTS
├── widgets/
│   ├── glass_card.dart          # Reusable glassmorphism container
│   ├── mic_button.dart          # Push-to-talk / tap-to-talk button
│   ├── voice_orb_blob.dart      # Custom-painted morphing blob
│   ├── voice_orb_bars.dart      # Custom-painted radial bars
│   └── voice_orb_particles.dart # Custom-painted particle sphere
└── screens/
    ├── home_screen.dart
    └── settings_screen.dart
```

## How a turn flows

1. User holds mic (PTT) **or** starts speaking (VAD).
2. `AudioService` streams amplitude → orb animates in real time.
3. On release / silence-detected, WAV file is POSTed to `/api/voice-turn`
   along with prior conversation history.
4. Backend: Whisper transcribes → Llama replies → PlayAI synthesizes WAV.
5. App decodes the base64 WAV, plays it via `just_audio`, transcript & reply
   appear in the chat panel; orb pulses during "speaking" state.

## Next steps

- Streaming/partial STT via WebSocket
- Interruption ("barge-in") while the agent is speaking
- Persist conversation history across sessions
- iOS/Android widgets and Siri/Assistant integration
