// lib/features/products/data/repositories/product_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  ProductRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final db = await dbHelper.database;
    // Database table adı 'Product' (büyük P)
    final result = await db.query('Product', orderBy: 'urunAdi ASC');

    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'products',
      where: 'urunAdi LIKE ? OR stokKodu LIKE ? OR urunBarcode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'urunAdi ASC',
    );

    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return ProductModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'products',
      where: 'urunBarcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return ProductModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'products',
      where: 'kategori = ?',
      whereArgs: [category],
      orderBy: 'urunAdi ASC',
    );

    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  @override
  Future<void> syncProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await dio.get(ApiConfig.products);

        if (response.statusCode == 200 && response.data['success'] == true) {
          final List<dynamic> productsJson = response.data['data'];

          // Clear existing products
          final db = await dbHelper.database;
          await db.delete('products');

          // Insert new products
          for (final productJson in productsJson) {
            await db.insert('products', productJson);
          }
        }
      } catch (e) {
        throw Exception('Product sync failed: $e');
      }
    } else {
      throw Exception('No internet connection for sync');
    }
  }

  @override
  Future<int> getProductsCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return result.first['count'] as int;
  }

  @override
  Future<void> updateProductStock(int productId, int newStock) async {
    final db = await dbHelper.database;
    await db.update(
      'products',
      {'stok': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );

    // Sync with server if online
    if (await networkInfo.isConnected) {
      try {
        await dio.put(
          '${ApiConfig.products}/$productId/stock',
          data: {'stock': newStock},
        );
      } catch (e) {
        // Handle sync error - could be queued for later
      }
    }
  }

  @override
  Future<bool> productExists(String barcode) async {
    final product = await getProductByBarcode(barcode);
    return product != null;
  }

  @override
  Future<List<ProductModel>> getLowStockProducts({int threshold = 10}) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'products',
      where: 'stok <= ?',
      whereArgs: [threshold],
      orderBy: 'stok ASC',
    );

    return result.map((json) => ProductModel.fromMap(json)).toList();
  }
}