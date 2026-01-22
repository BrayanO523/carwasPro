import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wash_type.dart';

class WashTypeModel extends WashType {
  const WashTypeModel({
    required String id,
    required String name,
    required String description,
    required String category,
    required bool isActive,
    required Map<String, double> prices,
    String? companyId,
    List<String> branchIds = const [],
  }) : super(
         id: id,
         name: name,
         description: description,
         category: category,
         isActive: isActive,
         prices: prices,
         companyId: companyId,
         branchIds: branchIds,
       );

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
