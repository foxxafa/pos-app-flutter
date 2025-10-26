// lib/features/customer/data/repositories/customer_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/customer/domain/entities/customer_model.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  CustomerRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query('CustomerBalance', orderBy: 'unvan ASC');

      return results.map((map) => CustomerModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get customers: $e');
    }
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        where: 'unvan LIKE ? OR telefon LIKE ? OR email LIKE ? OR kod LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: 'unvan ASC',
      );

      return results.map((map) => CustomerModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  @override
  Future<CustomerModel?> getCustomerById(int id) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        return CustomerModel.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer by ID: $e');
    }
  }

  @override
  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        where: 'telefon = ?',
        whereArgs: [phone],
      );

      if (results.isNotEmpty) {
        return CustomerModel.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer by phone: $e');
    }
  }

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      if (await networkInfo.isConnected) {
        await _addCustomerOnline(customer);
      } else {
        await _addCustomerOffline(customer);
      }
    } catch (e) {
      // Fallback to offline storage
      await _addCustomerOffline(customer);
    }
  }

  Future<void> _addCustomerOnline(CustomerModel customer) async {
    try {
      final response = await dio.post(
        ApiConfig.customers,
        data: customer.toMap(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save to local database as well
        final customerWithId = customer.copyWith(
          id: response.data['id'] ?? customer.id,
        );
        await _addCustomerOffline(customerWithId);
      } else {
        throw Exception('Failed to add customer online');
      }
    } catch (e) {
      throw Exception('Online customer addition failed: $e');
    }
  }

  Future<void> _addCustomerOffline(CustomerModel customer) async {
    try {
      final db = await dbHelper.database;
      await db.insert('CustomerBalance', customer.toMap());
    } catch (e) {
      throw Exception('Failed to add customer offline: $e');
    }
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      if (await networkInfo.isConnected) {
        await _updateCustomerOnline(customer);
      } else {
        await _updateCustomerOffline(customer);
      }
    } catch (e) {
      // Fallback to offline update
      await _updateCustomerOffline(customer);
    }
  }

  Future<void> _updateCustomerOnline(CustomerModel customer) async {
    try {
      final response = await dio.put(
        '${ApiConfig.customers}/${customer.id}',
        data: customer.toMap(),
      );

      if (response.statusCode == 200) {
        // Update local database as well
        await _updateCustomerOffline(customer);
      } else {
        throw Exception('Failed to update customer online');
      }
    } catch (e) {
      throw Exception('Online customer update failed: $e');
    }
  }

  Future<void> _updateCustomerOffline(CustomerModel customer) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'CustomerBalance',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
    } catch (e) {
      throw Exception('Failed to update customer offline: $e');
    }
  }

  @override
  Future<void> deleteCustomer(int customerId) async {
    try {
      if (await networkInfo.isConnected) {
        await _deleteCustomerOnline(customerId);
      } else {
        await _deleteCustomerOffline(customerId);
      }
    } catch (e) {
      // Fallback to offline deletion
      await _deleteCustomerOffline(customerId);
    }
  }

  Future<void> _deleteCustomerOnline(int customerId) async {
    try {
      final response = await dio.delete('${ApiConfig.customers}/$customerId');

      if (response.statusCode == 200) {
        // Delete from local database as well
        await _deleteCustomerOffline(customerId);
      } else {
        throw Exception('Failed to delete customer online');
      }
    } catch (e) {
      throw Exception('Online customer deletion failed: $e');
    }
  }

  Future<void> _deleteCustomerOffline(int customerId) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'CustomerBalance',
        where: 'id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      throw Exception('Failed to delete customer offline: $e');
    }
  }

  @override
  Future<void> syncCustomers() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await dio.get(ApiConfig.customers);

        if (response.statusCode == 200) {
          final List<dynamic> customersData = response.data['customers'] ?? response.data;
          final customers = customersData
              .map((data) => CustomerModel.fromMap(data))
              .toList();

          // Clear and insert all customers
          final db = await dbHelper.database;
          await db.delete('CustomerBalance');

          for (final customer in customers) {
            await db.insert('CustomerBalance', customer.toMap());
          }
        }
      } catch (e) {
        throw Exception('Customer sync failed: $e');
      }
    } else {
      throw Exception('No internet connection for sync');
    }
  }

  @override
  Future<int> getCustomersCount() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM CustomerBalance');
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get customers count: $e');
    }
  }

  @override
  Future<bool> customerExists(String phone) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        where: 'telefon = ?',
        whereArgs: [phone],
      );
      return results.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check customer existence: $e');
    }
  }

  @override
  Future<double> getCustomerBalance(int customerId) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        columns: ['bakiye'],
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (results.isNotEmpty) {
        final bakiyeStr = results.first['bakiye'] as String?;
        return double.tryParse(bakiyeStr ?? '0') ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to get customer balance: $e');
    }
  }

  @override
  Future<void> updateCustomerBalance(int customerId, double balance) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'CustomerBalance',
        {'bakiye': balance.toString()},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      // Also try to sync with server if online
      if (await networkInfo.isConnected) {
        try {
          await dio.put(
            '${ApiConfig.customers}/$customerId/balance',
            data: {'balance': balance},
          );
        } catch (e) {
          // Ignore online update errors, local update succeeded
        }
      }
    } catch (e) {
      throw Exception('Failed to update customer balance: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getCustomersWithBalance() async {
    try {
      final db = await dbHelper.database;
      final results = await db.rawQuery(
        'SELECT * FROM CustomerBalance WHERE CAST(bakiye AS REAL) > 0 ORDER BY CAST(bakiye AS REAL) DESC',
      );

      return results.map((map) => CustomerModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get customers with balance: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getRecentCustomers({int limit = 10}) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        orderBy: 'last_used DESC',
        limit: limit,
      );

      return results.map((map) => CustomerModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get recent customers: $e');
    }
  }

  @override
  Future<List<dynamic>> getCustomerTransactions(int customerId) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'Refunds',
        where: 'musteriId = ?',
        whereArgs: [customerId.toString()],
        orderBy: 'fisTarihi DESC',
      );

      return results;
    } catch (e) {
      throw Exception('Failed to get customer transactions: $e');
    }
  }

  // ============= CustomerBalance Methods (for CustomerBalanceController) =============

  @override
  Future<String> getCustomerBalanceByName(String customerName) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        'CustomerBalance',
        columns: ['bakiye'],
        where: 'LOWER(unvan) = ?',
        whereArgs: [customerName.toLowerCase()],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result[0]['bakiye']?.toString() ?? '0.00';
      } else {
        return '0.00';
      }
    } catch (e) {
      throw Exception('Failed to get customer balance by name: $e');
    }
  }

  @override
  Future<List<dynamic>> getAllCustomerBalances() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query('CustomerBalance');
      return results;
    } catch (e) {
      throw Exception('Failed to get all customer balances: $e');
    }
  }

  @override
  Future<dynamic> getCustomerByUnvan(String unvan) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'CustomerBalance',
        where: 'unvan = ?',
        whereArgs: [unvan],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer by unvan: $e');
    }
  }

  @override
  Future<void> fetchAndStoreCustomers() async {
    if (await networkInfo.isConnected) {
      try {
        // Get API key from database
        final db = await dbHelper.database;
        final result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

        if (result.isEmpty) {
          throw Exception('No API Key found');
        }

        final savedApiKey = result.first['apikey'] as String;

        // STEP 1: Get total customer count
        print('🔄 Müşteri sayısı getiriliyor...');
        final countResponse = await dio.get(
          ApiConfig.customerCountsUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $savedApiKey',
              'Accept': 'application/json',
            },
          ),
        );

        if (countResponse.statusCode != 200 || countResponse.data['status'] != 1) {
          throw Exception('Müşteri sayısı alınamadı');
        }

        final customerCount = countResponse.data['customer_count'] as int;
        print('📊 Toplam müşteri sayısı: $customerCount');

        // STEP 2: Download customers page by page
        const pageSize = 5000;
        int page = 1;
        final allCustomers = <Map<String, dynamic>>[];

        while (true) {
          print('📥 Sayfa $page indiriliyor...');

          final response = await dio.get(
            ApiConfig.musteriListesiUrl,
            queryParameters: {
              'page': page,
              'limit': pageSize,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $savedApiKey',
              },
            ),
          );

          if (response.statusCode == 200) {
            final data = response.data;

            if (data['status'] == 1) {
              final List<dynamic> customersData = data['customers'] ?? [];

              // Break if no more data
              if (customersData.isEmpty) {
                print('✅ Tüm sayfalar indirildi');
                break;
              }

              allCustomers.addAll(customersData.cast<Map<String, dynamic>>());

              print('📥 Sayfa $page: ${customersData.length} müşteri (Toplam: ${allCustomers.length}/$customerCount)');
              page++;
            } else {
              throw Exception('API returned status != 1');
            }
          } else {
            throw Exception('Veri alınamadı: ${response.statusCode}');
          }
        }

        // STEP 3: Clear and insert all customers
        print('💾 Müşteriler veritabanına kaydediliyor...');
        await db.delete('CustomerBalance');

        final batch = db.batch();
        for (var json in allCustomers) {
          batch.insert(
            'CustomerBalance',
            json,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);

        print('✅ ${allCustomers.length} müşteri veritabanına kaydedildi');
      } catch (e) {
        throw Exception('Failed to fetch and store customers: $e');
      }
    } else {
      throw Exception('No internet connection');
    }
  }

  @override
  Future<void> clearAllCustomerBalances() async {
    try {
      final db = await dbHelper.database;
      await db.delete('CustomerBalance');
      print('CustomerBalance tablosu temizlendi.');
    } catch (e) {
      throw Exception('Failed to clear customer balances: $e');
    }
  }

  @override
  Future<List<CustomerModel>?> getNewCustomer(DateTime date) async {
    if (!await networkInfo.isConnected) {
      print('❌ No internet connection');
      return null;
    }

    try {
      final formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
      String formattedDate = formatter.format(date);

      final db = await dbHelper.database;
      List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

      if (result.isEmpty) {
        print('❌ No API Key found.');
        return null;
      }

      String savedApiKey = result.first['apikey'];

      print('🔄 Fetching new customers since: $formattedDate');

      final response = await dio.get(
        '${ApiConfig.indexPhpBase}?r=apimobil/getnewcustomer',
        queryParameters: {'time': formattedDate},
        options: Options(
          headers: {
            'Authorization': 'Bearer $savedApiKey',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Response received: $data');

        if (data['status'] == 1) {
          final List customersJson = data['customers'];
          final customers = customersJson.map((json) => CustomerModel.fromJson(json)).toList();
          return customers;
        }
        return null;
      } else {
        print('❌ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ getNewCustomer error: $e');
      return null;
    }
  }
}