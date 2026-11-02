import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_ota/main.dart';
import 'package:todo_ota/models/task.dart';
import 'package:todo_ota/services/remote_config.dart';
import 'package:todo_ota/services/task_store.dart';

void main() {
  test('Task JSON round-trip', () {
    final t = Task(id: '1', title: 'شراء خبز', priority: Priority.high,
        dueDate: DateTime(2026, 8, 2));
    final back = Task.fromJson(t.toJson());
    expect(back.title, 'شراء خبز');
    expect(back.priority, Priority.high);
    expect(back.dueDate, DateTime(2026, 8, 2));
  });

  testWidgets('add, toggle and delete a task', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TaskStore();
    await store.load();
    await tester.pumpWidget(TodoApp(store: store, config: RemoteConfig()));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مهام هنا'), findsOneWidget);

    await tester.tap(find.text('مهمة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'مراجعة الدرس');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة الدرس'), findsOneWidget);
    expect(store.tasks.length, 1);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(store.tasks.first.done, isTrue);
    expect(find.text('أنجزت 1 من 1'), findsOneWidget);

    await tester.drag(find.text('مراجعة الدرس'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(store.tasks, isEmpty);
  });
}
