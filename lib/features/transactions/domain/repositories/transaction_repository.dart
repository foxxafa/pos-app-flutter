// lib/features/transactions/domain/repositories/transaction_repository.dart
import 'package:pos_app/features/transactions/domain/entities/transaction_model.dart';
import 'package:pos_app/features/transactions/domain/entities/cheque_model.dart';

abstract class TransactionRepository {
  /// Create new collection transaction
  Future<TahsilatModel> createTransaction(
    double tutar,
    String aciklama,
    String carikod,
    String username, {
    String? fisno,
  });

  /// Get all transactions
  Future<List<TahsilatModel>> getAllTransactions();

  /// Get transaction by ID/fisno
  Future<TahsilatModel?> getTransactionById(String fisno);

  /// Get transactions by customer code
  Future<List<TahsilatModel>> getTransactionsByCustomer(String carikod);

  /// Get transactions by user
  Future<List<TahsilatModel>> getTransactionsByUser(String username);

  /// Get transactions by date range
  Future<List<TahsilatModel>> getTransactionsByDateRange(DateTime startDate, DateTime endDate);

  /// Update transaction
  Future<void> updateTransaction(TahsilatModel transaction);

  /// Delete transaction
  Future<void> deleteTransaction(String fisno);

  /// Get total collection amount by date
  Future<double> getTotalCollectionByDate(DateTime date);

  /// Get total collection amount by customer
  Future<double> getTotalCollectionByCustomer(String carikod);

  /// Get total collection amount by user
  Future<double> getTotalCollectionByUser(String username);

  /// Search transactions by customer code or description
  Future<List<TahsilatModel>> searchTransactions(String query);

  /// Get today's transactions
  Future<List<TahsilatModel>> getTodaysTransactions();

  /// Get transactions summary for a specific date
  Future<Map<String, dynamic>> getTransactionsSummary(DateTime date);

  /// Sync transactions with server
  Future<void> syncTransactions();

  /// Upload pending transactions to server
  Future<void> uploadPendingTransactions();

  /// Mark transaction as synced
  Future<void> markTransactionAsSynced(String fisno);

  /// Get pending transactions (not synced)
  Future<List<TahsilatModel>> getPendingTransactions();

  /// Get transactions count
  Future<int> getTransactionsCount();

  /// Get recent transactions
  Future<List<TahsilatModel>> getRecentTransactions({int limit = 10});

  /// Create cheque record
  Future<void> createCheque(
    String customerCode,
    String chequeNumber,
    double amount,
    DateTime dueDate, {
    String bankName = '',
    String accountNumber = '',
    String description = '',
  });

  /// Get all cheques
  Future<List<dynamic>> getAllCheques();

  /// Get cheques by customer
  Future<List<dynamic>> getChequesByCustomer(String customerCode);

  /// Get cheques by status
  Future<List<dynamic>> getChequesByStatus(String status);

  /// Update cheque status
  Future<void> updateChequeStatus(String chequeNumber, String status);

  /// Get overdue cheques
  Future<List<dynamic>> getOverdueCheques();

  /// Get cheques due today
  Future<List<dynamic>> getChequesDueToday();

  /// Get cheques summary
  Future<Map<String, dynamic>> getChequesSummary();

  /// Process cheque payment
  Future<void> processChequePayment(String chequeNumber, double amount);

  /// Cancel cheque
  Future<void> cancelCheque(String chequeNumber, String reason);

  /// Get transaction history for customer
  Future<List<Map<String, dynamic>>> getCustomerTransactionHistory(String carikod);

  /// Get daily collection report
  Future<Map<String, dynamic>> getDailyCollectionReport(DateTime date);

  /// Get monthly collection report
  Future<Map<String, dynamic>> getMonthlyCollectionReport(int year, int month);

  /// Export transactions to CSV format
  Future<String> exportTransactionsToCSV(DateTime startDate, DateTime endDate);

  /// Get outstanding balances by customer
  Future<List<Map<String, dynamic>>> getOutstandingBalances();

  /// Calculate customer balance after transaction
  Future<double> calculateCustomerBalanceAfterTransaction(String carikod, double transactionAmount);

  /// Send tahsilat (collection) to server
  /// Returns true if successful, false otherwise
  Future<bool> sendTahsilat({
    required TahsilatModel model,
    required String method,
    required String apiKey,
    ChequeModel? chequeModel,
  });

  /// Send cheque tahsilat to server
  Future<bool> sendChequeTahsilat({
    required ChequeModel chequeModel,
    required String apiKey,
  });
}