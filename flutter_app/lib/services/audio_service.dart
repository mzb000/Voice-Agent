import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

// Platform-specific helpers: native file APIs on mobile/desktop, blob/data-URI
// on web. The default import is the IO version; web overrides it.
import 'platform_audio_io.dart'
    if (dart.library.html) 'platform_audio_web.dart';

/// Handles mic recording (with amplitude stream) and TTS playback.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Amplitude>? _ampSub;
  final _ampController = StreamController<double>.broadcast();

  /// Normalized [0..1] mic amplitude stream.
  Stream<double> get amplitude$ => _ampController.stream;

  /// Player state stream (for animating during TTS playback).
  Stream<PlayerState> get playerState$ => _player.playerStateStream;

  Future<bool> ensurePermission() async {
    // On web, the `record` package triggers the browser's getUserMedia prompt
    // itself when recording starts, so skip permission_handler there.
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> startRecording() async {
    if (!await ensurePermission()) {
      throw Exception('Microphone permission denied');
    }
    final path = await makeRecordingPath(
      'rec_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      // amp.current is in dBFS, roughly [-60..0]. Normalize.
      final db = amp.current.clamp(-60.0, 0.0);
      final norm = ((db + 60.0) / 60.0).clamp(0.0, 1.0);
      _ampController.add(norm);
    });

    return path;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    await _ampSub?.cancel();
    _ampSub = null;
    _ampController.add(0);
    return path;
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    await _ampSub?.cancel();
    _ampSub = null;
    _ampController.add(0);
  }

  /// Read the recorded audio bytes from a recording path/URL.
  Future<List<int>> readRecording(String pathOrUrl) =>
      readRecordingBytes(pathOrUrl);

  Future<void> playBytes(List<int> bytes, {String ext = 'wav'}) async {
    await playAudioBytes(_player, bytes, ext: ext);
  }

  Future<void> stopPlayback() => _player.stop();

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _ampController.close();
    await _recorder.dispose();
    await _player.dispose();
  }
}
