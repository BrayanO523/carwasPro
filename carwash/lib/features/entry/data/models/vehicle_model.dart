import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  VehicleModel({
    required super.id,
    // required super.model, // Removed
    required super.clientId,
    required super.companyId,
    required super.entryDate,
    required super.photoUrls,
    required super.status,
    required super.clientName,
    super.plate,
    super.brand,
    super.color,
    super.branchId,
    super.vehicleType,
    super.services,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      // model: data['modelo'] ?? '', // Removed
      clientId: data['cliente_id'] ?? '',
      companyId: data['empresa_id'] ?? '',
      entryDate: (data['fecha_ingreso'] as Timestamp).toDate(),
      photoUrls: List<String>.from(data['fotos'] ?? []),
      status: data['estado'] ?? 'pending',
      clientName: data['nombre_cliente'] ?? 'Cliente Desconocido',
      plate: data['placa'],
      brand: data['marca'],
      color: data['color'],
      branchId: data['sucursal_id'],
      vehicleType: data['tipo_vehiculo'],
      services: List<String>.from(data['servicios'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'modelo': model, // Removed
      'cliente_id': clientId,
      'empresa_id': companyId,
      'fecha_ingreso': Timestamp.fromDate(entryDate),
      'fotos': photoUrls,
      'estado': status,
      'nombre_cliente': clientName,
      'placa': plate,
      'marca': brand,
      'color': color,
      'tipo_vehiculo': vehicleType,
      'sucursal_id': branchId,
      'servicios': services,
    };
  }
}
