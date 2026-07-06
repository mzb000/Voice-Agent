import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/api_client.dart';
import '../services/audio_service.dart';

enum AgentState { idle, listening, thinking, speaking, error }

enum InteractionMode { pushToTalk, vad }

enum OrbStyle { blob, bars, particles }

class AgentController extends ChangeNotifier {
  AgentController({required this.api, required this.audio}) {
    _ampSub = audio.amplitude$.listen((a) {
      _amplitude = a;
      if (_state == AgentState.listening) _vadCheck(a);
      notifyListeners();
    });
    _playerSub = audio.playerState$.listen((ps) {
      if (ps.processingState.name == 'completed') {
        if (_state == AgentState.speaking) _setState(AgentState.idle);
      }
    });
  }

  final ApiClient api;
  final AudioService audio;

  AgentState _state = AgentState.idle;
  AgentState get state => _state;

  InteractionMode mode = InteractionMode.pushToTalk;
  OrbStyle orbStyle = OrbStyle.blob;

  final List<ChatMessage> history = [];
  String? _currentRecordingPath;
  String? _lastError;
  String? get lastError => _lastError;

  double _amplitude = 0.0;
  double get amplitude => _amplitude;

  // VAD tuning
  static const double _silenceThreshold = 0.08;
  static const Duration _silenceHang = Duration(milliseconds: 1200);
  Timer? _silenceTimer;

  StreamSubscription? _ampSub;
  StreamSubscription? _playerSub;

  void _setState(AgentState s) {
    _state = s;
    notifyListeners();
  }

  void setMode(InteractionMode m) {
    mode = m;
    notifyListeners();
  }

  void setOrbStyle(OrbStyle s) {
    orbStyle = s;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_state != AgentState.idle) return;
    _lastError = null;
    try {
      _currentRecordingPath = await audio.startRecording();
      _setState(AgentState.listening);
    } catch (e) {
      _lastError = e.toString();
      _setState(AgentState.error);
    }
  }

  Future<void> stopAndSend() async {
    if (_state != AgentState.listening) return;
    _silenceTimer?.cancel();
    final path = await audio.stopRecording();
    if (path == null) {
      _setState(AgentState.idle);
      return;
    }
    await _submit(path);
  }

  Future<void> cancel() async {
    _silenceTimer?.cancel();
    await audio.cancelRecording();
    await audio.stopPlayback();
    _setState(AgentState.idle);
  }

  void _vadCheck(double amp) {
    if (mode != InteractionMode.vad) return;
    if (amp > _silenceThreshold) {
      _silenceTimer?.cancel();
      _silenceTimer = null;
    } else {
      _silenceTimer ??= Timer(_silenceHang, () {
        stopAndSend();
      });
    }
  }

  Future<void> _submit(String audioPath) async {
    _setState(AgentState.thinking);
    try {
      final result = await api.voiceTurn(audioPath: audioPath, history: history);
      history.add(ChatMessage(role: 'user', content: result.transcript));
      history.add(ChatMessage(role: 'assistant', content: result.reply));
      _setState(AgentState.speaking);
      await audio.playBytes(result.audioBytes);
    } catch (e) {
      _lastError = e.toString();
      _setState(AgentState.error);
    }
  }

  void clearHistory() {
    history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _playerSub?.cancel();
    _silenceTimer?.cancel();
    audio.dispose();
    super.dispose();
  }
}
