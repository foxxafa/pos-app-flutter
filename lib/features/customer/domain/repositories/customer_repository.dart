// lib/features/customer/domain/repositories/customer_repository.dart
import 'package:pos_app/features/customer/domain/entities/customer_model.dart';

abstract class CustomerRepository {
  /// Get all customers from local database
  Future<List<CustomerModel>> getAllCustomers();

  /// Search customers by name, phone, or email
  Future<List<CustomerModel>> searchCustomers(String query);

  /// Get customer by ID
  Future<CustomerModel?> getCustomerById(int id);

  /// Get customer by phone number
  Future<CustomerModel?> getCustomerByPhone(String phone);

  /// Add new customer
  Future<void> addCustomer(CustomerModel customer);

  /// Update existing customer
  Future<void> updateCustomer(CustomerModel customer);

  /// Delete customer
  Future<void> deleteCustomer(int customerId);

  /// Sync customers from server
  Future<void> syncCustomers();

  /// Get total customers count
  Future<int> getCustomersCount();

  /// Check if customer exists
  Future<bool> customerExists(String phone);

  /// Get customer balance
  Future<double> getCustomerBalance(int customerId);

  /// Update customer balance
  Future<void> updateCustomerBalance(int customerId, double balance);

  /// Get customers with outstanding balance
  Future<List<CustomerModel>> getCustomersWithBalance();

  /// Get recent customers (last used)
  Future<List<CustomerModel>> getRecentCustomers({int limit = 10});

  /// Get customer transaction history
  Future<List<dynamic>> getCustomerTransactions(int customerId);

  // ============= CustomerBalance Methods (for CustomerBalanceController) =============

  /// Get customer balance by name (unvan)
  Future<String> getCustomerBalanceByName(String customerName);

  /// Get all customer balances
  Future<List<dynamic>> getAllCustomerBalances();

  /// Get customer by unvan
  Future<dynamic> getCustomerByUnvan(String unvan);

  /// Fetch and store customers from server
  Future<void> fetchAndStoreCustomers();

  /// Clear all customer balances
  Future<void> clearAllCustomerBalances();

  // ============= Sync Methods =============

  /// Get new customers from server since specific date
  Future<List<CustomerModel>?> getNewCustomer(DateTime date);
}