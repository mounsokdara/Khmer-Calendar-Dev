import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

const _prefix = 'wheel_custom_';

Future<List<File>> _files() async {
  final dir = await getApplicationSupportDirectory();
  if (!await dir.exists()) return [];
  final out = <File>[];
  await for (final e in dir.list()) {
    if (e is File && e.uri.pathSegments.last.startsWith(_prefix)) out.add(e);
  }
  out.sort((a, b) => a.path.compareTo(b.path));
  return out;
}



Future<void> saveCustomSound(Uint8List bytes, String ext) async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final stamp = DateTime.now().millisecondsSinceEpoch.toString().padLeft(15, '0');
  await File('${dir.path}/$_prefix$stamp.$ext').writeAsBytes(bytes, flush: true);
  await clearCustomSound(keepNewest: true);
}

Future<void> clearCustomSound({bool keepNewest = false}) async {
  try {
    final files = await _files();
    final drop = keepNewest && files.isNotEmpty ? files.sublist(0, files.length - 1) : files;
    for (final f in drop) {
      try {
        await f.delete();
      } catch (_) {

      }
    }
  } catch (_) {}
}

Future<Source?> customSoundSource() async {
  final files = await _files();
  return files.isEmpty ? null : DeviceFileSource(files.last.path);
}
