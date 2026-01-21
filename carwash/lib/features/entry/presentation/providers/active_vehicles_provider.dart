import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';

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

  void init(String companyId) {
    if (companyId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

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
      final modelMatch = vehicle.model.toLowerCase().contains(query);
      final plateMatch = vehicle.plate?.toLowerCase().contains(query) ?? false;

      return clientMatch || modelMatch || plateMatch;
    }).toList();
  }

  Future<void> markAsWashed(String vehicleId) async {
    try {
      await _repository.updateVehicleStatus(vehicleId, Vehicle.statusWashed);
      // The stream will automatically update the list, removing the vehicle
    } catch (e) {
      print('Error marking vehicle as washed: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}
