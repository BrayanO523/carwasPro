import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_profile.dart';

class Client {
  final String id;
  final String fullName;
  final String phone;
  final String? branchId;
  final String? rtn;
  final String? address;
  final String? email;
  final String companyId;
  final CreditProfile creditProfile;
  final bool active;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.fullName,
    required this.phone,
    this.branchId,
    this.rtn,
    this.address,
    this.email,
    required this.companyId,
    this.creditProfile = const CreditProfile(),
    this.active = true,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  // Getters for backward compatibility
  double get creditLimit => creditProfile.limit;
  double get currentBalance => creditProfile.currentBalance;
  bool get creditEnabled => creditProfile.active;
  int get creditDays => creditProfile.days;
  String? get creditNotes => creditProfile.notes;

  factory Client.fromMap(Map<String, dynamic> map, String id) {
    return Client(
      id: id,
      fullName: map['fullName'] ?? map['name'] ?? '',
      phone: map['phone'] ?? '',
      rtn: map['rtn'],
      address: map['address'],
      email: map['email'],
      companyId: map['companyId'] ?? '',
      creditProfile: CreditProfile(
        limit: (map['creditLimit'] ?? 0.0).toDouble(),
        currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
        active: map['creditEnabled'] ?? false,
        days: map['creditDays'] ?? 30,
        notes: map['creditNotes'],
      ),
      active: map['active'] ?? true,
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedBy: map['updatedBy'],
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'rtn': rtn,
      'address': address,
      'email': email,
      'companyId': companyId,
      'active': active,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
      ...creditProfile.toMap(), // Flatten for storage if using standard map
    };
  }

  Client copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? rtn,
    String? address,
    String? email,
    String? companyId,
    CreditProfile? creditProfile,
    bool? active,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      rtn: rtn ?? this.rtn,
      address: address ?? this.address,
      email: email ?? this.email,
      companyId: companyId ?? this.companyId,
      creditProfile: creditProfile ?? this.creditProfile,
      active: active ?? this.active,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
