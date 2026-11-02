import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/remote_config.dart';
import 'services/task_store.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TaskStore();
  final config = RemoteConfig();
  await store.load();
  // لا ننتظر الشبكة لفتح التطبيق: نستخدم النسخة المخزنة ثم نحدّث.
  config.load();
  runApp(TodoApp(store: store, config: config));
}

class TodoApp extends StatelessWidget {
  final TaskStore store;
  final RemoteConfig config;
  const TodoApp({super.key, required this.store, required this.config});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: config,
      builder: (context, _) => MaterialApp(
        title: config.appTitle,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorSchemeSeed: config.primaryColor,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: config.primaryColor,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: HomePage(store: store, config: config),
      ),
    );
  }
}
