import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/branch.dart';

class BranchModel extends Branch {
  BranchModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phone,
    required super.companyId,
    super.establishmentNumber = '000',
    super.createdBy,
    super.createdAt,
    super.updatedBy,
    super.updatedAt,
  });

  factory BranchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BranchModel(
      id: doc.id,
      name: data['nombre'] ?? '',
      address: data['direccion'] ?? '',
      phone: data['telefono'] ?? '',
      companyId: data['empresa_id'] ?? '',
      establishmentNumber: data['numero_establecimiento'] ?? '000',
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedBy: data['updatedBy'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'direccion': address,
      'telefono': phone,
      'empresa_id': companyId,
      'numero_establecimiento': establishmentNumber,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }
}
