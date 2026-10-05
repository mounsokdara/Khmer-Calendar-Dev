import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String?> cacheUrl(String url, String name) async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$name');
    if (await file.exists() && await file.length() > 200) return file.path;
    final res = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0 KhmerCalendar/1.0'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    await file.writeAsBytes(res.bodyBytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}
