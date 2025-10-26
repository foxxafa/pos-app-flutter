// lib/features/products/data/repositories/product_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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
    // ✅ sortOrder varsa kullan (çok hızlı!), yoksa fallback
    // ✅ Sadece aktif ürünleri çek (aktif=1)
    try {
      final result = await db.query(
        'Product',
        where: 'aktif = ?',
        whereArgs: [1],
        orderBy: 'sortOrder ASC',
      );
      return result.map((json) => ProductModel.fromMap(json)).toList();
    } catch (e) {
      // sortOrder kolonu yoksa (eski database), urunAdi'ye göre sırala
      print('⚠️ sortOrder yok, urunAdi ile sıralıyorum...');
      final result = await db.query('Product');
      final products = result.map((json) => ProductModel.fromMap(json)).toList();

      products.sort((a, b) {
        final nameA = a.urunAdi.trim();
        final nameB = b.urunAdi.trim();

        // İlk karaktere bak (boş string kontrolü)
        if (nameA.isEmpty) return 1;
        if (nameB.isEmpty) return -1;

        final firstCharA = nameA[0];
        final firstCharB = nameB[0];

        // İlk karakter harf mi kontrol et
        final startsWithLetterA = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(firstCharA);
        final startsWithLetterB = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(firstCharB);

        // Harfle başlayanlar önce, sayı/özel karakterle başlayanlar sonra
        if (startsWithLetterA && !startsWithLetterB) return -1;
        if (!startsWithLetterA && startsWithLetterB) return 1;

        // İkisi de aynı tipte başlıyorsa alfabetik sırala
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      return products;
    }
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

  // ============= Sync Methods =============

  @override
  Future<List<ProductModel>?> getNewProduct(DateTime date) async {
    if (!await networkInfo.isConnected) {
      print('❌ No internet connection');
      return null;
    }

    try {
      final formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
      String formattedDate = formatter.format(date);

      // Get API key from database
      final db = await dbHelper.database;
      List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

      if (result.isEmpty) {
        print('❌ No API Key found.');
        return null;
      }

      String savedApiKey = result.first['apikey'];
      print('Retrieved API Key: $savedApiKey');

      // STEP 1: Get total product count
      print('🔄 Ürün sayısı getiriliyor...');
      final countResponse = await dio.get(
        ApiConfig.productCountsUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $savedApiKey',
            'Accept': 'application/json',
          },
        ),
      );

      if (countResponse.statusCode != 200 || countResponse.data['status'] != 1) {
        print('❌ Ürün sayısı alınamadı');
        return null;
      }

      final productCount = countResponse.data['product_count'] as int;
      print('📊 Toplam ürün sayısı: $productCount');

      // STEP 2: Download products page by page
      const pageSize = 5000;
      int page = 1;
      final allProducts = <ProductModel>[];

      while (true) {
        print('📥 Sayfa $page indiriliyor...');

        // Use Dio with retry logic
        int maxRetries = 3;
        int retryDelay = 5; // seconds
        bool pageSuccess = false;

        for (int attempt = 1; attempt <= maxRetries; attempt++) {
          try {
            print('📡 Ürün indirme denemesi $attempt/$maxRetries...');

            final response = await dio.get(
              '${ApiConfig.indexPhpBase}?r=apimobil/getnewproducts',
              queryParameters: {
                'time': formattedDate,
                'page': page,
                'limit': pageSize,
              },
              options: Options(
                headers: {
                  'Authorization': 'Bearer $savedApiKey',
                  'Accept': 'application/json',
                },
                receiveTimeout: const Duration(minutes: 5),
              ),
            );

            if (response.statusCode == 200) {
              print('✅ HTTP response alındı: ${response.statusCode}');

              final data = response.data;

              if (data['status'] == 1) {
                final List productsJson = data['customers'] ?? [];

                // Break if no more data
                if (productsJson.isEmpty) {
                  print('✅ Tüm sayfalar indirildi');
                  pageSuccess = true;
                  return allProducts;
                }

                final products = productsJson.map((json) => ProductModel.fromJson(json)).toList();
                allProducts.addAll(products);

                print('📥 Sayfa $page: ${products.length} ürün (Toplam: ${allProducts.length}/$productCount)');
                pageSuccess = true;
                page++;
                break;
              } else {
                print('❌ API status: ${data['status']} - Ürün bulunamadı');
                return allProducts.isNotEmpty ? allProducts : null;
              }
            } else {
              print('❌ HTTP Error: ${response.statusCode}');

              if (attempt == maxRetries) {
                return allProducts.isNotEmpty ? allProducts : null;
              }
            }
          } catch (e) {
            print('⚠️ Deneme $attempt başarısız: $e');

            if (attempt == maxRetries) {
              print('❌ Tüm denemeler başarısız oldu');
              return allProducts.isNotEmpty ? allProducts : null;
            }

            print('🔄 $retryDelay saniye bekleyip tekrar denenecek...');
            await Future.delayed(Duration(seconds: retryDelay));
            retryDelay *= 2; // Exponential backoff
          }
        }

        if (!pageSuccess) {
          return allProducts.isNotEmpty ? allProducts : null;
        }
      }
    } catch (e) {
      print('❌ getNewProduct error: $e');
      return null;
    }
  }
}