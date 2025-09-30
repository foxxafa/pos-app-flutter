// lib/features/products/domain/repositories/product_repository.dart
import 'package:pos_app/features/products/domain/entities/product_model.dart';

abstract class ProductRepository {
  /// Get all products from local database
  Future<List<ProductModel>> getAllProducts();

  /// Search products by name or barcode
  Future<List<ProductModel>> searchProducts(String query);

  /// Get product by ID
  Future<ProductModel?> getProductById(int id);

  /// Get product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode);

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category);

  /// Sync products from server
  Future<void> syncProducts();

  /// Get total products count
  Future<int> getProductsCount();

  /// Update product stock
  Future<void> updateProductStock(int productId, int newStock);

  /// Check if product exists
  Future<bool> productExists(String barcode);

  /// Get low stock products
  Future<List<ProductModel>> getLowStockProducts({int threshold = 10});

  // ============= Sync Methods =============

  /// Get new products from server since specific date
  Future<List<ProductModel>?> getNewProduct(DateTime date);
}