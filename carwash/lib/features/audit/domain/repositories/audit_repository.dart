import '../entities/audit_log.dart';

abstract class AuditRepository {
  Future<void> logEvent(AuditLog log);
  Future<List<AuditLog>> getAuditLogs(
    String companyId, {
    String? userId,
    String? branchId,
    int limit = 50,
  });
}
