import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';


const _dataKey = 'khmer-calendar-wheel-custom';
const _extKey = 'khmer-calendar-wheel-custom-ext';

const _mime = {
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'oga': 'audio/ogg',
  'opus': 'audio/ogg',
  'flac': 'audio/flac',
  'aac': 'audio/aac',
  'm4a': 'audio/mp4',
};

Future<void> saveCustomSound(Uint8List bytes, String ext) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_dataKey, base64Encode(bytes));
  await prefs.setString(_extKey, ext);
}

Future<void> clearCustomSound({bool keepNewest = false}) async {
  if (keepNewest) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey);
    await prefs.remove(_extKey);
  } catch (_) {}
}

Future<Source?> customSoundSource() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_dataKey);
  if (raw == null || raw.isEmpty) return null;
  final ext = prefs.getString(_extKey) ?? 'mp3';
  return BytesSource(base64Decode(raw), mimeType: _mime[ext] ?? 'audio/mpeg');
}
