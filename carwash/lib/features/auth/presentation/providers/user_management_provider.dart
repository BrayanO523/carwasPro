import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../branch/domain/repositories/branch_repository.dart';
import '../../../branch/domain/entities/branch.dart';
import '../../domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';

class UserManagementProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BranchRepository _branchRepository;

  List<UserEntity> _users = [];
  List<Branch> _branches = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? _selectedBranchId; // Made private
  String _selectedRole = 'user'; // Default to user (employee)

  String? get selectedBranchId => _selectedBranchId;
  String get selectedRole => _selectedRole;

  void setSelectedBranch(String? value) {
    _selectedBranchId = value;
    notifyListeners();
  }

  void setSelectedRole(String value) {
    _selectedRole = value;
    notifyListeners();
  }

  UserManagementProvider({
    required AuthRepository authRepository,
    required BranchRepository branchRepository,
  }) : _authRepository = authRepository,
       _branchRepository = branchRepository;

  List<UserEntity> get users => _users;
  List<Branch> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cache State
  String? _lastConfigCompanyId;

  Future<void> loadConfig(String companyId, {bool force = false}) async {
    // Cache Check
    if (!force &&
        companyId == _lastConfigCompanyId &&
        _users.isNotEmpty &&
        _branches.isNotEmpty) {
      return;
    }
    _lastConfigCompanyId = companyId;

    _isLoading = true;
    notifyListeners();
    try {
      _branches = await _branchRepository.getBranches(companyId);
      await loadUsers(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers(String companyId) async {
    try {
      // Fetch users from Firestore directly or via Repository if we had a list method
      // For now, doing a direct query here since AuthRepository is focused on Auth methods
      // Ideally we should have a UserRepository or method in AuthRepository
      // Let's assume we do a quick query here or add getCompanyUsers to AuthRepository?
      // For speed, let's just use Firestore instance if we had access, but cleaner to update AuthRepository.
      // Actually, let's implement a simple fetch here using Firestore directly is bad practice but quick.
      // Better: Add getCompanyUsers to AuthRepository? No, AuthRepository handles Auth.
      // A UserRepository would be better. But for now, let's querying Firestore directly
      // is acceptable as a "ViewModel" logic if we inject Firestore?
      // Or just add getUsers(companyId) to AuthRepository. Let's do that in a future refactor.
      // I'll stick to creating a temporary local query here if I can verify Firestore access.
      // Wait, I don't have Firestore injected here.
      // I'll add `getCompanyUsers` to `AuthRepository` interface quickly? No better to query here if possible?
      // No, let's assume I can query Firestore via a helper or just add it to AuthRepository.
      // Let's update AuthRepository interface to include `getCompanyUsers`.

      // WAIT: I can just use FirebaseFirestore.instance for now to list users.
      print('Loading users for company: $companyId');
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('empresa_id', isEqualTo: companyId)
          .get();

      print('Found ${snapshot.docs.length} users');

      _users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<bool> createUser({required String companyId}) async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        selectedBranchId == null) {
      _errorMessage =
          'Por favor complete todos los campos y seleccione una sucursal';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _authRepository.createCompanyUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        role: _selectedRole,
        companyId: companyId,
        branchId: selectedBranchId,
      );

      _users.add(newUser);
      clearForm();
      return true;
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        _errorMessage = 'Este correo electrónico ya está registrado.';
      } else {
        _errorMessage = 'Error al crear usuario: $e';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String name,
    required String? branchId,
    required String companyId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.updateUser(
        userId: userId,
        name: name,
        branchId: branchId,
      );

      // Reload users to reflect changes
      await loadUsers(companyId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser({
    required String userId,
    required String companyId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.deleteUser(userId);
      // Reload users to reflect changes
      await loadUsers(companyId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    _selectedBranchId = null;
    _selectedRole = 'user';
    notifyListeners();
  }
}
