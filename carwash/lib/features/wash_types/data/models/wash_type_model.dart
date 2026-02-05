import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wash_type.dart';

class WashTypeModel extends WashType {
  const WashTypeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.isActive,
    required super.prices,
    super.companyId,
    super.branchIds = const [],
    super.createdBy,
    super.createdAt,
    super.updatedBy,
    super.updatedAt,
  });

  factory WashTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final pricesMap = data['precios'] as Map<String, dynamic>? ?? {};

    // Convert prices to Map<String, double> safely
    final convertedPrices = pricesMap.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return WashTypeModel(
      id: doc.id,
      name: data['nombre'] ?? '',
      description: data['descripcion'] ?? '',
      category: data['categoria'] ?? 'base',
      isActive: data['activo'] ?? true,
      prices: convertedPrices,
      companyId: data['empresa_id'],
      branchIds: List<String>.from(data['sucursal_ids'] ?? []),
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
      'descripcion': description,
      'categoria': category,
      'activo': isActive,
      'precios': prices,
      'empresa_id': companyId,
      'sucursal_ids': branchIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }

  // Helper to clone/copy
  WashTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isActive,
    Map<String, double>? prices,
    String? companyId,
    List<String>? branchIds,
  }) {
    return WashTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      prices: prices ?? this.prices,
      companyId: companyId ?? this.companyId,
      branchIds: branchIds ?? this.branchIds,
    );
  }
}
