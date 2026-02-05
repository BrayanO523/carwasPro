import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/credit_profile.dart';
// ...

class ClientModel extends Client {
  ClientModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.companyId,
    super.branchId,
    super.rtn,
    super.address,
    super.email,
    super.creditProfile,
    super.active,
    super.createdBy,
    super.createdAt,
    super.updatedBy,
    super.updatedAt,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      fullName:
          data['fullName'] ??
          data['nombre_completo'] ??
          data['nombre'] ??
          data['name'] ??
          data['clientName'] ??
          'Sin Nombre',
      phone: data['phone'] ?? data['telefono'] ?? '',
      companyId: data['empresa_id'] ?? data['companyId'] ?? '',
      branchId: data['sucursal_id'] ?? data['branchId'],
      rtn: data['rtn'],
      address: data['address'] ?? data['direccion'],
      email: data['email'],
      active: data['active'] ?? data['activo'] ?? true,
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedBy: data['updatedBy'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      // Map flat Firestore fields to CreditProfile
      creditProfile: CreditProfile(
        active: data['credito_activo'] ?? false,
        limit: (data['limite_credito'] ?? 0.0).toDouble(),
        currentBalance: (data['saldo_actual'] ?? 0.0).toDouble(),
        days: data['dias_credito'] ?? 30,
        notes: data['notas_credito'],
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      // Spanish snake_case fields (primary - matching existing DB convention)
      'nombre_completo': fullName,
      'telefono': phone,
      'empresa_id': companyId,
      'sucursal_id': branchId,
      'rtn': rtn,
      'direccion': address,
      'email': email,
      'activo': active,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
      // Credit fields (Spanish snake_case)
      'credito_activo': creditProfile.active,
      'limite_credito': creditProfile.limit,
      'saldo_actual': creditProfile.currentBalance,
      'dias_credito': creditProfile.days,
      'notas_credito': creditProfile.notes,
    };
  }
}
