import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.companyId,
    super.rtn,
    super.address,
    super.email,
    super.branchId,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      fullName:
          data['nombre_completo'] ??
          '${data['nombre']} ${data['apellido']}'.trim(),
      phone: data['telefono'] ?? '',
      companyId: data['empresa_id'] ?? '',
      rtn: data['rtn'],
      address: data['direccion'],
      email: data['email'],
      branchId: data['sucursal_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre_completo': fullName,
      'telefono': phone,
      'empresa_id': companyId,
      'rtn': rtn,
      'direccion': address,
      'email': email,
      'sucursal_id': branchId,
    };
  }
}
