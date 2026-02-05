class AuditLog {
  final String id;
  final String action; // CREATE, UPDATE, DELETE, TOGGLE_STATUS
  final String collection; // vehicles, clients, etc.
  final String documentId;
  final String userId;
  final String userEmail;
  final DateTime timestamp;
  final Map<String, dynamic> details; // Changed fields, old/new values
  final String companyId;
  final String? branchId;

  AuditLog({
    required this.id,
    required this.action,
    required this.collection,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    required this.timestamp,
    required this.details,
    required this.companyId,
    this.branchId,
  });
}
