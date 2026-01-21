import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
import 'package:carwash/features/entry/domain/repositories/vehicle_entry_repository.dart';

class BillingProvider extends ChangeNotifier {
  final VehicleEntryRepository _repository;
  StreamSubscription<List<Vehicle>>? _vehiclesSubscription;

  List<Vehicle> _allVehicles = [];
  String _searchText = '';
  bool _isLoading = true;

  BillingProvider({required VehicleEntryRepository repository})
    : _repository = repository;

  // Getters
  bool get isLoading => _isLoading;
  List<Vehicle> get vehicles => _filteredVehicles();

  void init(String companyId) {
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

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}
