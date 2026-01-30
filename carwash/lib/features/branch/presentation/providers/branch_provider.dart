import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';
import '../../data/models/branch_model.dart';

class BranchProvider extends ChangeNotifier {
  final BranchRepository _repository;

  List<Branch> _branches = [];
  bool _isLoading = false;
  String? _errorMessage;

  BranchProvider({required BranchRepository repository})
    : _repository = repository;

  List<Branch> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cache State
  String? _lastCompanyId;

  Future<void> loadBranches(String companyId, {bool force = false}) async {
    // Cache check
    if (!force && companyId == _lastCompanyId && _branches.isNotEmpty) return;
    _lastCompanyId = companyId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _branches = await _repository.getBranches(companyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Branch?> addBranch({
    required String name,
    required String address,
    required String phone,
    required String companyId,
    String establishmentNumber = '000',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newBranch = BranchModel(
        id: const Uuid().v4(),
        name: name,
        address: address,
        phone: phone,
        companyId: companyId,
        establishmentNumber: establishmentNumber,
      );

      await _repository.createBranch(newBranch);
      _branches.add(newBranch);
      return newBranch;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBranch({
    required String id,
    required String name,
    required String address,
    required String phone,
    required String companyId,
    String establishmentNumber = '000',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedBranch = BranchModel(
        id: id,
        name: name,
        address: address,
        phone: phone,
        companyId: companyId,
        establishmentNumber: establishmentNumber,
      );

      await _repository.updateBranch(updatedBranch);

      final index = _branches.indexWhere((b) => b.id == id);
      if (index != -1) {
        _branches[index] = updatedBranch;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
