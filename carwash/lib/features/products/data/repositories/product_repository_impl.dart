import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Product>> getProducts(
    String companyId, {
    String? branchId,
  }) async {
    Query query = _firestore
        .collection('productos')
        .where('empresa_id', isEqualTo: companyId);

    if (branchId != null) {
      query = query.where('sucursal_ids', arrayContains: branchId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> saveProduct(Product product) async {
    final model = product is ProductModel
        ? product
        : ProductModel(
            id: product.id,
            companyId: product.companyId,
            branchIds: product.branchIds,
            name: product.name,
            description: product.description,
            price: product.price,
            category: product.category,
            imageUrl: product.imageUrl,
            isActive: product.isActive,
          );

    final data = model.toMap();

    if (product.id.isEmpty) {
      await _firestore.collection('productos').add(data);
    } else {
      // Don't overwrite creation date if updating
      data.remove('fecha_creacion');
      await _firestore.collection('productos').doc(product.id).update(data);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('productos').doc(productId).delete();
  }
}
