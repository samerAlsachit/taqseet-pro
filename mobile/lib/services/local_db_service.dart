import 'package:hive_flutter/hive_flutter.dart';
import '../models/installment_model.dart';

/// Local database service using Hive for offline-first architecture
class LocalDBService {
  static const String _installmentsBoxName = 'installments';
  static const String _lastSyncKey = 'last_sync_timestamp';

  Box<Map>? _installmentsBox;
  Box? _metaBox;

  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _installmentsBox = await Hive.openBox<Map>(_installmentsBoxName);
    _metaBox = await Hive.openBox('meta');
  }

  /// Save a new installment locally
  Future<String> saveInstallment(InstallmentModel installment) async {
    await _ensureInitialized();

    // Generate local ID if not exists
    final localId =
        installment.localId ??
        'local_${DateTime.now().millisecondsSinceEpoch}_${installment.id}';

    final installmentData = installment
        .copyWith(
          localId: localId,
          isSynced: false,
          createdAt: installment.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        )
        .toJSON();

    await _installmentsBox!.put(localId, installmentData);
    return localId;
  }

  /// Get all installments from local storage
  List<InstallmentModel> getAllInstallments() {
    _ensureInitializedSync();

    if (_installmentsBox == null) return [];

    return _installmentsBox!.values.map((data) {
      return InstallmentModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();
  }

  /// Get installments by sync status
  List<InstallmentModel> getInstallmentsBySyncStatus({required bool isSynced}) {
    _ensureInitializedSync();

    if (_installmentsBox == null) return [];

    return _installmentsBox!.values
        .where((data) => data['is_synced'] == isSynced)
        .map(
          (data) => InstallmentModel.fromJSON(Map<String, dynamic>.from(data)),
        )
        .toList();
  }

  /// Get only unsynced installments (for sync to Supabase)
  List<InstallmentModel> getUnsyncedInstallments() {
    return getInstallmentsBySyncStatus(isSynced: false);
  }

  /// Update an existing installment locally
  Future<void> updateInstallment(InstallmentModel installment) async {
    await _ensureInitialized();

    final localId = installment.localId ?? installment.id;
    final existingData = _installmentsBox!.get(localId);

    if (existingData != null) {
      final updatedData = installment
          .copyWith(
            updatedAt: DateTime.now(),
            isSynced: false, // Mark as unsynced when updated locally
          )
          .toJSON();

      await _installmentsBox!.put(localId, updatedData);
    }
  }

  /// Mark installment as synced after successful sync to Supabase
  Future<void> markAsSynced(String localId, {String? serverId}) async {
    await _ensureInitialized();

    final data = _installmentsBox!.get(localId);
    if (data != null) {
      data['is_synced'] = true;
      if (serverId != null) {
        data['id'] = serverId;
      }
      data['synced_at'] = DateTime.now().toIso8601String();
      await _installmentsBox!.put(localId, data);
    }
  }

  /// Delete an installment locally
  Future<void> deleteInstallment(String localId) async {
    await _ensureInitialized();
    await _installmentsBox!.delete(localId);
  }

  /// Clear all local data (use with caution)
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _installmentsBox!.clear();
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    _ensureInitializedSync();
    final timestamp = _metaBox?.get(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime() async {
    await _ensureInitialized();
    await _metaBox!.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get count of unsynced items
  int getUnsyncedCount() {
    return getUnsyncedInstallments().length;
  }

  /// Check if service is initialized
  bool get isInitialized =>
      _installmentsBox != null && _installmentsBox!.isOpen;

  // Private helpers
  Future<void> _ensureInitialized() async {
    if (_installmentsBox == null || !_installmentsBox!.isOpen) {
      await init();
    }
  }

  void _ensureInitializedSync() {
    if (_installmentsBox == null || !_installmentsBox!.isOpen) {
      // In sync context, we can't await, so return empty
      return;
    }
  }

  /// Close all boxes (call on app close)
  Future<void> close() async {
    await _installmentsBox?.close();
    await _metaBox?.close();
    _installmentsBox = null;
    _metaBox = null;
  }
}
