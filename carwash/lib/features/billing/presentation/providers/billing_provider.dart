import 'dart:developer';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
import 'package:carwash/features/entry/domain/repositories/vehicle_entry_repository.dart';
import 'package:carwash/features/billing/domain/repositories/balance_repository.dart';
import 'package:carwash/features/billing/domain/entities/fiscal_config.dart';

import 'package:carwash/features/entry/domain/entities/client.dart';
import 'package:carwash/features/company/domain/entities/company.dart';
import 'package:carwash/features/branch/domain/entities/branch.dart';
import 'package:carwash/features/billing/domain/entities/invoice.dart';
import 'package:carwash/features/billing/domain/entities/invoice_item.dart';
import 'package:carwash/features/auth/domain/entities/user_entity.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class BillingProvider extends ChangeNotifier {
  final VehicleEntryRepository _repository;
  final BalanceRepository _balanceRepository;
  StreamSubscription<List<Vehicle>>? _vehiclesSubscription;

  // Fiscal Config moved below, duplicate removed here

  List<Vehicle> _allVehicles = [];
  String _searchText = '';
  bool _isLoading = true;

  BillingProvider({
    required VehicleEntryRepository repository,
    required BalanceRepository balanceRepository,
  }) : _repository = repository,
       _balanceRepository = balanceRepository;

  // Getters
  bool get isLoading => _isLoading;
  List<Vehicle> get vehicles => _filteredVehicles();

  // Cache state
  String? _currentCompanyId;

  void init(String companyId, {bool force = false}) {
    // Cache check
    if (!force && companyId == _currentCompanyId) return;
    _currentCompanyId = companyId;

    _isLoading = true;
    notifyListeners();

    _vehiclesSubscription?.cancel();
    _vehiclesSubscription = _repository
        .getVehiclesStream(companyId)
        .listen(
          (vehicles) {
            _allVehicles = vehicles;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            log('Error listening to vehicles: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> refresh() async {
    if (_currentCompanyId != null) {
      init(_currentCompanyId!, force: true);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  List<Vehicle> _filteredVehicles() {
    // 1. Filter by Status: Only show vehicles that are ready for billing (washed)
    final washedVehicles = _allVehicles
        .where((v) => v.status == Vehicle.statusWashed)
        .toList();

    if (_searchText.isEmpty) {
      return washedVehicles;
    }

    final query = _searchText.toLowerCase();
    return washedVehicles.where((vehicle) {
      final clientMatch = vehicle.clientName.toLowerCase().contains(query);
      // final modelMatch = vehicle.model.toLowerCase().contains(query); // Removed
      final plateMatch = vehicle.plate?.toLowerCase().contains(query) ?? false;

      return clientMatch || plateMatch; // || modelMatch;
    }).toList();
  }

  Future<void> markAsFinished(String vehicleId) async {
    try {
      await _repository.updateVehicleStatus(vehicleId, Vehicle.statusFinished);
    } catch (e) {
      log('Error marking vehicle as finished: $e');
      rethrow;
    }
  }

  // Fiscal Config State
  FiscalConfig? _fiscalConfig;
  FiscalConfig? get fiscalConfig => _fiscalConfig;

  // Wash Types Catalog Cache
  List<Map<String, dynamic>> _washTypesCatalog = [];

  List<Map<String, dynamic>> get washTypesCatalog => _washTypesCatalog;

  Map<String, dynamic> getServicePrice(String serviceId, String vehicleType) {
    if (_washTypesCatalog.isEmpty) return {};

    final service = _washTypesCatalog.firstWhere(
      (s) => s['id'] == serviceId || s['documentId'] == serviceId,
      orElse: () => {},
    );

    if (service.isEmpty) return {};

    final prices = service['precios'] as Map<String, dynamic>?;
    final price = (prices?[vehicleType] ?? 0).toDouble();

    return {'price': price, 'name': service['nombre'] ?? 'Servicio'};
  }

  Future<void> loadWashTypesCatalog(
    String companyId, {
    String? branchId,
  }) async {
    // If already loaded for this company (and branch logic matches), return.
    // For simplicity, we just reload if empty or logic could be added to check consistency.
    // Ideally we should cache by companyId.

    try {
      // Fetch both Global (null) and Company Specific
      final snapshot = await FirebaseFirestore.instance
          .collection('tiposLavados')
          .where(
            Filter.or(
              Filter('empresa_id', isNull: true),
              Filter('empresa_id', isEqualTo: companyId),
            ),
          )
          .where('activo', isEqualTo: true) // Field is 'activo'
          .get();

      final allDocs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        if (!data.containsKey('id')) data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by Branch
      _washTypesCatalog = allDocs.where((service) {
        // Field in Firestore is 'sucursal_ids'
        final branchIds = List<String>.from(service['sucursal_ids'] ?? []);

        if (branchIds.isEmpty) return true; // Available to all branches

        if (branchId == null) {
          return false;
        }
        final match = branchIds.contains(branchId);
        return match;
      }).toList();

      notifyListeners();
    } catch (e) {
      log('Error loading wash types catalog: $e');
    }
  }

  // Products Catalog Cache
  List<Map<String, dynamic>> _productsCatalog = [];
  List<Map<String, dynamic>> get productsCatalog => _productsCatalog;

  Future<void> loadProductsCatalog(String companyId, {String? branchId}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('productos')
          .where('empresa_id', isEqualTo: companyId)
          .where('activo', isEqualTo: true)
          .limit(100)
          .get();

      final allProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by Branch
      _productsCatalog = allProducts.where((product) {
        final branchIds = List<String>.from(product['sucursal_ids'] ?? []);

        if (branchIds.isEmpty) {
          return true; // Available to all branches if empty? Or restricted? Usually empty means global.
        }

        if (branchId == null) {
          return false; // If no branch selected, maybe don't show restricted products
        }
        return branchIds.contains(branchId);
      }).toList();

      notifyListeners();
    } catch (e) {
      log('Error loading products catalog: $e');
    }
  }

  // Fiscal Config Methods
  String? _lastFiscalCompanyId;
  String? _lastFiscalBranchId;

  Future<void> loadFiscalConfig(
    String companyId,
    String? branchId, {
    String? emissionPoint,
  }) async {
    // Cache Check
    if (_fiscalConfig != null &&
        companyId == _lastFiscalCompanyId &&
        branchId == _lastFiscalBranchId &&
        ((_fiscalConfig == null && emissionPoint == null) ||
            (_fiscalConfig?.emissionPoint == emissionPoint))) {
      return;
    }

    _lastFiscalCompanyId = companyId;
    _lastFiscalBranchId = branchId;

    try {
      // 1. Try to fetch SPECIFIC config for this User's Emission Point
      var config = await _balanceRepository.getFiscalConfig(
        companyId,
        branchId,
        emissionPoint,
      );

      // 2. Smart Pre-fill: If not found, try to find a TEMPLATE from the same branch
      if (config == null && branchId != null && emissionPoint != null) {
        // Fetch any config for this branch (ignoring emission point)
        // We reuse the same repository method but without emissionPoint filter?
        // Wait, the repo method creates a query. If we pass null, it filters only by branch.
        // But getFiscalConfig uses limit(1). This is perfect for finding "any" config to use as template.
        final templateConfig = await _balanceRepository.getFiscalConfig(
          companyId,
          branchId,
          null,
        );

        if (templateConfig != null) {
          // Create a "Draft" config reusing the valid CAI data but resetting Sequence/Point
          config = FiscalConfig(
            id: '', // New ID, will create new doc on save
            companyId: companyId,
            branchId: branchId,
            cai: templateConfig.cai, // Inherit
            rtn: templateConfig.rtn, // Inherit
            establishment: templateConfig.establishment, // Inherit
            emissionPoint: emissionPoint, // Set to CURRENT USER's point
            documentType: templateConfig.documentType, // Inherit
            rangeMin: templateConfig.rangeMin, // Inherit
            rangeMax: templateConfig.rangeMax, // Inherit
            currentSequence: templateConfig.rangeMin ?? 1, // RESET SEQUENCE
            authorizationDate: templateConfig.authorizationDate, // Inherit
            deadline: templateConfig.deadline, // Inherit
            email: templateConfig.email,
            phone: templateConfig.phone,
            address: templateConfig.address,
            active: true,
          );
        }
      }

      _fiscalConfig = config;
      notifyListeners();
    } catch (e) {
      log('Error loading fiscal config: $e');
      // Set empty or default config if needed?
    }
  }

  Future<void> updateFiscalConfig(FiscalConfig config) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if we need to archive the OLD config
      final oldConfig = _fiscalConfig;
      if (oldConfig != null &&
          oldConfig.id == config.id &&
          oldConfig.cai != null &&
          config.cai != null) {
        // If CAI Changed, Archive the old one
        if (oldConfig.cai != config.cai) {
          await _balanceRepository.archiveFiscalConfig(oldConfig);
        }
      }

      await _balanceRepository.saveFiscalConfig(config);
      _fiscalConfig = config;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      log('Error saving fiscal config: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Invoice Generation Logic
  Future<Invoice> emitInvoice({
    required Vehicle vehicle,
    required Client client,
    required Company company,
    required Branch? branch,
    required UserEntity issuer, // Added issuer
    required String rtn,
    required List<InvoiceItem> items,
    required String docType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fiscal Validation
      // 1. Fiscal Validation
      if (docType == 'invoice') {
        final config = _fiscalConfig;
        if (config == null ||
            (config.cai?.isEmpty ?? true) ||
            (config.rtn?.isEmpty ?? true)) {
          throw Exception(
            'Configuración Incompleta: Faltan datos fiscales (CAI, RTN) para facturar.',
          );
        }

        // SAR Validation: Establishment & Emission Point
        if (branch == null || branch.establishmentNumber.isEmpty) {
          throw Exception(
            'Error: La sucursal no tiene configurado el Nº Establecimiento (SAR).',
          );
        }
        if (issuer.emissionPoint == null || issuer.emissionPoint!.isEmpty) {
          throw Exception(
            'Error: El usuario no tiene configurado el Punto de Emisión (SAR).',
          );
        }

        if (config.deadline != null &&
            DateTime.now().isAfter(config.deadline!)) {
          throw Exception(
            '¡CAI VENCIDO! La fecha límite (${config.deadline}) ha expirado.',
          );
        }

        if (config.rangeMax != null &&
            config.currentSequence > config.rangeMax!) {
          throw Exception(
            '¡RANGO AGOTADO! Has alcanzado el límite de facturas (${config.rangeMax}).',
          );
        }
      }

      // 2. Generate Number & Update Sequence
      String finalInvoiceNumber =
          'REC-${DateTime.now().millisecondsSinceEpoch}';
      int? sequenceNumber;

      if (docType == 'invoice' && _fiscalConfig != null) {
        final config = _fiscalConfig!;
        final currentSeq = config.currentSequence;
        final formattedSeq = currentSeq.toString().padLeft(8, '0');

        // Dynamic Construction: AA-BB-CC-DDDDDDDD
        // AA: Establishment (Branch)
        // BB: Emission Point (User)
        // CC: Doc Type (Config - usually 01)
        // DD: Sequence
        final est = branch!.establishmentNumber.padLeft(3, '0');
        final emi = (issuer.emissionPoint ?? '001').padLeft(
          3,
          '0',
        ); // Fallback if user missing point
        final doc = (config.documentType ?? '01').padLeft(2, '0');

        finalInvoiceNumber = '$est-$emi-$doc-$formattedSeq';
        sequenceNumber = currentSeq;

        // Increment for NEXT invoice
        final updatedConfig = FiscalConfig(
          id: config.id,
          companyId: config.companyId,
          branchId: config.branchId,
          cai: config.cai!,
          rtn: config.rtn!,
          establishment: config.establishment,
          emissionPoint: config.emissionPoint,
          documentType: config.documentType,
          rangeMin: config.rangeMin,
          rangeMax: config.rangeMax,
          currentSequence: currentSeq + 1,
          authorizationDate: config.authorizationDate,
          deadline: config.deadline,
          email: config.email,
          phone: config.phone,
          address: config.address,
          active: true,
        );

        await updateFiscalConfig(updatedConfig);
      }

      // 3. Create Entity
      final subtotal = items.fold(0.0, (acc, item) => acc + item.total);
      final isv15 = subtotal * 0.15;
      final total = subtotal + isv15;

      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: company.id,
        branchId: branch?.id ?? '',
        clientId: client.id,
        vehicleId: vehicle.id,
        clientName: client.fullName,
        clientRtn: rtn,
        invoiceNumber: finalInvoiceNumber,
        items: items,
        subtotal: subtotal,
        discountTotal: 0.0,
        exemptAmount: 0.0,
        taxableAmount15: subtotal,
        taxableAmount18: 0.0,
        isv15: isv15,
        isv18: 0.0,
        totalAmount: total,
        createdAt: DateTime.now(),
        documentType: docType,
        cai: _fiscalConfig?.cai,
        caiDeadline: _fiscalConfig?.deadline,
        rangeMin: _fiscalConfig?.rangeMin,
        rangeMax: _fiscalConfig?.rangeMax,
        sequenceNumber: sequenceNumber,
      );

      // 4. Save Invoice
      await _balanceRepository.saveInvoice(invoice);

      // 5. Update Vehicle Status
      await markAsFinished(vehicle.id);

      _isLoading = false;
      notifyListeners();
      return invoice;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}
