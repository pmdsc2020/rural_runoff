import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: RuralRunoffApp(),
    ),
  );
}

class RuralRunoffApp extends StatelessWidget {
  const RuralRunoffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuralRunoff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
