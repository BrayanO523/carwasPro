import 'package:flutter/material.dart';
import '../../domain/entities/wash_type.dart';
import '../../domain/repositories/wash_type_repository.dart';
import '../../data/models/wash_type_model.dart';

class WashTypeProvider extends ChangeNotifier {
  final WashTypeRepository _repository;

  List<WashType> _washTypes = [];
  bool _isLoading = false;
  String? _errorMessage;

  WashTypeProvider({required WashTypeRepository repository})
    : _repository = repository;

  List<WashType> get washTypes => _washTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cache Logic
  bool _isLoaded = false;

  Future<void> loadWashTypes(String companyId, {bool force = false}) async {
    if (_isLoaded && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _washTypes = await _repository.getWashTypes(companyId: companyId);
      _isLoaded = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveWashType({
    required String? id,
    required String name,
    required String description,
    required String category,
    required bool isActive,
    required Map<String, double> prices,
    required String companyId, // Current User Company
    required List<String> branchIds,
    bool isGlobal = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? targetId = id;
      // If we are editing a global (system) service, we must create a NEW record for this company
      // This "Forks" the service so edits don't affect everyone else.
      if (isGlobal) {
        targetId = ''; // Empty ID triggers 'add' in repo
      }

      final washType = WashTypeModel(
        id: targetId ?? '',
        name: name,
        description: description,
        category: category,
        isActive: isActive,
        prices: prices,
        companyId: companyId,
        branchIds: branchIds,
      );

      await _repository.saveWashType(washType);

      await loadWashTypes(companyId, force: true);
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
