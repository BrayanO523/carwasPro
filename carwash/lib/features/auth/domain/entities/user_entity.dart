class UserEntity {
  final String id;
  final String email;
  final String companyId;
  final String role; // 'admin', 'employee'
  final String name;
  final String? branchId;
  final String? emissionPoint;
  final bool isFirstLogin;

  UserEntity({
    required this.id,
    required this.email,
    required this.companyId,
    required this.role,
    required this.name,
    this.branchId,
    this.emissionPoint,
    this.isFirstLogin = true,
  });
}
