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

  Future<void> loadWashTypes(
    String companyId, {
    String? branchId,
    bool force = false,
  }) async {
    if (_isLoaded && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _washTypes = await _repository.getWashTypes(
        companyId: companyId,
        branchId: branchId,
      );
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
    required String userId, // Added
    bool isGlobal = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. DUPLICATE CHECK
      // Filter existing active types (excluding the one being edited)
      final duplicates = _washTypes.where((w) {
        if (w.id == id) return false; // Skip self
        return w.name.trim().toLowerCase() == name.trim().toLowerCase();
      });

      for (final dup in duplicates) {
        // Check if duplicate shares any branch with the new configuration
        final hasBranchConflict = dup.branchIds.any(
          (bId) => branchIds.contains(bId),
        );
        if (hasBranchConflict) {
          throw Exception(
            'Ya existe un servicio llamado "$name" en una de las sucursales seleccionadas.',
          );
        }
      }

      String? targetId = id;
      // If we are editing a global (system) service, we must create a NEW record for this company
      // This "Forks" the service so edits don't affect everyone else.
      if (isGlobal) {
        targetId = ''; // Empty ID triggers 'add' in repo
      }

      final isNew = targetId == null || targetId.isEmpty;

      // Fetch existing if update to preserve createdBy/At?
      // For now, simpler to assume if ID provided, it's update.
      // But we don't have the OLD object here to preserve createdAt if we just overwrite.
      // WashTypeModel constructor takes them.
      // Ideally we should start with fetched object or rely on repo merge?
      // Repo uses `set` or `update`.
      // Let's create proper model.

      // If updating, we need to know previous state to keep createdBy/createdAt!
      // But here we are building mostly from scratch.
      // PRO TIP: If we are updating an item from `_washTypes` list, we can find it!.

      DateTime? existingCreatedAt;
      String? existingCreatedBy;

      if (!isNew && !isGlobal) {
        final existing = _washTypes.firstWhere(
          (w) => w.id == targetId,
          orElse: () => WashTypeModel(
            id: '',
            name: '',
            description: '',
            category: '',
            isActive: false,
            prices: {},
          ),
        );
        if (existing.id.isNotEmpty) {
          existingCreatedAt = existing.createdAt;
          existingCreatedBy = existing.createdBy;
        }
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
        createdBy: isNew ? userId : existingCreatedBy,
        createdAt: isNew ? DateTime.now() : existingCreatedAt,
        updatedBy: userId,
        updatedAt: DateTime.now(),
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

  Future<void> seedDefaultCatalog(String companyId, String branchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.seedDefaultWashTypes(companyId, branchId);
      await loadWashTypes(companyId, branchId: branchId, force: true);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
