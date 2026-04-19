/// Model for sync queue actions
/// Represents a single operation to be synced to Supabase
class SyncAction {
  /// Unique ID for this action (local)
  final String id;

  /// Endpoint/table name in Supabase (e.g., 'customers', 'installments', 'payments', 'products')
  final String endpoint;

  /// Action type: INSERT, UPDATE, DELETE
  final SyncActionType action;

  /// The data payload (map of field names to values)
  final Map<String, dynamic> data;

  /// When this action was created locally
  final DateTime timestamp;

  /// Record ID (for UPDATE/DELETE operations)
  final String? recordId;

  /// Number of retry attempts
  final int retryCount;

  /// Last error message if failed
  final String? lastError;

  SyncAction({
    required this.id,
    required this.endpoint,
    required this.action,
    required this.data,
    required this.timestamp,
    this.recordId,
    this.retryCount = 0,
    this.lastError,
  });

  /// Convert to JSON for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'action': action.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'record_id': recordId,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  /// Create from JSON (Hive storage)
  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      action: SyncActionType.values.firstWhere(
        (e) => e.name == (json['action'] as String? ?? 'insert'),
        orElse: () => SyncActionType.insert,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      recordId: json['record_id'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }

  /// Create a copy with updated fields
  SyncAction copyWith({
    String? id,
    String? endpoint,
    SyncActionType? action,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? recordId,
    int? retryCount,
    String? lastError,
  }) {
    return SyncAction(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      action: action ?? this.action,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      recordId: recordId ?? this.recordId,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Create an INSERT action
  factory SyncAction.insert({
    required String endpoint,
    required Map<String, dynamic> data,
    String? recordId,
  }) {
    return SyncAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomId()}',
      endpoint: endpoint,
      action: SyncActionType.insert,
      data: data,
      timestamp: DateTime.now(),
      recordId: recordId,
    );
  }

  /// Create an UPDATE action
  factory SyncAction.update({
    required String endpoint,
    required String recordId,
    required Map<String, dynamic> data,
  }) {
    return SyncAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomId()}',
      endpoint: endpoint,
      action: SyncActionType.update,
      data: data,
      timestamp: DateTime.now(),
      recordId: recordId,
    );
  }

  /// Create a DELETE action
  factory SyncAction.delete({
    required String endpoint,
    required String recordId,
  }) {
    return SyncAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomId()}',
      endpoint: endpoint,
      action: SyncActionType.delete,
      data: {'id': recordId},
      timestamp: DateTime.now(),
      recordId: recordId,
    );
  }

  static String _generateRandomId() {
    return DateTime.now().microsecondsSinceEpoch.toString().substring(6);
  }

  @override
  String toString() {
    return 'SyncAction($action $endpoint ${recordId ?? data['id']})';
  }
}

/// Action types for sync operations
enum SyncActionType { insert, update, delete }

/// Extension to get display name for action type
extension SyncActionTypeExtension on SyncActionType {
  String get displayName {
    switch (this) {
      case SyncActionType.insert:
        return 'إضافة';
      case SyncActionType.update:
        return 'تعديل';
      case SyncActionType.delete:
        return 'حذف';
    }
  }
}
