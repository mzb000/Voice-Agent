import 'dart:convert';
import 'package:dio/dio.dart';

import '../models/chat_message.dart';
import 'platform_audio_io.dart'
    if (dart.library.html) 'platform_audio_web.dart';

class VoiceTurnResult {
  final String transcript;
  final String reply;
  final List<int> audioBytes;
  final String audioMime;

  VoiceTurnResult({
    required this.transcript,
    required this.reply,
    required this.audioBytes,
    required this.audioMime,
  });
}

class ApiClient {
  ApiClient({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 90),
        ));

  final String baseUrl;
  final Dio _dio;

  Future<VoiceTurnResult> voiceTurn({
    required String audioPath,
    required List<ChatMessage> history,
  }) async {
    final bytes = await readRecordingBytes(audioPath);
    final form = FormData.fromMap({
      'audio': MultipartFile.fromBytes(bytes, filename: 'audio.wav'),
      'history': jsonEncode(history.map((m) => m.toJson()).toList()),
    });

    final res = await _dio.post('/api/voice-turn', data: form);
    final data = res.data as Map<String, dynamic>;
    return VoiceTurnResult(
      transcript: data['transcript'] as String? ?? '',
      reply: data['reply'] as String? ?? '',
      audioBytes: base64Decode(data['audio_base64'] as String? ?? ''),
      audioMime: data['audio_mime'] as String? ?? 'audio/wav',
    );
  }

  Future<String> transcribe(String audioPath) async {
    final bytes = await readRecordingBytes(audioPath);
    final form = FormData.fromMap({
      'audio': MultipartFile.fromBytes(bytes, filename: 'audio.wav'),
    });
    final res = await _dio.post('/api/transcribe', data: form);
    return (res.data['text'] as String?) ?? '';
  }

  Future<String> chat(List<ChatMessage> messages) async {
    final res = await _dio.post('/api/chat', data: {
      'messages': messages.map((m) => m.toJson()).toList(),
    });
    return (res.data['reply'] as String?) ?? '';
  }

  Future<List<int>> tts(String text) async {
    final res = await _dio.post(
      '/api/tts',
      data: {'text': text},
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data as List<int>;
  }
}
