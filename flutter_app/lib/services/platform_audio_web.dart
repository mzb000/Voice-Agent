import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

/// Web (browser) implementation of platform audio helpers.
///
/// On web the `record` package writes to an in-memory blob and `stop()`
/// returns a `blob:` URL rather than a filesystem path, so file APIs are
/// replaced with blob fetches and data-URI playback.

/// The recorder ignores the path argument on web; return a dummy name.
Future<String> makeRecordingPath(String name) async => name;

/// Fetch the recorded audio bytes from the blob: URL returned by stop().
Future<List<int>> readRecordingBytes(String pathOrUrl) async {
  final res = await http.get(Uri.parse(pathOrUrl));
  return res.bodyBytes;
}

/// Play raw audio bytes in the browser via a base64 data URI.
Future<void> playAudioBytes(
  AudioPlayer player,
  List<int> bytes, {
  String ext = 'wav',
}) async {
  final b64 = base64Encode(bytes);
  await player.setUrl('data:audio/$ext;base64,$b64');
  await player.play();
}
