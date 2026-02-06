class UserEntity {
  final String id;
  final String email;
  final String companyId;
  final String role; // 'admin', 'employee'
  final String name;
  final List<String> permissions;
  final String? branchId;
  final String? emissionPoint;
  final bool isFirstLogin;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  UserEntity({
    required this.id,
    required this.email,
    required this.companyId,
    required this.role,
    required this.name,
    this.permissions = const [],
    this.branchId,
    this.emissionPoint,
    this.isFirstLogin = true,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });
}
