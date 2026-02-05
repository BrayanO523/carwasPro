import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../company/domain/entities/company.dart';
import '../../../branch/domain/entities/branch.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../entry/domain/entities/vehicle.dart';
import '../../../wash_types/domain/entities/wash_type.dart';
import '../../../products/domain/entities/product.dart';

import '../../../company/domain/repositories/company_repository.dart';
import '../../../branch/domain/repositories/branch_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../entry/domain/repositories/vehicle_entry_repository.dart';
import '../../../wash_types/domain/repositories/wash_type_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../audit/domain/repositories/audit_repository.dart';
import '../../../audit/domain/entities/audit_log.dart';
// import '../../../billing/data/models/invoice_model.dart';
// import '../../../branch/domain/entities/branch.dart';
// import '../../../../core/utils/start_end_date_utils.dart';

class DataInspectorProvider extends ChangeNotifier {
  final CompanyRepository _companyRepository;
  final BranchRepository _branchRepository;
  final AuthRepository _authRepository;
  final VehicleEntryRepository _vehicleRepository;
  final WashTypeRepository _washTypeRepository;
  final ProductRepository _productRepository;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Temporary for fiscal config (needs repo)

  DataInspectorProvider({
    required CompanyRepository companyRepository,
    required BranchRepository branchRepository,
    required AuthRepository authRepository,
    required VehicleEntryRepository vehicleRepository,
    required WashTypeRepository washTypeRepository,
    required ProductRepository productRepository,
    required AuditRepository auditRepository,
  }) : _companyRepository = companyRepository,
       _branchRepository = branchRepository,
       _authRepository = authRepository,
       _vehicleRepository = vehicleRepository,
       _washTypeRepository = washTypeRepository,
       _productRepository = productRepository,
       _auditRepository = auditRepository;

  final AuditRepository _auditRepository;

  // Global Filter
  String? _selectedBranchId;
  String? get selectedBranchId => _selectedBranchId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Data Containers
  Company? company;
  List<Branch> branches = [];
  List<UserEntity> users = [];
  List<Vehicle> vehicles = [];
  List<WashType> washTypes = [];
  List<Product> products = [];
  List<Map<String, dynamic>> fiscalConfigs = [];

  // Audit State
  List<AuditLog> auditLogs = [];
  UserEntity? _selectedAuditUser;
  UserEntity? get selectedAuditUser => _selectedAuditUser;

  void clearSelectedAuditUser() {
    _selectedAuditUser = null;
    notifyListeners();
  }

  // Error State
  String? errorMessage;

  void setSelectedBranch(String? branchId) {
    if (_selectedBranchId != branchId) {
      _selectedBranchId = branchId;
      refreshData();
    }
  }

  Future<void> init(String companyId) async {
    _isLoading = true;
    notifyListeners();
    await refreshData(companyId: companyId);
  }

  Future<void> refreshData({String? companyId}) async {
    if (companyId == null && company == null) {
      return; // Need companyId at least once
    }
    final cid = companyId ?? company?.id;

    if (cid == null) return;

    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch Company
      company = await _companyRepository.getCompany(cid);

      // 2. Fetch Branches
      branches = await _branchRepository.getBranches(cid);

      // 3. Fetch Users
      users = await _authRepository.getUsers(cid, branchId: _selectedBranchId);

      // 4. Fetch Vehicles
      vehicles = await _vehicleRepository.getVehicles(
        cid,
        branchId: _selectedBranchId,
      );

      // 5. Fetch all Fiscal Configs to see who is billing
      // 5. Fetch all Fiscal Configs to see who is billing
      // Note: Idealmente mover a un repositorio dedicado en el futuro
      final fiscalSnaps = await _firestore
          .collection('facturacion')
          .where('empresa_id', isEqualTo: cid)
          .where('activo', isEqualTo: true) // Only interested in active configs
          .get();

      fiscalConfigs = fiscalSnaps.docs.map((d) {
        final data = d.data();
        data['id'] = d.id; // Inject ID
        return data;
      }).toList();

      // 6. Fetch Wash Types (Services)
      washTypes = await _washTypeRepository.getWashTypes(companyId: cid);

      // 7. Fetch Products
      products = await _productRepository.getProducts(cid);

      // 8. Fetch Audit Logs
      auditLogs = await _auditRepository.getAuditLogs(
        cid,
        branchId: _selectedBranchId,
        limit: 50,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuditLogsForUser(UserEntity user) async {
    final cid = company?.id;
    if (cid == null) return;

    _selectedAuditUser = user;
    // Don't notify yet, wait for loading to start

    try {
      _isLoading = true;
      notifyListeners();

      auditLogs = await _auditRepository.getAuditLogs(
        cid,
        userId: user.id,
        branchId: _selectedBranchId,
        limit: 50,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
