// lib/features/orders/data/repositories/order_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/orders/domain/entities/order_model.dart';
import 'package:pos_app/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  OrderRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  @override
  Future<FisModel> createOrder(
    String musteriId,
    double toplamtutar,
    String odemeTuru,
    double nakitOdeme,
    double kartOdeme,
    List<Map<String, dynamic>> orderItems, {
    String deliveryDate = '',
    String comment = '',
  }) async {
    try {
      final fisNo = _generateOrderNumber();
      final fistarihi = DateTime.now().toIso8601String();

      final order = FisModel(
        fisNo: fisNo,
        fistarihi: fistarihi,
        musteriId: musteriId,
        toplamtutar: toplamtutar,
        odemeTuru: odemeTuru,
        nakitOdeme: nakitOdeme,
        kartOdeme: kartOdeme,
        status: 'pending',
        deliveryDate: deliveryDate,
        comment: comment,
      );

      // Save to local database
      await _saveOrderToDatabase(order, orderItems);

      // Try to sync with server if online
      if (await networkInfo.isConnected) {
        try {
          await _syncOrderToServer(order, orderItems);
        } catch (e) {
          // Order saved locally, sync will be attempted later
        }
      }

      return order;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(6);
    return 'ORD$timestamp';
  }

  Future<void> _saveOrderToDatabase(FisModel order, List<Map<String, dynamic>> orderItems) async {
    final db = await dbHelper.database;

    // Save order header
    await db.insert('orders', {
      'fis_no': order.fisNo,
      'fis_tarihi': order.fistarihi,
      'musteri_id': order.musteriId,
      'toplam_tutar': order.toplamtutar,
      'odeme_turu': order.odemeTuru,
      'nakit_odeme': order.nakitOdeme,
      'kart_odeme': order.kartOdeme,
      'status': order.status,
      'delivery_date': order.deliveryDate,
      'comment': order.comment,
      'is_synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Save order items
    for (final item in orderItems) {
      await db.insert('order_items', {
        'fis_no': order.fisNo,
        'stok_kodu': item['stok_kodu'],
        'urun_adi': item['urun_adi'],
        'miktar': item['miktar'],
        'birim_fiyat': item['birim_fiyat'],
        'toplam_fiyat': item['birim_fiyat'] * item['miktar'],
        'vat': item['vat'] ?? 0,
        'iskonto': item['iskonto'] ?? 0,
        'birim_tipi': item['birim_tipi'] ?? 'Unit',
        'urun_barcode': item['urun_barcode'],
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _syncOrderToServer(FisModel order, List<Map<String, dynamic>> orderItems) async {
    try {
      final response = await dio.post(
        ApiConfig.orders,
        data: {
          'order': order.toJson(),
          'items': orderItems,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await markOrderAsSynced(order.fisNo);
      }
    } catch (e) {
      throw Exception('Failed to sync order to server: $e');
    }
  }

  @override
  Future<List<FisModel>> getAllOrders() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToFisModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all orders: $e');
    }
  }

  @override
  Future<FisModel?> getOrderById(String fisNo) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );

      if (results.isNotEmpty) {
        return _mapToFisModel(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order by ID: $e');
    }
  }

  @override
  Future<List<FisModel>> getOrdersByCustomer(String musteriId) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        where: 'musteri_id = ?',
        whereArgs: [musteriId],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToFisModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get orders by customer: $e');
    }
  }

  @override
  Future<List<FisModel>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToFisModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get orders by date range: $e');
    }
  }

  @override
  Future<List<FisModel>> getOrdersByStatus(String status) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToFisModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String fisNo, String newStatus) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'orders',
        {
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );

      // Try to sync with server if online
      if (await networkInfo.isConnected) {
        try {
          await dio.put(
            '${ApiConfig.orders}/$fisNo/status',
            data: {'status': newStatus},
          );
        } catch (e) {
          // Ignore server sync errors for status updates
        }
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  @override
  Future<void> updateOrderDeliveryDate(String fisNo, String deliveryDate) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'orders',
        {
          'delivery_date': deliveryDate,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );
    } catch (e) {
      throw Exception('Failed to update order delivery date: $e');
    }
  }

  @override
  Future<void> updateOrderComment(String fisNo, String comment) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'orders',
        {
          'comment': comment,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );
    } catch (e) {
      throw Exception('Failed to update order comment: $e');
    }
  }

  @override
  Future<void> deleteOrder(String fisNo) async {
    try {
      final db = await dbHelper.database;

      // Delete order items first
      await db.delete(
        'order_items',
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );

      // Delete order
      await db.delete(
        'orders',
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );

      // Try to sync deletion with server if online
      if (await networkInfo.isConnected) {
        try {
          await dio.delete('${ApiConfig.orders}/$fisNo');
        } catch (e) {
          // Ignore server sync errors for deletions
        }
      }
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderItems(String fisNo) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'order_items',
        where: 'fis_no = ?',
        whereArgs: [fisNo],
        orderBy: 'created_at ASC',
      );

      return results;
    } catch (e) {
      throw Exception('Failed to get order items: $e');
    }
  }

  @override
  Future<void> addOrderItem(String fisNo, Map<String, dynamic> orderItem) async {
    try {
      final db = await dbHelper.database;
      await db.insert('order_items', {
        'fis_no': fisNo,
        ...orderItem,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update order total
      await _recalculateOrderTotal(fisNo);
    } catch (e) {
      throw Exception('Failed to add order item: $e');
    }
  }

  @override
  Future<void> updateOrderItem(String fisNo, String stokKodu, Map<String, dynamic> updates) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'order_items',
        {
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fis_no = ? AND stok_kodu = ?',
        whereArgs: [fisNo, stokKodu],
      );

      // Update order total
      await _recalculateOrderTotal(fisNo);
    } catch (e) {
      throw Exception('Failed to update order item: $e');
    }
  }

  @override
  Future<void> removeOrderItem(String fisNo, String stokKodu) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'order_items',
        where: 'fis_no = ? AND stok_kodu = ?',
        whereArgs: [fisNo, stokKodu],
      );

      // Update order total
      await _recalculateOrderTotal(fisNo);
    } catch (e) {
      throw Exception('Failed to remove order item: $e');
    }
  }

  Future<void> _recalculateOrderTotal(String fisNo) async {
    try {
      final total = await calculateOrderTotal(fisNo);
      final db = await dbHelper.database;
      await db.update(
        'orders',
        {
          'toplam_tutar': total,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );
    } catch (e) {
      throw Exception('Failed to recalculate order total: $e');
    }
  }

  @override
  Future<double> calculateOrderTotal(String fisNo) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(
          (birim_fiyat * miktar) * (1 - iskonto / 100.0) * (1 + vat / 100.0)
        ) as total
        FROM order_items
        WHERE fis_no = ?
      ''', [fisNo]);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to calculate order total: $e');
    }
  }

  @override
  Future<void> syncOrders() async {
    if (await networkInfo.isConnected) {
      try {
        // Download orders from server
        final response = await dio.get(ApiConfig.orders);

        if (response.statusCode == 200) {
          final List<dynamic> ordersData = response.data['orders'] ?? response.data;

          final db = await dbHelper.database;

          for (final orderData in ordersData) {
            final existingOrder = await db.query(
              'orders',
              where: 'fis_no = ?',
              whereArgs: [orderData['fis_no']],
            );

            if (existingOrder.isEmpty) {
              // Insert new order
              await db.insert('orders', {
                'fis_no': orderData['fis_no'],
                'fis_tarihi': orderData['fis_tarihi'],
                'musteri_id': orderData['musteri_id'],
                'toplam_tutar': orderData['toplam_tutar'],
                'odeme_turu': orderData['odeme_turu'],
                'nakit_odeme': orderData['nakit_odeme'],
                'kart_odeme': orderData['kart_odeme'],
                'status': orderData['status'],
                'delivery_date': orderData['delivery_date'] ?? '',
                'comment': orderData['comment'] ?? '',
                'is_synced': 1,
                'created_at': orderData['created_at'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // Upload pending orders
        await uploadPendingOrders();
      } catch (e) {
        throw Exception('Orders sync failed: $e');
      }
    } else {
      throw Exception('No internet connection for sync');
    }
  }

  @override
  Future<void> uploadPendingOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final pendingOrders = await getPendingOrders();

        for (final order in pendingOrders) {
          try {
            final orderItems = await getOrderItems(order.fisNo);
            await _syncOrderToServer(order, orderItems);
          } catch (e) {
            // Continue with next order if one fails
            continue;
          }
        }
      } catch (e) {
        throw Exception('Failed to upload pending orders: $e');
      }
    }
  }

  @override
  Future<void> markOrderAsSynced(String fisNo) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'orders',
        {'is_synced': 1},
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );
    } catch (e) {
      throw Exception('Failed to mark order as synced: $e');
    }
  }

  @override
  Future<List<FisModel>> getPendingOrders() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        where: 'is_synced = 0',
        orderBy: 'created_at ASC',
      );

      return results.map((map) => _mapToFisModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get pending orders: $e');
    }
  }

  @override
  Future<int> getOrdersCount() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get orders count: $e');
    }
  }

  @override
  Future<List<FisModel>> getTodaysOrders() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await getOrdersByDateRange(startOfDay, endOfDay);
    } catch (e) {
      throw Exception('Failed to get today\'s orders: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getOrdersSummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as orders_count,
          SUM(toplam_tutar) as total_amount,
          SUM(nakit_odeme) as cash_amount,
          SUM(kart_odeme) as card_amount
        FROM orders
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      final row = result.first;
      return {
        'orders_count': row['orders_count'] ?? 0,
        'total_amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
        'cash_amount': (row['cash_amount'] as num?)?.toDouble() ?? 0.0,
        'card_amount': (row['card_amount'] as num?)?.toDouble() ?? 0.0,
        'date': date.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get orders summary: $e');
    }
  }

  @override
  Future<List<FisModel>> searchOrders(String query) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'orders',
        where: 'fis_no LIKE ? OR musteri_id LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToFisModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderPaymentDetails(String fisNo) async {
    try {
      final order = await getOrderById(fisNo);
      if (order == null) {
        throw Exception('Order not found');
      }

      return {
        'fis_no': order.fisNo,
        'toplam_tutar': order.toplamtutar,
        'odeme_turu': order.odemeTuru,
        'nakit_odeme': order.nakitOdeme,
        'kart_odeme': order.kartOdeme,
      };
    } catch (e) {
      throw Exception('Failed to get order payment details: $e');
    }
  }

  @override
  Future<void> updateOrderPayment(String fisNo, double nakitOdeme, double kartOdeme, String odemeTuru) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'orders',
        {
          'nakit_odeme': nakitOdeme,
          'kart_odeme': kartOdeme,
          'odeme_turu': odemeTuru,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fis_no = ?',
        whereArgs: [fisNo],
      );
    } catch (e) {
      throw Exception('Failed to update order payment: $e');
    }
  }

  @override
  Future<void> cancelOrder(String fisNo) async {
    await updateOrderStatus(fisNo, 'cancelled');
  }

  @override
  Future<void> restoreOrder(String fisNo) async {
    await updateOrderStatus(fisNo, 'pending');
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String fisNo) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'order_history',
        where: 'fis_no = ?',
        whereArgs: [fisNo],
        orderBy: 'created_at DESC',
      );

      return results;
    } catch (e) {
      throw Exception('Failed to get order history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> generateOrderReceipt(String fisNo) async {
    try {
      final order = await getOrderById(fisNo);
      final orderItems = await getOrderItems(fisNo);

      if (order == null) {
        throw Exception('Order not found');
      }

      return {
        'order': {
          'fis_no': order.fisNo,
          'fis_tarihi': order.fistarihi,
          'musteri_id': order.musteriId,
          'toplam_tutar': order.toplamtutar,
          'odeme_turu': order.odemeTuru,
          'nakit_odeme': order.nakitOdeme,
          'kart_odeme': order.kartOdeme,
          'status': order.status,
          'delivery_date': order.deliveryDate,
          'comment': order.comment,
        },
        'items': orderItems,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to generate order receipt: $e');
    }
  }

  FisModel _mapToFisModel(Map<String, dynamic> map) {
    return FisModel(
      fisNo: map['fis_no'] as String,
      fistarihi: map['fis_tarihi'] as String,
      musteriId: map['musteri_id'] as String,
      toplamtutar: (map['toplam_tutar'] as num).toDouble(),
      odemeTuru: map['odeme_turu'] as String,
      nakitOdeme: (map['nakit_odeme'] as num).toDouble(),
      kartOdeme: (map['kart_odeme'] as num).toDouble(),
      status: map['status'] as String,
      deliveryDate: map['delivery_date'] as String? ?? '',
      comment: map['comment'] as String? ?? '',
    );
  }

  // ============= Order Submission (for OrderController) =============

  @override
  Future<bool> submitOrder({
    required FisModel fisModel,
    required List<dynamic> orderItems,
    required String bearerToken,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        throw Exception('No internet connection');
      }

      // Clean stokKodu and urunAdi from FREE markers
      final cleanedItems = orderItems.map((item) {
        final itemJson = (item as dynamic).toJson() as Map<String, dynamic>;

        final cleanedStokKodu = (itemJson['StokKodu'] as String)
            .replaceAll('_(FREEUnit)', '')
            .replaceAll('_(FREEBox)', '')
            .replaceAll(' (FREEUnit)', '')
            .replaceAll(' (FREEBox)', '')
            .trim();

        final cleanedUrunAdi = (itemJson['UrunAdi'] as String)
            .replaceAll('_(FREEUnit)', '')
            .replaceAll('_(FREEBox)', '')
            .replaceAll(' (FREEUnit)', '')
            .replaceAll(' (FREEBox)', '')
            .trim();

        final cleanedJson = Map<String, dynamic>.from(itemJson);
        cleanedJson['StokKodu'] = cleanedStokKodu;
        cleanedJson['UrunAdi'] = cleanedUrunAdi;
        return cleanedJson;
      }).toList();

      final response = await dio.post(
        ApiConfig.satisUrl,
        data: {
          "fis": fisModel.toJson(),
          "satirlar": cleanedItems,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearerToken',
          },
        ),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 200) {
        try {
          // Handle double JSON response (rowhub API quirk)
          String responseBody = response.data.toString();
          final parts = responseBody.split('}{');
          String lastJson;

          if (parts.length > 1) {
            lastJson = '{${parts.last}';
          } else {
            lastJson = responseBody;
          }

          final jsonResponse = response.data as Map<String, dynamic>;

          if (jsonResponse.containsKey('status')) {
            print("Status: ${jsonResponse['status']}");
            return true;
          } else {
            print("Status alanı bulunamadı. Yanıt: $lastJson");
            return false;
          }
        } catch (e) {
          print("Yanıt JSON olarak çözümlenemedi: ${response.data}");
          return false;
        }
      } else {
        print("Hata: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      print("submitOrder hatası: $e");
      return false;
    }
  }
}