enum Priority { low, medium, high }

class Task {
  final String id;
  String title;
  String note;
  bool done;
  Priority priority;
  final DateTime createdAt;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
    this.priority = Priority.medium,
    DateTime? createdAt,
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == j['priority'],
          orElse: () => Priority.medium,
        ),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
        dueDate: j['dueDate'] == null
            ? null
            : DateTime.tryParse(j['dueDate'] as String),
      );
}
