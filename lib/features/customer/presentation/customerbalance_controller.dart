import 'package:pos_app/features/customer/domain/entities/customer_balance.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';

class CustomerBalanceController {
  final CustomerRepository? _repository;

  CustomerBalanceController({CustomerRepository? repository})
      : _repository = repository;

  // ============= Repository-based methods (if repository available) =============

  Future<String> getCustomerBalanceByName(String customerName) async {
    if (_repository != null) {
      try {
        return await _repository.getCustomerBalanceByName(customerName);
      } catch (e) {
        print('Error getting customer balance: $e');
        return '0.00';
      }
    } else {
      // Fallback: This shouldn't happen in production but kept for safety
      throw Exception('CustomerRepository not provided');
    }
  }

  Future<void> printAllCustomerBalances() async {
    if (_repository != null) {
      try {
        final results = await _repository.getAllCustomerBalances();
        for (var row in results) {
          print('--- Müşteri ---');
          (row as Map).forEach((key, value) {
            print('$key: $value');
          });
          print('----------------\n');
        }
      } catch (e) {
        print('Error printing customer balances: $e');
      }
    }
  }

  Future<void> insertCustomer(CustomerBalanceModel model) async {
    // This method is not commonly used, keeping for backward compatibility
    // In practice, should use repository's methods directly
    throw UnimplementedError(
        'Use CustomerRepository.fetchAndStoreCustomers() instead');
  }

  Future<void> insertCustomers(List<CustomerBalanceModel> customers) async {
    // This method is not commonly used, keeping for backward compatibility
    // In practice, should use repository's methods directly
    throw UnimplementedError(
        'Use CustomerRepository.fetchAndStoreCustomers() instead');
  }

  Future<List<CustomerBalanceModel>> getAllCustomers() async {
    if (_repository != null) {
      try {
        final results = await _repository.getAllCustomerBalances();
        return results
            .map((map) => CustomerBalanceModel.fromJson(map as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error getting all customers: $e');
        return [];
      }
    } else {
      throw Exception('CustomerRepository not provided');
    }
  }

  Future<void> clearAll() async {
    if (_repository != null) {
      try {
        await _repository.clearAllCustomerBalances();
      } catch (e) {
        print('Error clearing customer balances: $e');
      }
    }
  }

  Future<void> fetchAndStoreCustomers() async {
    if (_repository != null) {
      try {
        await _repository.fetchAndStoreCustomers();
      } catch (e) {
        print('Error fetching and storing customers: $e');
        rethrow;
      }
    } else {
      throw Exception('CustomerRepository not provided');
    }
  }

  Future<CustomerBalanceModel?> getCustomerByUnvan(String unvan) async {
    if (_repository != null) {
      try {
        final result = await _repository.getCustomerByUnvan(unvan);
        if (result != null) {
          return CustomerBalanceModel.fromJson(result as Map<String, dynamic>);
        }
        return null;
      } catch (e) {
        print('Error getting customer by unvan: $e');
        return null;
      }
    } else {
      throw Exception('CustomerRepository not provided');
    }
  }

}