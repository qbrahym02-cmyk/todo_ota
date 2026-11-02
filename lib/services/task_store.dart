import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// تخزين المهام محلياً على الجهاز.
class TaskStore extends ChangeNotifier {
  static const _key = 'tasks_v1';
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get doneCount => _tasks.where((t) => t.done).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(list.map((e) => Task.fromJson(e as Map<String, dynamic>)));
      } catch (_) {/* بيانات تالفة – نتجاهلها */}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void add(Task t) {
    _tasks.insert(0, t);
    _changed();
  }

  void insertAt(int index, Task t) {
    _tasks.insert(index.clamp(0, _tasks.length), t);
    _changed();
  }

  void update(Task t) {
    final i = _tasks.indexWhere((e) => e.id == t.id);
    if (i != -1) {
      _tasks[i] = t;
      _changed();
    }
  }

  void toggle(String id) {
    final t = _tasks.firstWhere((e) => e.id == id);
    t.done = !t.done;
    _changed();
  }

  int remove(String id) {
    final i = _tasks.indexWhere((e) => e.id == id);
    if (i != -1) {
      _tasks.removeAt(i);
      _changed();
    }
    return i;
  }

  void clearCompleted() {
    _tasks.removeWhere((t) => t.done);
    _changed();
  }
}
