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
}