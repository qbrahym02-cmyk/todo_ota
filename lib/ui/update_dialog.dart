import 'package:flutter/material.dart';

import '../services/updater.dart';

Future<void> showUpdateDialog(BuildContext context, ReleaseInfo r,
    {bool force = false}) {
  return showDialog(
    context: context,
    barrierDismissible: !force,
    builder: (_) => PopScope(
      canPop: !force,
      child: _UpdateDialog(release: r, force: force),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  final ReleaseInfo release;
  final bool force;
  const _UpdateDialog({required this.release, required this.force});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      await Updater.downloadAndInstall(
          widget.release, (p) => setState(() => _progress = p));
      if (mounted && !widget.force) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _progress = null;
        _error = 'تعذّر التحديث: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null;
    return AlertDialog(
      icon: const Icon(Icons.system_update, size: 40),
      title: Text('تحديث جديد ${widget.release.versionName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.force)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('هذا التحديث إجباري للمتابعة.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (widget.release.notes.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(child: Text(widget.release.notes)),
            ),
          if (downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 4),
            Text('جاري التحميل ${((_progress ?? 0) * 100).round()}%'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        if (!widget.force && !downloading)
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('لاحقاً')),
        FilledButton(
          onPressed: downloading ? null : _start,
          child: const Text('تحديث الآن'),
        ),
      ],
    );
  }
}
