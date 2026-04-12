import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installment_model.dart';
import 'local_db_service.dart';

/// Sync service for offline-first architecture
/// Monitors internet connectivity and syncs local data to Supabase
class SyncService {
  final LocalDBService _localDB;
  final SupabaseClient _supabase;
  
  // Stream subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Sync status stream controller
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  // Last sync result
  SyncResult? _lastSyncResult;
  SyncResult? get lastSyncResult => _lastSyncResult;
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService({
    LocalDBService? localDB,
    SupabaseClient? supabase,
  })  : _localDB = localDB ?? LocalDBService(),
        _supabase = supabase ?? Supabase.instance.client;

  /// Initialize and start monitoring connectivity
  Future<void> init() async {
    await _localDB.init();
    _startConnectivityMonitoring();
  }

  /// Start listening to connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasInternet = results.any((result) => 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );
      
      if (hasInternet && !_isSyncing) {
        // Auto-sync when internet is available
        syncPendingInstallments();
      }
    });
  }

  /// Manually trigger sync for pending installments
  Future<SyncResult> syncPendingInstallments() async {
    if (_isSyncing) {
      return SyncResult.alreadySyncing();
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.inProgress);

    try {
      // Get all unsynced installments from local DB
      final unsyncedInstallments = _localDB.getUnsyncedInstallments();
      
      if (unsyncedInstallments.isEmpty) {
        _isSyncing = false;
        _syncStatusController.add(SyncStatus.completed);
        _lastSyncResult = SyncResult.success(syncedCount: 0);
        return _lastSyncResult!;
      }

      int successCount = 0;
      int failCount = 0;
      List<String> failedIds = [];

      // Sync each installment to Supabase
      for (final installment in unsyncedInstallments) {
        try {
          final result = await _syncInstallmentToSupabase(installment);
          
          if (result) {
            successCount++;
          } else {
            failCount++;
            failedIds.add(installment.localId ?? installment.id);
          }
        } catch (e) {
          failCount++;
          failedIds.add(installment.localId ?? installment.id);
        }
      }

      // Update last sync timestamp
      await _localDB.updateLastSyncTime();

      _isSyncing = false;
      
      if (failCount == 0) {
        _syncStatusController.add(SyncStatus.completed);
        _lastSyncResult = SyncResult.success(syncedCount: successCount);
      } else if (successCount == 0) {
        _syncStatusController.add(SyncStatus.failed);
        _lastSyncResult = SyncResult.failure(
          error: 'All sync operations failed',
          failedIds: failedIds,
        );
      } else {
        _syncStatusController.add(SyncStatus.partial);
        _lastSyncResult = SyncResult.partial(
          syncedCount: successCount,
          failedCount: failCount,
          failedIds: failedIds,
        );
      }

      return _lastSyncResult!;

    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(SyncStatus.failed);
      _lastSyncResult = SyncResult.failure(error: e.toString());
      return _lastSyncResult!;
    }
  }

  /// Sync a single installment to Supabase
  Future<bool> _syncInstallmentToSupabase(InstallmentModel installment) async {
    try {
      final data = installment.toSupabase();
      
      // Check if record already exists in Supabase
      final existing = await _supabase
          .from('installments')
          .select('id')
          .eq('id', installment.id)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing record
        await _supabase
            .from('installments')
            .update(data)
            .eq('id', installment.id);
      } else {
        // Insert new record
        await _supabase.from('installments').insert(data);
      }
      
      // Mark as synced in local DB
      await _localDB.markAsSynced(
        installment.localId ?? installment.id,
        serverId: installment.id,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check current connectivity status
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
  }

  /// Get count of pending items to sync
  int getPendingSyncCount() {
    return _localDB.getUnsyncedCount();
  }

  /// Dispose and cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status enum for UI updates
enum SyncStatus {
  idle,
  inProgress,
  completed,
  partial,
  failed,
}

/// Sync result class for detailed sync information
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final List<String> failedIds;
  final String? error;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    this.failedIds = const [],
    this.error,
  }) : timestamp = DateTime.now();

  SyncResult.success({required int syncedCount})
      : success = true,
        syncedCount = syncedCount,
        failedCount = 0,
        failedIds = const [],
        error = null,
        timestamp = DateTime.now();

  SyncResult.failure({required String error, List<String>? failedIds})
      : success = false,
        syncedCount = 0,
        failedCount = failedIds?.length ?? 0,
        failedIds = failedIds ?? [],
        error = error,
        timestamp = DateTime.now();

  SyncResult.partial({
    required int syncedCount,
    required int failedCount,
    required List<String> failedIds,
  })   : success = true,
        syncedCount = syncedCount,
        failedCount = failedCount,
        failedIds = failedIds,
        error = null,
        timestamp = DateTime.now();

  SyncResult.alreadySyncing()
      : success = false,
        syncedCount = 0,
        failedCount = 0,
        failedIds = const [],
        error = 'Sync already in progress',
        timestamp = DateTime.now();

  bool get hasPartialSuccess => success && failedCount > 0;
}
