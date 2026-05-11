import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'data/datasources/local/hive_service.dart';
import 'data/datasources/local/sqlite_service.dart';
import 'data/datasources/remote/api_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'core/logger/app_logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await HiveService().init();
  await SQLiteService().init();
  ApiService().init();
  ConnectivityService().init();

  if (AppConfig.isSupabaseMode && !AppConfig.SUPABASE_URL.contains('your-project')) {
    await Supabase.initialize(
      url: AppConfig.SUPABASE_URL,
      anonKey: AppConfig.SUPABASE_ANON_KEY,
    );
  }

  await SyncService().init();

  AppLogger.info('Marsa App initialized');

  runApp(const MarsaApp());
}
