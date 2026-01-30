import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<void> logout();
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity> createCompanyUser({
    required String email,
    required String password,
    required String companyId,
    required String name,
    required String role,
    String? branchId,
    String? emissionPoint,
  });

  Future<UserEntity?> registerOwner({
    required String email,
    required String password,
    required String companyId,
    required String name,
    required String branchId,
    String? emissionPoint, // Added emissionPoint
  });

  Future<void> updateUser({
    required String userId,
    required String name,
    String? branchId,
    String? emissionPoint,
  });

  Future<void> deleteUser(String userId);
  Future<void> markFirstLoginComplete(String userId);
}
