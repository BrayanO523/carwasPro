import '../../domain/entities/audit_log.dart';

class AuditLogModel extends AuditLog {
  AuditLogModel({
    required super.id,
    required super.action,
    required super.collection,
    required super.documentId,
    required super.userId,
    required super.userEmail,
    required super.timestamp,
    required super.details,
    required super.companyId,
    super.branchId,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      action: map['action'] ?? '',
      collection: map['collection'] ?? '',
      documentId: map['documentId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      companyId: map['empresa_id'] ?? '',
      branchId: map['sucursal_id'],
    );
  }

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      action: entity.action,
      collection: entity.collection,
      documentId: entity.documentId,
      userId: entity.userId,
      userEmail: entity.userEmail,
      timestamp: entity.timestamp,
      details: entity.details,
      companyId: entity.companyId,
      branchId: entity.branchId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'collection': collection,
      'documentId': documentId,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'empresa_id': companyId,
      'sucursal_id': branchId,
    };
  }
}
