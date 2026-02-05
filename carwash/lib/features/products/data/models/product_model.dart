import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.companyId,
    required super.branchIds,
    required super.name,
    required super.description,
    required super.price,
    required super.category,
    super.imageUrl,
    super.isActive,
    super.createdBy,
    super.createdAt,
    super.updatedBy,
    super.updatedAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      companyId: data['empresa_id'] ?? '',
      branchIds: List<String>.from(data['sucursal_ids'] ?? []),
      name: data['nombre'] ?? '',
      description: data['descripcion'] ?? '',
      price: (data['precio'] ?? 0).toDouble(),
      category: data['categoria'] ?? 'General',
      imageUrl: data['imagen_url'],
      isActive: data['activo'] ?? true,
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
      'empresa_id': companyId,
      'sucursal_ids': branchIds,
      'nombre': name,
      'descripcion': description,
      'precio': price,
      'categoria': category,
      'imagen_url': imageUrl,
      'activo': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }
}
