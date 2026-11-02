import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// يحمّل ملف APK داخل التطبيق ثم يفتح شاشة التثبيت مباشرة.
Future<void> downloadAndInstall(
    String url, void Function(double) onProgress) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/update.apk');
  if (await file.exists()) await file.delete();

  final client = http.Client();
  try {
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) {
      throw HttpException('فشل التحميل (${res.statusCode})');
    }
    final total = res.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in res.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress(received / total);
    }
    await sink.close();
  } finally {
    client.close();
  }

  final result = await OpenFilex.open(file.path,
      type: 'application/vnd.android.package-archive');
  if (result.type != ResultType.done) {
    throw Exception(result.message);
  }
}
