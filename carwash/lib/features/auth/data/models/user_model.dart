import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    required super.companyId,
    required super.role,
    required super.name,
    super.branchId,
    super.emissionPoint,
    super.isFirstLogin = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      companyId: data['empresa_id'] ?? '',
      role: data['rol'] ?? 'user',
      name: data['nombre'] ?? '',
      branchId: data['sucursal_id'],
      emissionPoint: data['punto_emision'],
      isFirstLogin:
          data['is_first_login'] ?? true, // Default true for legacy users too
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'empresa_id': companyId,
      'rol': role,
      'nombre': name,
      'sucursal_id': branchId,
      'punto_emision': emissionPoint,
      'is_first_login': isFirstLogin,
    };
  }
}
