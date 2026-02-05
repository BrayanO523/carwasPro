import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_repository.dart';
import '../models/audit_log_model.dart';

class AuditRepositoryImpl implements AuditRepository {
  final FirebaseFirestore _firestore;

  AuditRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> logEvent(AuditLog log) async {
    try {
      final logModel = AuditLogModel.fromEntity(log);
      await _firestore
          .collection('audit_logs')
          .doc(log.id)
          .set(logModel.toMap());
    } catch (e) {
      // Fail silently or log to console, but don't block app flow for audit failure
      developer.log('Audit Log Failed: $e');
    }
  }

  @override
  Future<List<AuditLog>> getAuditLogs(
    String companyId, {
    String? userId,
    String? branchId,
    int limit = 50,
  }) async {
    try {
      var query = _firestore
          .collection('audit_logs')
          .where('empresa_id', isEqualTo: companyId);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (branchId != null) {
        query = query.where('sucursal_id', isEqualTo: branchId);
      }

      final querySnapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        return AuditLogModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      developer.log('Error fetching Audit Logs: $e');
      return [];
    }
  }
}
