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
  });
}
