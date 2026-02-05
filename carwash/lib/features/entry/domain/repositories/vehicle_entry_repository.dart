// import 'dart:io';
import 'dart:typed_data';

import '../entities/client.dart';
import '../entities/vehicle.dart';

abstract class VehicleEntryRepository {
  Future<void> saveClient(Client client);
  Future<Client?> getClientByPhone(
    String phone,
    String companyId, {
    String? branchId,
  });
  Future<Client?> getClientById(String id);
  Future<void> saveVehicle(Vehicle vehicle);
  Future<String> uploadVehicleImage({
    required Uint8List imageBytes,
    required String companyId,
    required String branchId,
    required String clientId,
    required String vehicleId,
    required String clientName,
    required String vehicleType,
  });

  Stream<List<Vehicle>> getVehiclesStream(String companyId, {String? branchId});
  Future<List<Vehicle>> getVehicles(String companyId, {String? branchId});

  Future<void> updateVehicleStatus(
    String vehicleId,
    String status, {
    String? userId,
    String? userEmail,
  });
  Future<Map<String, String>> getServiceIdsToNames({String? companyId});
  Stream<List<Client>> getClientsStream(String companyId, {String? branchId});
  Future<void> updateClientBalance(
    String clientId,
    double newBalance, {
    String? userId,
  });
  Future<List<Client>> searchClients(
    String query,
    String companyId, {
    String? branchId,
  });
  Future<void> toggleClientActive(
    String clientId,
    bool isActive, {
    String? userId,
    String? userEmail,
  });
}
