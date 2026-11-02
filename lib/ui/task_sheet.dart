import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/remote_config.dart';

Future<Task?> showTaskSheet(BuildContext context,
    {required RemoteConfig config, Task? task}) {
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskSheet(config: config, task: task),
  );
}

class _TaskSheet extends StatefulWidget {
  final RemoteConfig config;
  final Task? task;
  const _TaskSheet({required this.config, this.task});

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final _title = TextEditingController(text: widget.task?.title);
  late final _note = TextEditingController(text: widget.task?.note);
  late Priority _priority = widget.task?.priority ?? Priority.medium;
  late DateTime? _due = widget.task?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final t = widget.task;
    Navigator.pop(
      context,
      Task(
        id: t?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        note: _note.text.trim(),
        done: t?.done ?? false,
        priority: _priority,
        createdAt: t?.createdAt,
        dueDate: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.task == null ? 'مهمة جديدة' : 'تعديل المهمة',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'عنوان المهمة', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder()),
          ),
          if (c.featurePriorities) ...[
            const SizedBox(height: 16),
            SegmentedButton<Priority>(
              segments: const [
                ButtonSegment(value: Priority.low, label: Text('منخفضة')),
                ButtonSegment(value: Priority.medium, label: Text('متوسطة')),
                ButtonSegment(value: Priority.high, label: Text('عالية')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
          ],
          if (c.featureDueDates) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(_due == null
                  ? 'إضافة تاريخ استحقاق'
                  : DateFormat('EEEE d MMMM yyyy', 'ar').format(_due!)),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _due ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 5),
                );
                if (d != null) setState(() => _due = d);
              },
            ),
            if (_due != null)
              TextButton(
                  onPressed: () => setState(() => _due = null),
                  child: const Text('إزالة التاريخ')),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('حفظ')),
        ],
      ),
    );
  }
}
