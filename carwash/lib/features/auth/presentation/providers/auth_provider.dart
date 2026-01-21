import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../company/domain/repositories/company_repository.dart';
import '../../../branch/domain/repositories/branch_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final CompanyRepository? _companyRepository;
  final BranchRepository? _branchRepository;

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  String? _companyName;
  String? _branchName;

  AuthProvider({
    required AuthRepository authRepository,
    CompanyRepository? companyRepository,
    BranchRepository? branchRepository,
  }) : _authRepository = authRepository,
       _companyRepository = companyRepository,
       _branchRepository = branchRepository {
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      _loadAdditionalUserInfo(); // Fetch company/branch info
      notifyListeners();
    });
  }

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  String? get companyName => _companyName;
  String? get branchName => _branchName;

  Future<void> _loadAdditionalUserInfo() async {
    final user = _currentUser;
    if (user == null) {
      _companyName = null;
      _branchName = null;
      notifyListeners();
      return;
    }

    try {
      // 1. Fetch Company
      if (_companyRepository != null && user.companyId.isNotEmpty) {
        final company = await _companyRepository!.getCompany(user.companyId);
        _companyName = company?.name;
      }

      // 2. Fetch Branch
      // If user has a specific branchId, fetch it.
      if (_branchRepository != null) {
        if (user.branchId != null && user.branchId!.isNotEmpty) {
          final branch = await _branchRepository!.getBranch(user.branchId!);
          _branchName = branch?.name;
        } else {
          // Fallback: If no specific branch, and role is admin, maybe fetch the "Main" branch?
          // The user stated: "Address registered with company IS the main branch".
          // Usually we might not have a separate branch entity for main if it's implicit in company,
          // BUT the system architecture likely created a "main" branch doc during company reg.
          // Let's assume there's a branch with id 'main' or query for it?
          // Or just leave it null and let UI handle "Sucursal Principal" text?
          // Actually, earlier code in VehicleEntryProvider used 'main' as branchId.
          // Let's try to fetch branch 'main' first if branchId is null? OR check if user has 'main' branchId.
          // If branchId is null, we can try to fetch the first branch of the company.
          final branches = await _branchRepository!.getBranches(user.companyId);
          if (branches.isNotEmpty) {
            // Heuristic: First branch created is usually main.
            // Or if one is named "Principal" or matches company address.
            // For now, take the first one or display 'Sucursal Principal' if none specific.
            _branchName = branches.first.name;
          } else {
            _branchName = 'Sucursal Principal';
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading additional user info: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(email, password);
      _isLoading = false;
      if (user != null) {
        _currentUser = user;
        await _loadAdditionalUserInfo();
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Credenciales inválidas';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _companyName = null;
    _branchName = null;
    notifyListeners();
  }
}
