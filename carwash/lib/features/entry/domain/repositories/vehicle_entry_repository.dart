import 'dart:io';
import '../entities/client.dart';
import '../entities/vehicle.dart';

abstract class VehicleEntryRepository {
  Future<void> saveClient(Client client);
  Future<Client?> getClientByPhone(String phone, String companyId);
  Future<Client?> getClientById(String id);
  Future<void> saveVehicle(Vehicle vehicle);
  Future<String> uploadVehicleImage({
    required File imageFile,
    required String companyId,
    required String branchId,
    required String clientId,
    required String vehicleId,
  });

  Stream<List<Vehicle>> getVehiclesStream(String companyId, {String? branchId});

  Future<void> updateVehicleStatus(String vehicleId, String status);
  Future<Map<String, String>> getServiceIdsToNames({String? companyId});
}
