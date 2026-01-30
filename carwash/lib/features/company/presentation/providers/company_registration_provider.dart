import 'package:carwash/features/branch/data/models/branch_model.dart';
import 'package:carwash/features/branch/domain/repositories/branch_repository.dart';
import 'package:carwash/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/company_repository.dart';
import '../../data/models/company_model.dart';
import 'package:carwash/features/wash_types/domain/repositories/wash_type_repository.dart';

class CompanyRegistrationProvider extends ChangeNotifier {
  final CompanyRepository _companyRepository;
  final AuthRepository _authRepository;
  final BranchRepository _branchRepository;
  final WashTypeRepository _washTypeRepository;

  bool _isLoading = false;
  String? _errorMessage;

  // Form Controllers
  final companyNameController = TextEditingController();
  final rtnController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final adminEmailController = TextEditingController();
  final adminPasswordController = TextEditingController();
  final adminNameController = TextEditingController();

  CompanyRegistrationProvider({
    required CompanyRepository companyRepository,
    required AuthRepository authRepository,
    required BranchRepository branchRepository,
    required WashTypeRepository washTypeRepository,
  }) : _companyRepository = companyRepository,
       _authRepository = authRepository,
       _branchRepository = branchRepository,
       _washTypeRepository = washTypeRepository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> registerCompany() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Generate IDs
      final companyId = const Uuid().v4();
      final mainBranchId = const Uuid().v4();

      // 2. Create User FIRST (Signs in automatically)
      // This ensures we are authenticated for subsequent Firestore writes
      await _authRepository.registerOwner(
        email: adminEmailController.text.trim(),
        password: adminPasswordController.text.trim(),
        companyId: companyId,
        name: adminNameController.text.trim(),
        branchId: mainBranchId,
        emissionPoint: '001', // Default for first Admin/Owner
      );

      // 3. Create Company Entity
      final newCompany = CompanyModel(
        id: companyId,
        name: companyNameController.text.trim(),
        rtn: rtnController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        createdAt: DateTime.now(),
      );

      // 4. Save Company to Firestore (Authorized: isSignedIn)
      await _companyRepository.registerCompany(newCompany);

      // 5. Create Main Branch (Authorized: isSameCompany -> check User.companyId)
      final mainBranch = BranchModel(
        id: mainBranchId,
        name: 'Sucursal Principal',
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        companyId: companyId,
        establishmentNumber: '000', // Default for Main Branch
        // isMain: true? (If we had that field, but we assume first one is main for now)
      );
      await _branchRepository.createBranch(mainBranch);

      // 6. Seed Default Catalog
      await _washTypeRepository.seedDefaultWashTypes(companyId, mainBranchId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    rtnController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    adminEmailController.dispose();
    adminPasswordController.dispose();
    adminNameController.dispose();
    super.dispose();
  }
}
