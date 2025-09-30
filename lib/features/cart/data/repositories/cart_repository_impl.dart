// lib/features/cart/data/repositories/cart_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  CartRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  @override
  Future<void> addItemToCart(String stokKodu, String urunAdi, double birimFiyat,
      String urunBarcode, int vat, {int miktar = 1, String birimTipi = 'Unit',
      int iskonto = 0, String? imsrc, String adetFiyati = '', String kutuFiyati = '',
      String aciklama = '', int birimKey1 = 0, int birimKey2 = 0}) async {
    try {
      final db = await dbHelper.database;

      // Check if item already exists in cart
      final existing = await db.query(
        'cart_items',
        where: 'stok_kodu = ?',
        whereArgs: [stokKodu],
      );

      if (existing.isNotEmpty) {
        // Update quantity if item exists
        final currentQuantity = existing.first['miktar'] as int;
        await db.update(
          'cart_items',
          {'miktar': currentQuantity + miktar},
          where: 'stok_kodu = ?',
          whereArgs: [stokKodu],
        );
      } else {
        // Insert new item
        await db.insert('cart_items', {
          'stok_kodu': stokKodu,
          'urun_adi': urunAdi,
          'miktar': miktar,
          'birim_fiyat': birimFiyat,
          'vat': vat,
          'birim_tipi': birimTipi,
          'durum': 1,
          'urun_barcode': urunBarcode,
          'iskonto': iskonto,
          'imsrc': imsrc,
          'adet_fiyati': adetFiyati,
          'kutu_fiyati': kutuFiyati,
          'aciklama': aciklama,
          'birim_key1': birimKey1,
          'birim_key2': birimKey2,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  @override
  Future<void> removeItemFromCart(String stokKodu) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'cart_items',
        where: 'stok_kodu = ?',
        whereArgs: [stokKodu],
      );
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  @override
  Future<void> updateItemQuantity(String stokKodu, int newQuantity) async {
    try {
      final db = await dbHelper.database;
      if (newQuantity <= 0) {
        await removeItemFromCart(stokKodu);
      } else {
        await db.update(
          'cart_items',
          {'miktar': newQuantity},
          where: 'stok_kodu = ?',
          whereArgs: [stokKodu],
        );
      }
    } catch (e) {
      throw Exception('Failed to update item quantity: $e');
    }
  }

  @override
  Future<void> updateItemDiscount(String stokKodu, int discount) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'cart_items',
        {'iskonto': discount},
        where: 'stok_kodu = ?',
        whereArgs: [stokKodu],
      );
    } catch (e) {
      throw Exception('Failed to update item discount: $e');
    }
  }

  @override
  Future<void> updateItemPrice(String stokKodu, double newPrice) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'cart_items',
        {'birim_fiyat': newPrice},
        where: 'stok_kodu = ?',
        whereArgs: [stokKodu],
      );
    } catch (e) {
      throw Exception('Failed to update item price: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'cart_items',
        orderBy: 'created_at ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get cart items: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCartItemByCode(String stokKodu) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'cart_items',
        where: 'stok_kodu = ?',
        whereArgs: [stokKodu],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw Exception('Failed to get cart item: $e');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      final db = await dbHelper.database;
      await db.delete('cart_items');
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  @override
  Future<double> getCartSubtotal() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(birim_fiyat * miktar) as subtotal
        FROM cart_items
      ''');
      return (result.first['subtotal'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get cart subtotal: $e');
    }
  }

  @override
  Future<double> getCartTotal() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(
          (birim_fiyat * miktar) * (1 - iskonto / 100.0) * (1 + vat / 100.0)
        ) as total
        FROM cart_items
      ''');
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get cart total: $e');
    }
  }

  @override
  Future<double> getCartVATAmount() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(
          (birim_fiyat * miktar) * (1 - iskonto / 100.0) * (vat / 100.0)
        ) as vat_amount
        FROM cart_items
      ''');
      return (result.first['vat_amount'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get cart VAT amount: $e');
    }
  }

  @override
  Future<double> getCartDiscountAmount() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(
          (birim_fiyat * miktar) * (iskonto / 100.0)
        ) as discount_amount
        FROM cart_items
      ''');
      return (result.first['discount_amount'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get cart discount amount: $e');
    }
  }

  @override
  Future<int> getCartItemsCount() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM cart_items');
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get cart items count: $e');
    }
  }

  @override
  Future<void> saveCart(String cartName, String? customerCode) async {
    try {
      final db = await dbHelper.database;
      final cartItems = await getCartItems();

      if (cartItems.isEmpty) {
        throw Exception('Cannot save empty cart');
      }

      // Save cart header
      await db.insert('saved_carts', {
        'cart_name': cartName,
        'customer_code': customerCode,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Save cart items
      for (final item in cartItems) {
        await db.insert('saved_cart_items', {
          'cart_name': cartName,
          ...item,
        });
      }
    } catch (e) {
      throw Exception('Failed to save cart: $e');
    }
  }

  @override
  Future<void> loadSavedCart(String cartName) async {
    try {
      final db = await dbHelper.database;

      // Clear current cart
      await clearCart();

      // Load saved cart items
      final savedItems = await db.query(
        'saved_cart_items',
        where: 'cart_name = ?',
        whereArgs: [cartName],
      );

      for (final item in savedItems) {
        await db.insert('cart_items', {
          'stok_kodu': item['stok_kodu'],
          'urun_adi': item['urun_adi'],
          'miktar': item['miktar'],
          'birim_fiyat': item['birim_fiyat'],
          'vat': item['vat'],
          'birim_tipi': item['birim_tipi'],
          'durum': item['durum'],
          'urun_barcode': item['urun_barcode'],
          'iskonto': item['iskonto'],
          'imsrc': item['imsrc'],
          'adet_fiyati': item['adet_fiyati'],
          'kutu_fiyati': item['kutu_fiyati'],
          'aciklama': item['aciklama'],
          'birim_key1': item['birim_key1'],
          'birim_key2': item['birim_key2'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to load saved cart: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSavedCarts() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'saved_carts',
        orderBy: 'created_at DESC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get saved carts: $e');
    }
  }

  @override
  Future<void> deleteSavedCart(String cartName) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'saved_carts',
        where: 'cart_name = ?',
        whereArgs: [cartName],
      );
      await db.delete(
        'saved_cart_items',
        where: 'cart_name = ?',
        whereArgs: [cartName],
      );
    } catch (e) {
      throw Exception('Failed to delete saved cart: $e');
    }
  }

  @override
  Future<bool> isItemInCart(String stokKodu) async {
    try {
      final item = await getCartItemByCode(stokKodu);
      return item != null;
    } catch (e) {
      throw Exception('Failed to check item in cart: $e');
    }
  }

  @override
  Future<int> getItemQuantity(String stokKodu) async {
    try {
      final item = await getCartItemByCode(stokKodu);
      return item?['miktar'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get item quantity: $e');
    }
  }

  @override
  Future<void> mergeCart(List<Map<String, dynamic>> otherCartItems) async {
    try {
      for (final item in otherCartItems) {
        await addItemToCart(
          item['stok_kodu'],
          item['urun_adi'],
          item['birim_fiyat'],
          item['urun_barcode'],
          item['vat'],
          miktar: item['miktar'],
          birimTipi: item['birim_tipi'] ?? 'Unit',
          iskonto: item['iskonto'] ?? 0,
          imsrc: item['imsrc'],
          adetFiyati: item['adet_fiyati'] ?? '',
          kutuFiyati: item['kutu_fiyati'] ?? '',
          aciklama: item['aciklama'] ?? '',
          birimKey1: item['birim_key1'] ?? 0,
          birimKey2: item['birim_key2'] ?? 0,
        );
      }
    } catch (e) {
      throw Exception('Failed to merge cart: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCartSummary() async {
    try {
      final itemsCount = await getCartItemsCount();
      final subtotal = await getCartSubtotal();
      final total = await getCartTotal();
      final vatAmount = await getCartVATAmount();
      final discountAmount = await getCartDiscountAmount();

      return {
        'items_count': itemsCount,
        'subtotal': subtotal,
        'total': total,
        'vat_amount': vatAmount,
        'discount_amount': discountAmount,
        'net_amount': subtotal - discountAmount,
      };
    } catch (e) {
      throw Exception('Failed to get cart summary: $e');
    }
  }

  @override
  Future<void> applyBulkDiscount(double discountPercentage) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'cart_items',
        {'iskonto': discountPercentage},
      );
    } catch (e) {
      throw Exception('Failed to apply bulk discount: $e');
    }
  }

  @override
  Future<void> setCartCustomer(String? customerCode) async {
    try {
      final db = await dbHelper.database;

      // Check if cart_session exists, create if not
      final sessionExists = await db.query('cart_session', limit: 1);
      if (sessionExists.isEmpty) {
        await db.insert('cart_session', {
          'customer_code': customerCode,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await db.update(
          'cart_session',
          {
            'customer_code': customerCode,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to set cart customer: $e');
    }
  }

  @override
  Future<String?> getCartCustomer() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query('cart_session', limit: 1);
      return results.isNotEmpty ? results.first['customer_code'] as String? : null;
    } catch (e) {
      throw Exception('Failed to get cart customer: $e');
    }
  }

  @override
  Future<bool> validateCart() async {
    try {
      final itemsCount = await getCartItemsCount();
      if (itemsCount == 0) {
        return false;
      }

      final items = await getCartItems();
      for (final item in items) {
        if (item['miktar'] <= 0) {
          return false;
        }
        if (item['birim_fiyat'] <= 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to validate cart: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCartHistory() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'cart_history',
        orderBy: 'created_at DESC',
        limit: 50,
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get cart history: $e');
    }
  }
}