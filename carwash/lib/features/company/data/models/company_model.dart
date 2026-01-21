import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/company.dart';

class CompanyModel extends Company {
  CompanyModel({
    required super.id,
    required super.name,
    required super.rtn,
    required super.address,
    required super.phone,
    required super.email,
    required super.createdAt,
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] ?? '',
      rtn: data['rtn'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rtn': rtn,
      'address': address,
      'phone': phone,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
