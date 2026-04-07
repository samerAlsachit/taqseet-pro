import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/installment_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
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
            child: MainNavigationScreen(),
          ),
        ),
      ),
    );
  }
}
