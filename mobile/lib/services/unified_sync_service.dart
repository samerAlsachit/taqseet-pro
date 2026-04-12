import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_action_model.dart';

/// Unified Sync Engine - محرك مزامنة موحد
///
/// يدير جميع عمليات المزامنة للتطبيق من خلال queue واحد
/// يدعم: العملاء، الأقساط، المدفوعات، المنتجات، وأي كيان آخر
class UnifiedSyncService {
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _syncMetaBoxName = 'sync_meta';

  static final UnifiedSyncService _instance = UnifiedSyncService._internal();
  factory UnifiedSyncService() => _instance;
  UnifiedSyncService._internal();

  Box<Map>? _syncQueueBox;
  Box? _metaBox;
  SupabaseClient? _supabase;

  // Stream controllers
  final _syncStatusController = StreamController<SyncEngineStatus>.broadcast();
  final _queueChangeController =
      StreamController<int>.broadcast(); // Queue count changes

  Stream<SyncEngineStatus> get syncStatusStream => _syncStatusController.stream;
  Stream<int> get queueCountStream => _queueChangeController.stream;

  // State
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _maxRetries = 3;

  SyncEngineStatus _currentStatus = SyncEngineStatus.idle;
  SyncEngineStatus get currentStatus => _currentStatus;

  /// Initialize the sync service
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _syncQueueBox = await Hive.openBox<Map>(_syncQueueBoxName);
    _metaBox = await Hive.openBox(_syncMetaBoxName);
    _supabase = Supabase.instance.client;

    _isInitialized = true;

    // Start monitoring connectivity
    _startConnectivityMonitoring();

    // Process any pending items on startup
    _notifyQueueChange();
  }

  /// ============================================
  /// Queue Operations - عمليات قائمة الانتظار
  /// ============================================

  /// Add an action to the sync queue
  /// إضافة عملية إلى قائمة المزامنة
  Future<void> queueAction(SyncAction action) async {
    await _ensureInitialized();

    await _syncQueueBox!.put(action.id, action.toJson());
    _notifyQueueChange();

    // Try to process immediately if online
    if (await isOnline()) {
      processQueue();
    }
  }

  /// Queue INSERT operation
  Future<void> queueInsert({
    required String endpoint,
    required Map<String, dynamic> data,
    String? recordId,
  }) async {
    final action = SyncAction.insert(
      endpoint: endpoint,
      data: data,
      recordId: recordId,
    );
    await queueAction(action);
  }

  /// Queue UPDATE operation
  Future<void> queueUpdate({
    required String endpoint,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final action = SyncAction.update(
      endpoint: endpoint,
      recordId: recordId,
      data: data,
    );
    await queueAction(action);
  }

  /// Queue DELETE operation
  Future<void> queueDelete({
    required String endpoint,
    required String recordId,
  }) async {
    final action = SyncAction.delete(endpoint: endpoint, recordId: recordId);
    await queueAction(action);
  }

  /// Get all pending actions from queue
  List<SyncAction> getPendingActions() {
    _ensureInitializedSync();
    if (_syncQueueBox == null) return [];

    return _syncQueueBox!.values.map((data) {
        return SyncAction.fromJson(Map<String, dynamic>.from(data));
      }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Oldest first
  }

  /// Get queue count
  int getPendingCount() {
    _ensureInitializedSync();
    return _syncQueueBox?.length ?? 0;
  }

  /// Remove action from queue after successful sync
  Future<void> removeAction(String actionId) async {
    await _ensureInitialized();
    await _syncQueueBox!.delete(actionId);
    _notifyQueueChange();
  }

  /// Update action after failed attempt (increment retry count)
  Future<void> markActionFailed(String actionId, String error) async {
    await _ensureInitialized();

    final data = _syncQueueBox!.get(actionId);
    if (data != null) {
      final action = SyncAction.fromJson(Map<String, dynamic>.from(data));
      final updatedAction = action.copyWith(
        retryCount: action.retryCount + 1,
        lastError: error,
      );

      // If max retries reached, move to dead letter queue or log
      if (updatedAction.retryCount >= _maxRetries) {
        await _moveToDeadLetterQueue(updatedAction);
        await _syncQueueBox!.delete(actionId);
      } else {
        await _syncQueueBox!.put(actionId, updatedAction.toJson());
      }

      _notifyQueueChange();
    }
  }

  /// Clear all pending actions
  Future<void> clearQueue() async {
    await _ensureInitialized();
    await _syncQueueBox!.clear();
    _notifyQueueChange();
  }

  /// ============================================
  /// Queue Processing - معالجة قائمة الانتظار
  /// ============================================

  /// Callback for showing sync notifications (set by UI)
  void Function(String message)? onSyncSuccess;
  void Function(String message)? onSyncError;

  /// Process all pending actions in the queue
  /// المعالجة المركزية للـ Queue مع Retry Mechanism
  Future<ProcessResult> processQueue() async {
    await _ensureInitialized();

    if (_isProcessing) {
      return ProcessResult.alreadyProcessing();
    }

    if (!await isOnline()) {
      return ProcessResult.offline();
    }

    _isProcessing = true;
    _currentStatus = SyncEngineStatus.processing;
    _syncStatusController.add(_currentStatus);

    final pendingActions = getPendingActions();

    if (pendingActions.isEmpty) {
      _isProcessing = false;
      _currentStatus = SyncEngineStatus.idle;
      _syncStatusController.add(_currentStatus);
      return ProcessResult.success(processed: 0, failed: 0);
    }

    int successCount = 0;
    int failCount = 0;
    List<String> failedIds = [];

    for (final action in pendingActions) {
      try {
        final result = await _processActionWithRetry(action);

        if (result) {
          await removeAction(action.id);
          successCount++;
          // Notify UI of successful sync
          onSyncSuccess?.call('تمت مزامنة ${action.action.displayName} بنجاح');
        } else {
          await markActionFailed(
            action.id,
            'فشل بعد ${action.retryCount} محاولات',
          );
          failCount++;
          failedIds.add(action.id);
        }
      } catch (e) {
        await markActionFailed(action.id, e.toString());
        failCount++;
        failedIds.add(action.id);
      }
    }

    _isProcessing = false;

    // Update last sync time
    await _updateLastSyncTime();

    // Determine final status
    if (failCount == 0) {
      _currentStatus = SyncEngineStatus.completed;
    } else if (successCount == 0) {
      _currentStatus = SyncEngineStatus.failed;
    } else {
      _currentStatus = SyncEngineStatus.partial;
    }

    _syncStatusController.add(_currentStatus);

    // Show final notification
    if (successCount > 0 && failCount == 0) {
      onSyncSuccess?.call('تمت مزامنة $successCount عملية بنجاح');
    } else if (failCount > 0) {
      onSyncError?.call('فشلت مزامنة $failCount عملية');
    }

    return ProcessResult(
      success: failCount == 0 || successCount > 0,
      processed: successCount,
      failed: failCount,
      failedIds: failedIds,
    );
  }

  /// Process action with automatic retry
  /// محاولة المعالجة مع إعادة المحاولة التلقائية
  Future<bool> _processActionWithRetry(SyncAction action) async {
    int attempts = 0;
    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 30);

    while (attempts < maxAttempts) {
      try {
        final result = await _processAction(action);
        if (result) return true;

        // Failed but no exception - might be server error
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        // Check if it's a network error
        final errorStr = e.toString().toLowerCase();
        final isNetworkError =
            errorStr.contains('socket') ||
            errorStr.contains('timeout') ||
            errorStr.contains('connection') ||
            errorStr.contains('network');

        if (isNetworkError && attempts < maxAttempts - 1) {
          attempts++;
          await Future.delayed(retryDelay);
          continue;
        }
        return false;
      }
    }
    return false;
  }

  /// Process a single action based on its type
  /// المعالجة حسب نوع العملية
  Future<bool> _processAction(SyncAction action) async {
    try {
      switch (action.action) {
        case SyncActionType.insert:
          return await _processInsert(action);
        case SyncActionType.update:
          return await _processUpdate(action);
        case SyncActionType.delete:
          return await _processDelete(action);
      }
    } catch (e) {
      return false;
    }
  }

  /// Process INSERT operation
  Future<bool> _processInsert(SyncAction action) async {
    try {
      await _supabase!.from(action.endpoint).insert(action.data);
      return true;
    } catch (e) {
      // If record already exists, treat as success
      if (e.toString().contains('duplicate')) {
        return true;
      }
      return false;
    }
  }

  /// Process UPDATE operation
  Future<bool> _processUpdate(SyncAction action) async {
    try {
      final recordId = action.recordId ?? action.data['id'];
      if (recordId == null) return false;

      await _supabase!
          .from(action.endpoint)
          .update(action.data)
          .eq('id', recordId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process DELETE operation
  Future<bool> _processDelete(SyncAction action) async {
    try {
      final recordId = action.recordId ?? action.data['id'];
      if (recordId == null) return false;

      await _supabase!.from(action.endpoint).delete().eq('id', recordId);
      return true;
    } catch (e) {
      // If record not found, treat as success (already deleted)
      if (e.toString().contains('not found') ||
          e.toString().contains('No rows found')) {
        return true;
      }
      return false;
    }
  }

  /// ============================================
  /// Connectivity - مراقبة الاتصال
  /// ============================================

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((results) async {
      final hasInternet = results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );

      if (hasInternet && !_isProcessing && getPendingCount() > 0) {
        // Auto-process when internet returns
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Small delay for stability
        processQueue();
      }
    });
  }

  /// ============================================
  /// Helpers - دوال مساعدة
  /// ============================================

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  void _ensureInitializedSync() {
    // For sync contexts where we can't await
  }

  void _notifyQueueChange() {
    _queueChangeController.add(getPendingCount());
  }

  Future<void> _moveToDeadLetterQueue(SyncAction action) async {
    // Store failed actions for later inspection
    final deadLetterKey = 'dead_${action.id}';
    await _metaBox!.put(deadLetterKey, {
      'action': action.toJson(),
      'failed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateLastSyncTime() async {
    await _metaBox!.put('last_sync', DateTime.now().toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timestamp = _metaBox?.get('last_sync');
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Dispose and cleanup
  void dispose() {
    _syncStatusController.close();
    _queueChangeController.close();
    _syncQueueBox?.close();
    _metaBox?.close();
  }
}

/// ============================================
/// Status & Result Classes
/// ============================================

enum SyncEngineStatus { idle, processing, completed, partial, failed }

extension SyncEngineStatusExtension on SyncEngineStatus {
  String get displayName {
    switch (this) {
      case SyncEngineStatus.idle:
        return 'جاهز';
      case SyncEngineStatus.processing:
        return 'جاري المعالجة...';
      case SyncEngineStatus.completed:
        return 'تم بنجاح';
      case SyncEngineStatus.partial:
        return 'تم جزئياً';
      case SyncEngineStatus.failed:
        return 'فشل';
    }
  }
}

class ProcessResult {
  final bool success;
  final int processed;
  final int failed;
  final List<String> failedIds;
  final DateTime timestamp;

  ProcessResult({
    required this.success,
    required this.processed,
    required this.failed,
    this.failedIds = const [],
  }) : timestamp = DateTime.now();

  ProcessResult.success({required int processed, required int failed})
    : success = failed == 0,
      processed = processed,
      failed = failed,
      failedIds = const [],
      timestamp = DateTime.now();

  ProcessResult.offline()
    : success = false,
      processed = 0,
      failed = 0,
      failedIds = const [],
      timestamp = DateTime.now();

  ProcessResult.alreadyProcessing()
    : success = false,
      processed = 0,
      failed = 0,
      failedIds = const [],
      timestamp = DateTime.now();

  bool get hasPartialSuccess => success && failed > 0;
}
