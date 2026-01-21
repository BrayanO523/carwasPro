import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../domain/entities/client.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../models/client_model.dart';
import '../models/vehicle_model.dart';

class VehicleEntryRepositoryImpl implements VehicleEntryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  VehicleEntryRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<void> saveClient(Client client) async {
    ClientModel clientModel;
    if (client is ClientModel) {
      clientModel = client;
    } else {
      clientModel = ClientModel(
        id: client.id,
        name: client.name,
        lastName: client.lastName,
        phone: client.phone,
        companyId: client.companyId,
        rtn: client.rtn,
        address: client.address,
        email: client.email,
      );
    }

    await _firestore
        .collection('clientes')
        .doc(client.id)
        .set(clientModel.toMap());
  }

  @override
  Future<Client?> getClientById(String id) async {
    try {
      final doc = await _firestore.collection('clientes').doc(id).get();
      if (doc.exists) {
        return ClientModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting client: $e');
      return null;
    }
  }

  @override
  Future<Client?> getClientByPhone(String phone, String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('clientes')
          .where('empresa_id', isEqualTo: companyId)
          .where('telefono', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ClientModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error finding client: $e');
      return null;
    }
  }

  @override
  Future<void> saveVehicle(Vehicle vehicle) async {
    await _firestore
        .collection('vehiculos')
        .doc(vehicle.id)
        .set((vehicle as VehicleModel).toMap());
  }

  @override
  Future<String> uploadVehicleImage({
    required File imageFile,
    required String companyId,
    required String branchId,
    required String clientId,
    required String vehicleId,
  }) async {
    final fileName = path.basename(imageFile.path);
    // Path structure: empresa/sucursal/cliente/vehiculo/imagen.jpg
    final storagePath = '$companyId/$branchId/$clientId/$vehicleId/$fileName';

    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  @override
  Stream<List<Vehicle>> getVehiclesStream(String companyId) {
    return _firestore
        .collection('vehiculos')
        .where('empresa_id', isEqualTo: companyId)
        .orderBy('fecha_ingreso', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    await _firestore.collection('vehiculos').doc(vehicleId).update({
      'estado': status,
    });
  }
}
