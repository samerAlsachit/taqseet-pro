class SyncQueueModel {
  final int? id;
  final String operation;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> data;
  final String status;
  final DateTime createdAt;

  SyncQueueModel({
    this.id,
    required this.operation,
    required this.tableName,
    required this.recordId,
    required this.data,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'operation': operation,
    'table_name': tableName,
    'record_id': recordId,
    'data': data,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) => SyncQueueModel(
    id: map['id'],
    operation: map['operation'],
    tableName: map['table_name'],
    recordId: map['record_id'],
    data: map['data'] is String ? {} : Map<String, dynamic>.from(map['data'] ?? {}),
    status: map['status'] ?? 'pending',
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
  );
}
