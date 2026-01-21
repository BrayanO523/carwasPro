import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel({
    required super.id,
    required super.name,
    required super.lastName,
    required super.phone,
    super.rtn,
    super.address,
    super.email,
    required super.companyId,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      name: data['nombre'] ?? '',
      lastName: data['apellido'] ?? '',
      phone: data['telefono'] ?? '',
      rtn: data['rtn'],
      address: data['direccion'],
      email: data['email'],
      companyId: data['empresa_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'apellido': lastName,
      'telefono': phone,
      'rtn': rtn,
      'direccion': address,
      'email': email,
      'empresa_id': companyId,
    };
  }
}
