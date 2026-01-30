import 'dart:developer';

import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveVehiclesProvider extends ChangeNotifier {
  final VehicleEntryRepository _repository;
  StreamSubscription<List<Vehicle>>? _vehiclesSubscription;

  List<Vehicle> _allVehicles = [];
  String _searchText = '';
  bool _isLoading = false;

  ActiveVehiclesProvider({required VehicleEntryRepository repository})
    : _repository = repository;

  // Getters
  bool get isLoading => _isLoading;
  List<Vehicle> get vehicles => _filteredVehicles();

  // Cache state
  String? _currentCompanyId;
  String? _currentBranchId;

  void init(String companyId, {String? branchId, bool force = false}) {
    if (companyId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Cache check: If generic inputs match current state, do nothing
    if (!force &&
        companyId == _currentCompanyId &&
        branchId == _currentBranchId) {
      return;
    }

    _currentCompanyId = companyId;
    _currentBranchId = branchId;

    _isLoading = true;
    notifyListeners();

    _vehiclesSubscription?.cancel();
    _vehiclesSubscription = _repository
        .getVehiclesStream(companyId, branchId: branchId)
        .listen(
          (vehicles) {
            _allVehicles = vehicles;
            _isLoading = false;
            // Load service names when vehicles are loaded
            _loadServiceNames();
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
      // Re-initialize with forced reload
      init(_currentCompanyId!, branchId: _currentBranchId, force: true);

      // Wait a bit to simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Map<String, String> _serviceNames = {};

  Future<void> _loadServiceNames() async {
    if (_currentCompanyId == null) return;
    _serviceNames = await _repository.getServiceIdsToNames(
      companyId: _currentCompanyId,
    );
    notifyListeners();
  }

  String getServiceName(String serviceId) {
    return _serviceNames[serviceId] ?? 'Cargando...';
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  List<Vehicle> _filteredVehicles() {
    // 1. Filter by Status: Only show vehicles that are currently washing
    final washingVehicles = _allVehicles
        .where((v) => v.status == Vehicle.statusWashing)
        .toList();

    if (_searchText.isEmpty) {
      return washingVehicles;
    }

    final query = _searchText.toLowerCase();
    return washingVehicles.where((vehicle) {
      final clientMatch = vehicle.clientName.toLowerCase().contains(query);
      // final modelMatch = vehicle.model.toLowerCase().contains(query);
      final plateMatch = vehicle.plate?.toLowerCase().contains(query) ?? false;

      return clientMatch || plateMatch; // || modelMatch;
    }).toList();
  }

  Future<void> markAsWashed(String vehicleId) async {
    try {
      await _repository.updateVehicleStatus(vehicleId, Vehicle.statusWashed);
    } catch (e) {
      log('Error marking vehicle as washed: $e');
      rethrow;
    }
  }

  Future<void> completeWashAndNotify({
    required Vehicle vehicle,
    required String companyName,
  }) async {
    try {
      // 1. Mark as Washed
      await markAsWashed(vehicle.id);

      // 2. Fetch Client Info
      final client = await _repository.getClientById(vehicle.clientId);
      if (client == null || client.phone.isEmpty) {
        throw NoPhoneException();
      }

      // 3. Prepare Phone
      String phone = client.phone.replaceAll(RegExp(r'\D'), '');
      if (!phone.startsWith('504')) phone = '504$phone';

      // 4. Prepare Message
      final clientName = vehicle.clientName;
      final message = Uri.encodeComponent(
        "Un gusto saludar desde $companyName, estimado $clientName, le informo que su vehiculo ya fue lavado y puede pasar por el",
      );

      // 5. Launch WhatsApp
      final webUrl = Uri.parse("https://wa.me/$phone?text=$message");

      if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
        throw WhatsAppLaunchException();
      }
    } catch (e) {
      // Re-throw known domain exceptions or wrap unknown ones
      if (e is NoPhoneException || e is WhatsAppLaunchException) {
        rethrow;
      }
      log('Error in completeWashAndNotify: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}

class NoPhoneException implements Exception {}

class WhatsAppLaunchException implements Exception {}
