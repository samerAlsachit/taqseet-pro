import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/installment_provider.dart';
import 'screens/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/unified_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://sdygpgchcyxkgqmswgyb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWdwZ2NoY3l4a2dxbXN3Z3liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyODM4MTUsImV4cCI6MjA4OTg1OTgxNX0.3gsWQTejmO2YtrhB6VnSkdAp0Du3TJQAsoJiI9beVaY',
  );

  // Initialize Unified Sync Engine
  await UnifiedSyncService().init();

  runApp(const MarsaApp());
}

class MarsaApp extends StatelessWidget {
  const MarsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => InstallmentProvider()),
        ],
        child: MaterialApp(
          title: 'Marsa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: const Locale('ar', 'IQ'),
          supportedLocales: const [
            Locale('ar', 'IQ'), // Arabic Iraq
            Locale('en', 'US'), // English US
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: LoginScreen(),
          ),
        ),
      ),
    );
  }
}
