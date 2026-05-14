import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'services/theme_notifier.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeNotifier.instance.init();
  runApp(const MarsaApp());
}

class MarsaApp extends StatelessWidget {
  const MarsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) => MaterialApp(
        title: 'مرساة',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeNotifier.instance.mode,
        home: const AuthGate(),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );
  }
}
