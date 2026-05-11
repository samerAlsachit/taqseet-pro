import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/logger/app_logger.dart';
import 'api_service.dart';

class StorageApi {

  Future<String?> uploadImage(String path, File file) async {
    try {
      if (AppConfig.isSupabaseMode) {
        await Supabase.instance.client.storage.from(AppConfig.SUPABASE_STORAGE_BUCKET).upload(path, file);
        final url = Supabase.instance.client.storage.from(AppConfig.SUPABASE_STORAGE_BUCKET).getPublicUrl(path);
        return url;
      }
      final res = await ApiService().uploadFile('/customers/upload', file.path, 'file');
      return res['data']?['url']?.toString() ?? file.path;
    } catch (e) {
      AppLogger.error('Image upload failed', e);
      return null;
    }
  }

  Future<void> deleteImage(String path) async {
    try {
      if (AppConfig.isSupabaseMode) {
        await Supabase.instance.client.storage.from(AppConfig.SUPABASE_STORAGE_BUCKET).remove([path]);
      }
    } catch (e) {
      AppLogger.warn('Image delete failed: $e');
    }
  }
}
