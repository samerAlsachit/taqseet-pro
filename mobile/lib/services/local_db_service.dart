import 'package:hive_flutter/hive_flutter.dart';
import '../models/installment_model.dart';

/// Local database service using Hive for offline-first architecture
/// مع دعم المزامنة التراكمية (Incremental Sync)
class LocalDBService {
  static const String _installmentsBoxName = 'installments';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _appSettingsBoxName = 'app_settings';
  static const String _incrementalSyncKey = 'last_incremental_sync';

  Box<Map>? _installmentsBox;
  Box? _metaBox;
  Box? _appSettingsBox;

  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _installmentsBox = await Hive.openBox<Map>(_installmentsBoxName);
    _metaBox = await Hive.openBox('meta');
    _appSettingsBox = await Hive.openBox(_appSettingsBoxName);
  }

  /// ============================================
  /// Incremental Sync Methods - المزامنة التراكمية
  /// ============================================

  /// Get last incremental sync timestamp for a specific table
  DateTime? getLastIncrementalSyncTime(String tableName) {
    _ensureInitializedSync();
    final key = '${_incrementalSyncKey}_$tableName';
    final timestamp = _appSettingsBox?.get(key);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Update last incremental sync timestamp for a specific table
  Future<void> updateLastIncrementalSyncTime(String tableName) async {
    await _ensureInitialized();
    final key = '${_incrementalSyncKey}_$tableName';
    await _appSettingsBox!.put(key, DateTime.now().toIso8601String());
  }

  /// Upsert (Insert or Update) an installment from server
  /// Used during incremental sync to merge server data
  Future<void> upsertInstallmentFromServer(InstallmentModel installment) async {
    await _ensureInitialized();

    final localId = installment.localId ?? installment.id;
    if (localId.isEmpty) return;

    final existingData = _installmentsBox!.get(localId);

    if (existingData != null) {
      // Update existing - but preserve local modifications if newer
      final localUpdatedAt = DateTime.tryParse(
        existingData['updated_at'] ?? '',
      );
      final serverUpdatedAt = installment.updatedAt;

      // Only update if server data is newer or same time
      if (serverUpdatedAt != null &&
          (localUpdatedAt == null ||
              !serverUpdatedAt.isBefore(localUpdatedAt))) {
        final updatedData = installment
            .copyWith(
              isSynced: true, // Server data is already synced
            )
            .toJSON();
        await _installmentsBox!.put(localId, updatedData);
      }
    } else {
      // Insert new - mark as synced since it came from server
      final newData = installment
          .copyWith(localId: localId, isSynced: true)
          .toJSON();
      await _installmentsBox!.put(localId, newData);
    }
  }

  /// Batch upsert multiple installments from server
  Future<int> batchUpsertFromServer(List<InstallmentModel> installments) async {
    await _ensureInitialized();
    int count = 0;

    for (final installment in installments) {
      await upsertInstallmentFromServer(installment);
      count++;
    }

    return count;
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

    if (_installmentsBox == null) {
      print('📦 LocalDB: Installments box is null');
      return [];
    }

    final allData = _installmentsBox!.values.toList();
    print('📦 LocalDB: Found ${allData.length} total installments in Hive');

    return allData.map((data) {
      return InstallmentModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();
  }

  /// Get installments by customer name (with fallback search)
  List<InstallmentModel> getInstallmentsByCustomerName(String customerName) {
    _ensureInitializedSync();

    print('🔍 LocalDB: Searching installments for customer: "$customerName"');

    if (_installmentsBox == null) {
      print('📦 LocalDB: Installments box is null');
      return [];
    }

    final allData = _installmentsBox!.values.toList();
    print('📦 LocalDB: Total installments in box: ${allData.length}');

    // Normalize customer name for search (trim spaces, case insensitive)
    final normalizedSearchName = customerName.trim().toLowerCase();

    final matchingData = allData.where((data) {
      final dataCustomerName =
          (data['customer_name'] ?? data['customerName'] ?? '').toString();
      final normalizedDataName = dataCustomerName.trim().toLowerCase();

      // Debug: print all customer names we're comparing
      print('  Comparing: "$normalizedDataName" == "$normalizedSearchName"');

      return normalizedDataName == normalizedSearchName;
    }).toList();

    print('✅ LocalDB: Found ${matchingData.length} matching installments');

    return matchingData.map((data) {
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

  /// Check if installments box is empty
  bool isInstallmentsEmpty() {
    _ensureInitializedSync();
    if (_installmentsBox == null) return true;
    return _installmentsBox!.isEmpty;
  }

  /// Debug: Print all customer names in the database
  void debugPrintAllCustomerNames() {
    _ensureInitializedSync();

    if (_installmentsBox == null) {
      print('📦 LocalDB Debug: Box is null');
      return;
    }

    final allData = _installmentsBox!.values.toList();
    print('📦 LocalDB Debug: ${allData.length} installments found:');

    for (var i = 0; i < allData.length; i++) {
      final data = allData[i];
      final customerName =
          data['customer_name'] ?? data['customerName'] ?? 'Unknown';
      final customerId =
          data['customer_id'] ?? data['customerId'] ?? 'no-customer-id';
      final id = data['id'] ?? data['localId'] ?? 'no-id';
      print(
        '  [$i] ID: $id, CustomerID: $customerId, Customer: "$customerName"',
      );
    }
  }

  /// Get installments by customer ID (more reliable than name)
  List<InstallmentModel> getInstallmentsByCustomerId(String customerId) {
    _ensureInitializedSync();

    print('🔍 LocalDB: Searching installments for customer ID: "$customerId"');

    if (_installmentsBox == null) {
      print('📦 LocalDB: Installments box is null');
      return [];
    }

    final allData = _installmentsBox!.values.toList();
    print('📦 LocalDB: Total installments in box: ${allData.length}');

    final matchingData = allData.where((data) {
      final dataCustomerId = (data['customer_id'] ?? data['customerId'] ?? '')
          .toString();
      return dataCustomerId == customerId;
    }).toList();

    print(
      '✅ LocalDB: Found ${matchingData.length} matching installments by customer ID',
    );

    return matchingData.map((data) {
      return InstallmentModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();
  }

  /// Clear installments box and re-fetch from server
  /// Use this when table name changes or data is corrupted
  Future<void> clearAndRefetchInstallments() async {
    await _ensureInitialized();

    print('🗑️ LocalDB: Clearing installments box...');
    await _installmentsBox!.clear();

    // Reset sync timestamp to force full re-fetch
    await _appSettingsBox!.delete('${_incrementalSyncKey}_installment_plans');
    await _appSettingsBox!.delete('${_incrementalSyncKey}_installments');

    print('✅ LocalDB: Box cleared, ready for re-fetch from installment_plans');
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

  /// Clear all boxes (call on app close)
  Future<void> close() async {
    await _installmentsBox?.close();
    await _metaBox?.close();
    await _appSettingsBox?.close();
    _installmentsBox = null;
    _metaBox = null;
    _appSettingsBox = null;
  }
}
