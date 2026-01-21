import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    required super.companyId,
    required super.role,
    required super.name,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      companyId: data['company_id'] ?? '',
      role: data['role'] ?? 'employee',
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'company_id': companyId,
      'role': role,
      'name': name,
    };
  }
}
