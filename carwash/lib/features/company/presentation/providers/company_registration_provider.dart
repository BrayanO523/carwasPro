import 'package:carwash/features/branch/data/models/branch_model.dart';
import 'package:carwash/features/branch/domain/repositories/branch_repository.dart';
import 'package:carwash/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/company_repository.dart';
import '../../data/models/company_model.dart';

class CompanyRegistrationProvider extends ChangeNotifier {
  final CompanyRepository _companyRepository;
  final AuthRepository _authRepository;
  final BranchRepository _branchRepository;

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
  }) : _companyRepository = companyRepository,
       _authRepository = authRepository,
       _branchRepository = branchRepository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> registerCompany() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Generate Company ID
      final companyId = const Uuid().v4();

      // 2. Create Company Entity
      final newCompany = CompanyModel(
        id: companyId,
        name: companyNameController.text.trim(),
        rtn: rtnController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        createdAt: DateTime.now(),
      );

      // 3. Save Company to Firestore
      await _companyRepository.registerCompany(newCompany);

      // 3b. Create Main Branch
      final mainBranchId = const Uuid().v4();
      final mainBranch = BranchModel(
        id: mainBranchId,
        name: 'Sucursal Principal',
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        companyId: companyId,
      );
      await _branchRepository.createBranch(mainBranch);

      // 4. Create Admin User linked to this Company and Main Branch
      await _authRepository.createCompanyUser(
        email: adminEmailController.text.trim(),
        password: adminPasswordController.text.trim(),
        companyId: companyId,
        name: adminNameController.text.trim(),
        role: 'admin',
        branchId: mainBranchId, // Assign admin to main branch
      );

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
