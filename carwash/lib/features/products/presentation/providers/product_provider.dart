import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  ProductProvider({required ProductRepository repository})
    : _repository = repository;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filter Active Products Only (For Billing Screen)
  List<Product> get activeProducts =>
      _products.where((p) => p.isActive).toList();

  Future<void> loadProducts(
    String companyId, {
    String? branchId,
    bool force = false,
  }) async {
    if (!force && _products.isNotEmpty) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _products = await _repository.getProducts(companyId, branchId: branchId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveProduct(Product product) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.saveProduct(product);

      // Reload logic could be optimized, but ensuring consistency for now
      // Assuming we have companyId and branchId from the product saved
      // Or just append locally if it's new
      if (product.id.isEmpty) {
        // Since we don't have the ID from add() unless we change repo return type
        // better to reload or append a placeholder.
        // For simplicity, let's just reload in UI or accept optimistic update.
      } else {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      // _isLoading = true; // Use local loading state in UI for delete usually
      await _repository.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
