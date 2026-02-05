import 'dart:developer';
// import 'dart:io';
import 'dart:typed_data'; // Added

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:uuid/uuid.dart'; // Added for audit IDs
import '../../domain/entities/client.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../../../audit/domain/entities/audit_log.dart'; // Audit Log
import '../../../audit/domain/repositories/audit_repository.dart'; // Audit Log
import '../models/client_model.dart';
import '../models/vehicle_model.dart';
import '../../domain/entities/credit_profile.dart';
// import '../../../../core/utils/image_utils.dart';

class VehicleEntryRepositoryImpl implements VehicleEntryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuditRepository _auditRepository;

  VehicleEntryRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required AuditRepository auditRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auditRepository = auditRepository;

  @override
  Future<void> saveClient(Client client) async {
    ClientModel clientModel;
    if (client is ClientModel) {
      clientModel = client;
    } else {
      clientModel = ClientModel(
        id: client.id,
        fullName: client.fullName,
        phone: client.phone,
        companyId: client.companyId,
        rtn: client.rtn,
        address: client.address,
        email: client.email,
        creditProfile: client.creditProfile,
        active: client.active,
        createdBy: client.createdBy,
        createdAt: client.createdAt,
        updatedBy: client.updatedBy,
        updatedAt: client.updatedAt,
      );
    }

    // Check if it's new or update for audit
    final isNew =
        client.createdAt == null ||
        client.createdAt!.isAfter(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ); // Heuristic if ID check is hard w/o get

    // 1. Write to 'clients' collection (Denormalized Snapshot)
    await _firestore
        .collection('clientes')
        .doc(client.id)
        .set(clientModel.toMap());

    // 2. Write to 'client_credits' collection (Master Credit Data)
    await _saveCreditData(
      client.id,
      client.creditProfile,
      client.companyId,
      client.branchId,
    );

    // 3. Log Audit
    await _auditRepository.logEvent(
      AuditLog(
        id: const Uuid().v4(),
        action: isNew ? 'CREATE_CLIENT' : 'UPDATE_CLIENT',
        collection: 'clientes',
        documentId: client.id,
        userId: client.updatedBy ?? client.createdBy ?? 'unknown',
        userEmail: 'unknown', // Ideally passed or retrieved
        timestamp: DateTime.now(),
        details: clientModel.toMap(),
        companyId: client.companyId,
        branchId: client.branchId,
      ),
    );
  }

  Future<void> _saveCreditData(
    String clientId,
    CreditProfile profile,
    String companyId,
    String? branchId,
  ) async {
    final data = profile.toMap();
    data['empresa_id'] = companyId; // Required for Firestore security rules
    if (branchId != null) data['sucursal_id'] = branchId;
    await _firestore.collection('creditos_clientes').doc(clientId).set(data);
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
      log('Error getting client: $e');
      return null;
    }
  }

  @override
  Future<Client?> getClientByPhone(
    String phone,
    String companyId, {
    String? branchId,
  }) async {
    try {
      Query query = _firestore
          .collection('clientes')
          .where('empresa_id', isEqualTo: companyId)
          .where('telefono', isEqualTo: phone);

      if (branchId != null && branchId.isNotEmpty) {
        query = query.where('sucursal_id', isEqualTo: branchId);
      }

      final querySnapshot = await query.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        return ClientModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      log('Error finding client: $e');
      return null;
    }
  }

  @override
  Future<void> saveVehicle(Vehicle vehicle) async {
    try {
      await _firestore
          .collection('vehiculos')
          .doc(vehicle.id)
          .set((vehicle as VehicleModel).toMap());

      // Audit Log
      await _auditRepository.logEvent(
        AuditLog(
          id: const Uuid().v4(),
          action: 'CREATE_VEHICLE',
          collection: 'vehiculos',
          documentId: vehicle.id,
          userId: vehicle.updatedBy ?? vehicle.createdBy ?? 'unknown',
          userEmail: 'unknown', // Context needed
          timestamp: DateTime.now(),
          details: {
            'plate': vehicle.plate,
            'client': vehicle.clientName,
            'status': vehicle.status,
          },
          companyId: vehicle.companyId,
          branchId: vehicle.branchId,
        ),
      );
    } catch (e) {
      log('Error saving vehicle: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadVehicleImage({
    required Uint8List imageBytes,
    required String companyId,
    required String branchId,
    required String clientId,
    required String vehicleId,
    required String clientName,
    required String vehicleType,
  }) async {
    // 1. Fetch Company and Branch Names
    String companyName = companyId;
    String branchName = branchId;

    try {
      final companyDoc = await _firestore
          .collection('empresas')
          .doc(companyId)
          .get();
      if (companyDoc.exists) {
        companyName = companyDoc.data()?['nombre'] ?? companyId;
      }

      final branchDoc = await _firestore
          .collection('sucursales')
          .doc(branchId)
          .get();
      if (branchDoc.exists) {
        branchName = branchDoc.data()?['nombre'] ?? branchId;
      }
    } catch (e) {
      log('Error fetching names for storage path: $e');
    }

    // 2. Sanitize Names
    final safeCompany = _sanitizeName(companyName);
    final safeBranch = _sanitizeName(branchName);
    final safeClient = _sanitizeName(clientName);
    final safeVehicleType = _sanitizeName(vehicleType);
    // Generate filename
    final fileName =
        'img_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 4)}.jpg';

    // 3. Construct Path: company/branch/client/vehicleType/filename
    final storagePath =
        '$safeCompany/$safeBranch/$safeClient/$safeVehicleType/$fileName';

    final ref = _storage.ref().child(storagePath);
    // Use putData for cross-platform compatibility
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = await ref.putData(imageBytes, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  String _sanitizeName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscore
  }

  @override
  Stream<List<Vehicle>> getVehiclesStream(
    String companyId, {
    String? branchId,
  }) {
    Query query = _firestore
        .collection('vehiculos')
        .where('empresa_id', isEqualTo: companyId);

    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('sucursal_id', isEqualTo: branchId);
    }

    return query.orderBy('fecha_ingreso', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<List<Vehicle>> getVehicles(
    String companyId, {
    String? branchId,
  }) async {
    Query query = _firestore
        .collection('vehiculos')
        .where('empresa_id', isEqualTo: companyId);

    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('sucursal_id', isEqualTo: branchId);
    }

    final snapshot = await query
        .orderBy('fecha_ingreso', descending: true)
        .limit(500)
        .get();

    return snapshot.docs.map((doc) => VehicleModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateVehicleStatus(
    String vehicleId,
    String status, {
    String? userId,
    String? userEmail,
  }) async {
    try {
      // Get current doc for companyId
      final docRef = _firestore.collection('vehiculos').doc(vehicleId);
      final doc = await docRef.get();
      final companyId = doc.exists ? doc.get('empresa_id') : '';

      await docRef.update({
        'estado': status,
        'updatedBy': userId,
        'updatedAt': Timestamp.now(),
      });

      // Audit Log
      await _auditRepository.logEvent(
        AuditLog(
          id: const Uuid().v4(),
          action: 'UPDATE_VEHICLE_STATUS',
          collection: 'vehiculos',
          documentId: vehicleId,
          userId: userId ?? 'unknown',
          userEmail: userEmail ?? 'unknown',
          timestamp: DateTime.now(),
          details: {'oldStatus': 'unknown', 'newStatus': status},
          companyId: companyId,
          branchId: doc.exists ? doc.get('sucursal_id') : null,
        ),
      );
    } catch (e) {
      log('Error updating vehicle status: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> getServiceIdsToNames({String? companyId}) async {
    try {
      Query query = _firestore.collection('tiposLavados');

      if (companyId != null && companyId.isNotEmpty) {
        query = query.where(
          Filter.or(
            Filter('empresa_id', isNull: true),
            Filter('empresa_id', isEqualTo: companyId),
          ),
        );
      }

      final snapshot = await query.get();
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('nombre')) {
          map[doc.id] = data['nombre'] as String;
        }
      }
      return map;
    } catch (e) {
      log('Error fetching wash types: $e');
      return {};
    }
  }

  @override
  Stream<List<Client>> getClientsStream(String companyId, {String? branchId}) {
    Query query = _firestore
        .collection('clientes')
        .where('empresa_id', isEqualTo: companyId);

    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('sucursal_id', isEqualTo: branchId);
    }

    return query
        // Note: Removed 'active' server filter because existing clients may not have this field.
        // Client-side filtering handles inactive clients if active field exists and is false.
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClientModel.fromFirestore(doc))
              .where((client) => client.active != false) // Client-side filter
              .toList();
        });
  }

  @override
  Future<void> updateClientBalance(
    String clientId,
    double newBalance, {
    String? userId,
  }) async {
    // 1. Update quick access collection
    // We also need the companyId for the secure query, so let's get the doc ref
    final clientRef = _firestore.collection('clientes').doc(clientId);
    final clientDoc = await clientRef.get();

    if (!clientDoc.exists) return;
    final companyId = clientDoc.get('empresa_id');

    await clientRef.update({'saldo_actual': newBalance});

    // 2. Update secure credit profile collection
    // We try to find the credit profile by clientId AND companyId (Required by Rules)
    final creditQuery = await _firestore
        .collection('creditos_clientes')
        .where('empresa_id', isEqualTo: companyId)
        .where('cliente_id', isEqualTo: clientId)
        .limit(1)
        .get();

    if (creditQuery.docs.isNotEmpty) {
      await creditQuery.docs.first.reference.update({
        'saldo_actual': newBalance,
        'updatedBy': userId,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  @override
  Future<List<Client>> searchClients(
    String query,
    String companyId, {
    String? branchId,
  }) async {
    try {
      if (query.isEmpty) return [];

      // Note: Firestore text search is case-sensitive and prefix-only by default
      // We search on 'nombre_completo' as it's the main field now
      Query firestoreQuery = _firestore
          .collection('clientes')
          .where('empresa_id', isEqualTo: companyId);

      if (branchId != null && branchId.isNotEmpty) {
        firestoreQuery = firestoreQuery.where(
          'sucursal_id',
          isEqualTo: branchId,
        );
      }

      final snapshot = await firestoreQuery
          .where('active', isEqualTo: true) // Only show active clients
          .where('nombre_completo', isGreaterThanOrEqualTo: query)
          .where('nombre_completo', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error searching clients: $e');
      return [];
    }
  }

  @override
  Future<void> toggleClientActive(
    String clientId,
    bool isActive, {
    String? userId,
    String? userEmail,
  }) async {
    try {
      final docRef = _firestore.collection('clientes').doc(clientId);
      final doc = await docRef.get();
      final companyId = doc.exists ? doc.get('empresa_id') : '';

      await docRef.update({
        'active': isActive,
        'activo': isActive, // Legacy/DB field
        'updatedBy': userId,
        'updatedAt': Timestamp.now(),
      });

      // Audit Log
      await _auditRepository.logEvent(
        AuditLog(
          id: const Uuid().v4(),
          action: isActive ? 'ACTIVATE_CLIENT' : 'DEACTIVATE_CLIENT',
          collection: 'clientes',
          documentId: clientId,
          userId: userId ?? 'unknown',
          userEmail: userEmail ?? 'unknown',
          timestamp: DateTime.now(),
          details: {'isActive': isActive},
          companyId: companyId,
          branchId: doc.exists ? doc.get('sucursal_id') : null,
        ),
      );
    } catch (e) {
      log('Error toggling client active state: $e');
      rethrow;
    }
  }
}
