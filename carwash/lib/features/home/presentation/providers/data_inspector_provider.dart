import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../company/data/models/company_model.dart';
import '../../../branch/data/models/branch_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../entry/data/models/vehicle_model.dart';
import '../../../wash_types/data/models/wash_type_model.dart';
import '../../../products/data/models/product_model.dart';
// import '../../../billing/data/models/invoice_model.dart';
// import '../../../branch/domain/entities/branch.dart';
// import '../../../../core/utils/start_end_date_utils.dart';

class DataInspectorProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Global Filter
  String? _selectedBranchId;
  String? get selectedBranchId => _selectedBranchId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Data Containers
  // Data Containers
  CompanyModel? company;
  List<BranchModel> branches = [];
  List<UserModel> users = [];
  List<VehicleModel> vehicles = [];
  List<WashTypeModel> washTypes = [];
  List<ProductModel> products = [];
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> fiscalConfigs = [];

  // Invoices? Might be heavy, maybe just fetch last 50 or by date.
  // User requested "ABSOLUTELY ALL DATA".
  // We'll fetch all but be mindful.

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
      // 1. Fetch Company (Always)
      final companyDoc = await _firestore.collection('empresas').doc(cid).get();
      if (companyDoc.exists) {
        company = CompanyModel.fromFirestore(companyDoc);
      }

      // 2. Fetch Branches
      final branchSnaps = await _firestore
          .collection('sucursales')
          .where('empresa_id', isEqualTo: cid)
          .get();
      branches = branchSnaps.docs
          .map((d) => BranchModel.fromFirestore(d))
          .toList();

      // 3. Fetch Users
      Query userQuery = _firestore
          .collection('usuarios')
          .where('empresa_id', isEqualTo: cid);
      if (_selectedBranchId != null) {
        userQuery = userQuery.where(
          'sucursal_id',
          isEqualTo: _selectedBranchId,
        );
      }
      final userSnaps = await userQuery.get();
      users = userSnaps.docs.map((d) => UserModel.fromFirestore(d)).toList();

      // 4. Fetch Vehicles
      // Note: Vehicles might not have 'sucursal_id' directly indexed or named differently.
      // Based on previous files, it seems vehicles have 'sucursal_id'.
      Query vehicleQuery = _firestore
          .collection('vehiculos')
          .where('empresa_id', isEqualTo: cid);
      if (_selectedBranchId != null) {
        vehicleQuery = vehicleQuery.where(
          'sucursal_id',
          isEqualTo: _selectedBranchId,
        );
      }
      // Limit to last 500 to avoid crash? Or fetch all as requested?
      // "ABSOLUTAMENTE TODOS".
      final vehicleSnaps = await vehicleQuery
          .orderBy('fecha_ingreso', descending: true)
          .get();
      vehicles = vehicleSnaps.docs
          .map((d) => VehicleModel.fromFirestore(d))
          .toList();

      // 5. Fetch Invoices (Facturas)
      // Assuming 'facturas' collection
      Query invoiceQuery = _firestore
          .collection('facturas')
          .where('empresa_id', isEqualTo: cid);
      if (_selectedBranchId != null) {
        invoiceQuery = invoiceQuery.where(
          'sucursal_id',
          isEqualTo: _selectedBranchId,
        );
      }
      final invoiceSnaps = await invoiceQuery
          .orderBy('fecha_creacion', descending: true)
          .get();
      // Parsing to generic map for now to allow inspection of raw data even if model is partial
      invoices = invoiceSnaps.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id; // Inject ID
        return data;
      }).toList();

      // 5. Fetch all Fiscal Configs to see who is billing
      final fiscalSnaps = await _firestore
          .collection(
            'facturacion',
          ) // Check collection name in rules, it was 'facturacion'
          .where('empresa_id', isEqualTo: cid)
          .where('activo', isEqualTo: true) // Only interested in active configs
          .get();

      fiscalConfigs = fiscalSnaps.docs.map((d) {
        final data = d.data();
        data['id'] = d.id; // Inject ID
        return data;
      }).toList();

      // 6. Fetch Wash Types (Services)
      final washTypeSnaps = await _firestore
          .collection('tiposLavados')
          .where('empresa_id', isEqualTo: cid)
          .get();
      washTypes = washTypeSnaps.docs
          .map((d) => WashTypeModel.fromFirestore(d))
          .toList();

      // 7. Fetch Products
      final productSnaps = await _firestore
          .collection('productos')
          .where('empresa_id', isEqualTo: cid)
          .get();
      products = productSnaps.docs
          .map((d) => ProductModel.fromFirestore(d))
          .toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
