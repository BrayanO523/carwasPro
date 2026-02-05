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
    String? operatorId,
  });

  Future<UserEntity?> registerOwner({
    required String email,
    required String password,
    required String companyId,
    required String name,
    required String branchId,
    String? emissionPoint,
  });

  Future<void> updateUser({
    required String userId,
    required String name,
    String? branchId,
    String? emissionPoint,
    String? operatorId,
  });

  Future<void> deleteUser(String userId, {String? operatorId});
  Future<void> markFirstLoginComplete(String userId);
  Future<List<UserEntity>> getUsers(String companyId, {String? branchId});
}
