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

  Future<void> loadBranches(String companyId) async {
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

  Future<bool> addBranch({
    required String name,
    required String address,
    required String phone,
    required String companyId,
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
      );

      await _repository.createBranch(newBranch);
      _branches.add(newBranch);
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
