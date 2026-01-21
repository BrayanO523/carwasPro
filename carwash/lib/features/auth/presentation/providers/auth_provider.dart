import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required AuthRepository authRepository})
    : _authRepository = authRepository {
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(email, password);
      _isLoading = false;
      if (user != null) {
        _currentUser = user;
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
    notifyListeners();
  }
}
