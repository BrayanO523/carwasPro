import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts(String companyId, {String? branchId});
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String productId);
}
