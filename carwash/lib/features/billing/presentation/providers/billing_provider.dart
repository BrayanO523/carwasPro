import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
import 'package:carwash/features/entry/domain/repositories/vehicle_entry_repository.dart';
import 'package:carwash/features/billing/domain/repositories/balance_repository.dart';
import 'package:carwash/features/billing/domain/entities/fiscal_config.dart';

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
            print('Error listening to vehicles: $error');
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
      final modelMatch = vehicle.model.toLowerCase().contains(query);
      final plateMatch = vehicle.plate?.toLowerCase().contains(query) ?? false;

      return clientMatch || modelMatch || plateMatch;
    }).toList();
  }

  Future<void> markAsFinished(String vehicleId) async {
    try {
      await _repository.updateVehicleStatus(vehicleId, Vehicle.statusFinished);
    } catch (e) {
      print('Error marking vehicle as finished: $e');
      rethrow;
    }
  }

  // Fiscal Config State
  FiscalConfig? _fiscalConfig;
  FiscalConfig? get fiscalConfig => _fiscalConfig;

  // Wash Types Catalog Cache
  List<Map<String, dynamic>> _washTypesCatalog = [];
  bool _isCatalogLoaded = false;

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
      print(
        'DEBUG: Loading Catalog for Company: $companyId, Branch: $branchId',
      );
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

      print(
        'DEBUG: Firestore returned ${snapshot.docs.length} active services (Global + Company).',
      );

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
        // print('DEBUG: Service ${service['nombre']} branches: $branchIds');

        if (branchIds.isEmpty) return true; // Available to all branches

        if (branchId == null) {
          print(
            'DEBUG: Discarding ${service['nombre']} because branchId arg is null',
          );
          return false;
        }
        final match = branchIds.contains(branchId);
        if (!match)
          print(
            'DEBUG: Discarding ${service['nombre']} because $branchId not in $branchIds',
          );
        return match;
      }).toList();

      print(
        'DEBUG: Final Catalog Size after Branch Filter: ${_washTypesCatalog.length}',
      );

      _isCatalogLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading wash types catalog: $e');
    }
  }

  // Fiscal Config Methods
  String? _lastFiscalCompanyId;
  String? _lastFiscalBranchId;

  Future<void> loadFiscalConfig(String companyId, String? branchId) async {
    // Cache Check
    if (_fiscalConfig != null &&
        companyId == _lastFiscalCompanyId &&
        branchId == _lastFiscalBranchId) {
      return;
    }

    _lastFiscalCompanyId = companyId;
    _lastFiscalBranchId = branchId;

    try {
      final config = await _balanceRepository.getFiscalConfig(
        companyId,
        branchId,
      );
      _fiscalConfig = config;
      notifyListeners();
    } catch (e) {
      print('Error loading fiscal config: $e');
      // Set empty or default config if needed?
    }
  }

  Future<void> updateFiscalConfig(FiscalConfig config) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _balanceRepository.saveFiscalConfig(config);
      _fiscalConfig = config;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error saving fiscal config: $e');
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
