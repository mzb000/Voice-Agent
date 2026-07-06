import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Native (mobile/desktop) implementation of platform audio helpers.

/// Create a real temp file path for the recorder to write to.
Future<String> makeRecordingPath(String name) async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/$name';
}

/// Read the recorded audio bytes from a file path.
Future<List<int>> readRecordingBytes(String pathOrUrl) async {
  return File(pathOrUrl).readAsBytes();
}

/// Play raw audio bytes by writing a temp file and pointing the player at it.
Future<void> playAudioBytes(
  AudioPlayer player,
  List<int> bytes, {
  String ext = 'wav',
}) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.$ext');
  await f.writeAsBytes(bytes, flush: true);
  await player.setFilePath(f.path);
  await player.play();
}
