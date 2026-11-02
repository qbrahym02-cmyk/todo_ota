import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';

/// إعدادات تُقرأ من الإنترنت عند كل تشغيل.
/// أي تعديل على remote/config.json في GitHub يظهر عند المستخدم فوراً
/// (بدون بناء أو تحميل نسخة جديدة).
class RemoteConfig extends ChangeNotifier {
  static const _cacheKey = 'remote_config_cache';

  String appTitle = 'مهامي';
  Color primaryColor = const Color(0xFF6750A4);
  bool announcementEnabled = false;
  String announcementText = '';
  Color announcementColor = const Color(0xFFFFF3CD);
  bool featurePriorities = true;
  bool featureSearch = true;
  bool featureStats = true;
  bool featureDueDates = true;
  int minBuild = 0;
  bool loadedFromNetwork = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) _apply(cached);

    try {
      final uri = Uri.parse(
          '${AppConfig.remoteConfigUrl}?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        _apply(body);
        loadedFromNetwork = true;
        await prefs.setString(_cacheKey, body);
      }
    } catch (_) {/* بدون إنترنت – نستخدم النسخة المخزنة */}
    notifyListeners();
  }

  void _apply(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      appTitle = j['app_title'] as String? ?? appTitle;
      primaryColor = _color(j['primary_color']) ?? primaryColor;
      final a = j['announcement'] as Map<String, dynamic>? ?? {};
      announcementEnabled = a['enabled'] as bool? ?? false;
      announcementText = a['text'] as String? ?? '';
      announcementColor = _color(a['color']) ?? announcementColor;
      final f = j['features'] as Map<String, dynamic>? ?? {};
      featurePriorities = f['priorities'] as bool? ?? featurePriorities;
      featureSearch = f['search'] as bool? ?? featureSearch;
      featureStats = f['stats'] as bool? ?? featureStats;
      featureDueDates = f['due_dates'] as bool? ?? featureDueDates;
      minBuild = (j['min_build'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  static Color? _color(dynamic v) {
    if (v is! String) return null;
    var hex = v.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final n = int.tryParse(hex, radix: 16);
    return n == null ? null : Color(n);
  }
}
