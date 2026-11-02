import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/remote_config.dart';
import '../services/task_store.dart';
import '../services/updater.dart';
import 'task_sheet.dart';
import 'update_dialog.dart';

enum Filter { all, active, done }

class HomePage extends StatefulWidget {
  final TaskStore store;
  final RemoteConfig config;
  const HomePage({super.key, required this.store, required this.config});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Filter _filter = Filter.all;
  String _query = '';
  bool _searching = false;
  bool _updateShown = false;

  TaskStore get store => widget.store;
  RemoteConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate({bool manual = false}) async {
    if (kIsWeb) {
      if (manual) _snack('نسخة الويب تتحدث تلقائياً عند إعادة تحميل الصفحة ✅');
      return;
    }
    final r = await Updater.checkForUpdate();
    if (!mounted) return;
    if (r == null) {
      if (manual) _snack('أنت تستخدم أحدث نسخة ✅');
      return;
    }
    if (_updateShown && !manual) return;
    _updateShown = true;
    final force = await Updater.currentBuild() < config.minBuild;
    if (!mounted) return;
    showUpdateDialog(context, r, force: force);
  }

  void _snack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  List<Task> _visible() {
    var list = store.tasks.where((t) => switch (_filter) {
          Filter.all => true,
          Filter.active => !t.done,
          Filter.done => t.done,
        });
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((t) =>
          t.title.toLowerCase().contains(q) || t.note.toLowerCase().contains(q));
    }
    final sorted = list.toList();
    sorted.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (config.featurePriorities && a.priority != b.priority) {
        return b.priority.index - a.priority.index;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  Future<void> _openSheet([Task? task]) async {
    final result = await showTaskSheet(context, config: config, task: task);
    if (result == null) return;
    task == null ? store.add(result) : store.update(result);
  }

  void _delete(Task t) {
    final i = store.remove(t.id);
    _snack('تم حذف "${t.title}"',
        action: SnackBarAction(
            label: 'تراجع', onPressed: () => store.insertAt(i, t)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, config]),
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final tasks = _visible();
        return Scaffold(
          appBar: AppBar(
            title: _searching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                        hintText: 'ابحث في المهام...', border: InputBorder.none),
                    onChanged: (v) => setState(() => _query = v),
                  )
                : Text(config.appTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (config.featureSearch)
                IconButton(
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    _query = '';
                  }),
                ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'clear') store.clearCompleted();
                  if (v == 'update') _checkUpdate(manual: true);
                  if (v == 'refresh') {
                    await config.load();
                    _snack('تم تحديث الإعدادات من السيرفر');
                  }
                  if (v == 'about') _about();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'clear', child: Text('حذف المكتملة')),
                  PopupMenuItem(value: 'update', child: Text('البحث عن تحديث')),
                  PopupMenuItem(value: 'refresh', child: Text('تحديث الإعدادات')),
                  PopupMenuItem(value: 'about', child: Text('حول التطبيق')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (config.announcementEnabled && config.announcementText.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.announcementColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.campaign_outlined, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(config.announcementText,
                            style: const TextStyle(color: Colors.black87))),
                  ]),
                ),
              if (config.featureStats) _stats(scheme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SegmentedButton<Filter>(
                  segments: const [
                    ButtonSegment(value: Filter.all, label: Text('الكل')),
                    ButtonSegment(value: Filter.active, label: Text('الحالية')),
                    ButtonSegment(value: Filter.done, label: Text('المكتملة')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? _empty(scheme)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96, top: 4),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _tile(tasks[i], scheme),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openSheet(),
            icon: const Icon(Icons.add),
            label: const Text('مهمة جديدة'),
          ),
        );
      },
    );
  }

  Widget _stats(ColorScheme scheme) {
    final total = store.tasks.length;
    final done = store.doneCount;
    final p = total == 0 ? 0.0 : done / total;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                  value: p, strokeWidth: 6, backgroundColor: scheme.surfaceContainerHighest),
              Text('${(p * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أنجزت $done من $total',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(total - done == 0 ? 'لا توجد مهام متبقية 🎉' : 'متبقي ${total - done} مهام',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _empty(ColorScheme scheme) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.checklist_rtl, size: 80, color: scheme.outline),
          const SizedBox(height: 12),
          Text(_query.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد مهام هنا',
              style: TextStyle(color: scheme.outline, fontSize: 16)),
        ]),
      );

  Widget _tile(Task t, ColorScheme scheme) {
    final pColor = switch (t.priority) {
      Priority.high => Colors.red,
      Priority.medium => Colors.orange,
      Priority.low => Colors.green,
    };
    final overdue =
        t.dueDate != null && !t.done && t.dueDate!.isBefore(DateTime.now());
    return Dismissible(
      key: ValueKey(t.id),
      background: Container(
        color: scheme.errorContainer,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      secondaryBackground: Container(
        color: scheme.errorContainer,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(t),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          onTap: () => _openSheet(t),
          leading: Checkbox(
            value: t.done,
            shape: const CircleBorder(),
            onChanged: (_) => store.toggle(t.id),
          ),
          title: Text(
            t.title,
            style: TextStyle(
              decoration: t.done ? TextDecoration.lineThrough : null,
              color: t.done ? scheme.outline : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: (t.note.isEmpty && t.dueDate == null)
              ? null
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (t.note.isNotEmpty)
                    Text(t.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (config.featureDueDates && t.dueDate != null)
                    Row(children: [
                      Icon(Icons.event, size: 14,
                          color: overdue ? scheme.error : scheme.outline),
                      const SizedBox(width: 4),
                      Text(DateFormat('d MMM yyyy', 'ar').format(t.dueDate!),
                          style: TextStyle(
                              fontSize: 12,
                              color: overdue ? scheme.error : scheme.outline)),
                    ]),
                ]),
          trailing: config.featurePriorities
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: pColor, shape: BoxShape.circle))
              : null,
        ),
      ),
    );
  }

  Future<void> _about() async {
    final v = await Updater.currentVersion();
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: config.appTitle,
      applicationVersion: v,
      applicationIcon: const Icon(Icons.checklist_rtl, size: 40),
      children: [
        Text(config.loadedFromNetwork
            ? 'الإعدادات محمّلة من السيرفر ✅'
            : 'الإعدادات من النسخة المحفوظة (بدون اتصال)'),
      ],
    );
  }
}
