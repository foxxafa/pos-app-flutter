// lib/features/customer/data/repositories/customer_repository_impl.dart
import 'package:dio/dio.dart';
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
      final results = await db.query('customers', orderBy: 'name ASC');

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
        'customers',
        where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
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
        'customers',
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
        'customers',
        where: 'phone = ?',
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
      await db.insert('customers', customer.toMap());
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
        'customers',
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
        'customers',
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
          await db.delete('customers');

          for (final customer in customers) {
            await db.insert('customers', customer.toMap());
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
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
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
        'customers',
        where: 'phone = ?',
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
        'customers',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (results.isNotEmpty) {
        return (results.first['balance'] as num?)?.toDouble() ?? 0.0;
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
        'customers',
        {'balance': balance},
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
      final results = await db.query(
        'customers',
        where: 'balance > 0',
        orderBy: 'balance DESC',
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
        'customers',
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
        'transactions',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );

      return results;
    } catch (e) {
      throw Exception('Failed to get customer transactions: $e');
    }
  }
}