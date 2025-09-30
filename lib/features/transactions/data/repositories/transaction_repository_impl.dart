// lib/features/transactions/data/repositories/transaction_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/transactions/domain/entities/transaction_model.dart';
import 'package:pos_app/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  TransactionRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  @override
  Future<TahsilatModel> createTransaction(
    double tutar,
    String aciklama,
    String carikod,
    String username, {
    String? fisno,
  }) async {
    try {
      final generatedFisno = fisno ?? _generateTransactionNumber();

      final transaction = TahsilatModel(
        fisno: generatedFisno,
        tutar: tutar,
        aciklama: aciklama,
        carikod: carikod,
        username: username,
      );

      // Save to local database
      await _saveTransactionToDatabase(transaction);

      // Try to sync with server if online
      if (await networkInfo.isConnected) {
        try {
          await _syncTransactionToServer(transaction);
        } catch (e) {
          // Transaction saved locally, sync will be attempted later
        }
      }

      return transaction;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  String _generateTransactionNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(6);
    return 'TXN$timestamp';
  }

  Future<void> _saveTransactionToDatabase(TahsilatModel transaction) async {
    final db = await dbHelper.database;
    await db.insert('transactions', {
      'fisno': transaction.fisno,
      'tutar': transaction.tutar,
      'aciklama': transaction.aciklama,
      'carikod': transaction.carikod,
      'username': transaction.username,
      'is_synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _syncTransactionToServer(TahsilatModel transaction) async {
    try {
      final response = await dio.post(
        ApiConfig.transactions,
        data: transaction.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await markTransactionAsSynced(transaction.fisno);
      }
    } catch (e) {
      throw Exception('Failed to sync transaction to server: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getAllTransactions() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get all transactions: $e');
    }
  }

  @override
  Future<TahsilatModel?> getTransactionById(String fisno) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        where: 'fisno = ?',
        whereArgs: [fisno],
      );

      if (results.isNotEmpty) {
        return _mapToTahsilatModel(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction by ID: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getTransactionsByCustomer(String carikod) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        where: 'carikod = ?',
        whereArgs: [carikod],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by customer: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getTransactionsByUser(String username) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        where: 'username = ?',
        whereArgs: [username],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by user: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  @override
  Future<void> updateTransaction(TahsilatModel transaction) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'transactions',
        {
          'tutar': transaction.tutar,
          'aciklama': transaction.aciklama,
          'carikod': transaction.carikod,
          'username': transaction.username,
          'is_synced': 0, // Mark as not synced since it's updated
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'fisno = ?',
        whereArgs: [transaction.fisno],
      );

      // Try to sync with server if online
      if (await networkInfo.isConnected) {
        try {
          await _syncTransactionToServer(transaction);
        } catch (e) {
          // Ignore sync errors for updates
        }
      }
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String fisno) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'transactions',
        where: 'fisno = ?',
        whereArgs: [fisno],
      );

      // Try to sync deletion with server if online
      if (await networkInfo.isConnected) {
        try {
          await dio.delete('${ApiConfig.transactions}/$fisno');
        } catch (e) {
          // Ignore server sync errors for deletions
        }
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  @override
  Future<double> getTotalCollectionByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(tutar) as total
        FROM transactions
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total collection by date: $e');
    }
  }

  @override
  Future<double> getTotalCollectionByCustomer(String carikod) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(tutar) as total
        FROM transactions
        WHERE carikod = ?
      ''', [carikod]);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total collection by customer: $e');
    }
  }

  @override
  Future<double> getTotalCollectionByUser(String username) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(tutar) as total
        FROM transactions
        WHERE username = ?
      ''', [username]);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total collection by user: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> searchTransactions(String query) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        where: 'carikod LIKE ? OR aciklama LIKE ? OR fisno LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to search transactions: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getTodaysTransactions() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await getTransactionsByDateRange(startOfDay, endOfDay);
    } catch (e) {
      throw Exception('Failed to get today\'s transactions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionsSummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as transactions_count,
          SUM(tutar) as total_amount,
          MIN(tutar) as min_amount,
          MAX(tutar) as max_amount,
          AVG(tutar) as avg_amount
        FROM transactions
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      final row = result.first;
      return {
        'transactions_count': row['transactions_count'] ?? 0,
        'total_amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
        'min_amount': (row['min_amount'] as num?)?.toDouble() ?? 0.0,
        'max_amount': (row['max_amount'] as num?)?.toDouble() ?? 0.0,
        'avg_amount': (row['avg_amount'] as num?)?.toDouble() ?? 0.0,
        'date': date.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get transactions summary: $e');
    }
  }

  @override
  Future<void> syncTransactions() async {
    if (await networkInfo.isConnected) {
      try {
        // Download transactions from server
        final response = await dio.get(ApiConfig.transactions);

        if (response.statusCode == 200) {
          final List<dynamic> transactionsData = response.data['transactions'] ?? response.data;

          final db = await dbHelper.database;

          for (final transactionData in transactionsData) {
            final existingTransaction = await db.query(
              'transactions',
              where: 'fisno = ?',
              whereArgs: [transactionData['fisno']],
            );

            if (existingTransaction.isEmpty) {
              // Insert new transaction
              await db.insert('transactions', {
                'fisno': transactionData['fisno'],
                'tutar': transactionData['tutar'],
                'aciklama': transactionData['aciklama'],
                'carikod': transactionData['carikod'],
                'username': transactionData['username'],
                'is_synced': 1,
                'created_at': transactionData['created_at'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // Upload pending transactions
        await uploadPendingTransactions();
      } catch (e) {
        throw Exception('Transactions sync failed: $e');
      }
    } else {
      throw Exception('No internet connection for sync');
    }
  }

  @override
  Future<void> uploadPendingTransactions() async {
    if (await networkInfo.isConnected) {
      try {
        final pendingTransactions = await getPendingTransactions();

        for (final transaction in pendingTransactions) {
          try {
            await _syncTransactionToServer(transaction);
          } catch (e) {
            // Continue with next transaction if one fails
            continue;
          }
        }
      } catch (e) {
        throw Exception('Failed to upload pending transactions: $e');
      }
    }
  }

  @override
  Future<void> markTransactionAsSynced(String fisno) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'transactions',
        {'is_synced': 1},
        where: 'fisno = ?',
        whereArgs: [fisno],
      );
    } catch (e) {
      throw Exception('Failed to mark transaction as synced: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getPendingTransactions() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        where: 'is_synced = 0',
        orderBy: 'created_at ASC',
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get pending transactions: $e');
    }
  }

  @override
  Future<int> getTransactionsCount() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get transactions count: $e');
    }
  }

  @override
  Future<List<TahsilatModel>> getRecentTransactions({int limit = 10}) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'transactions',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((map) => _mapToTahsilatModel(map)).toList();
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }

  @override
  Future<void> createCheque(
    String customerCode,
    String chequeNumber,
    double amount,
    DateTime dueDate, {
    String bankName = '',
    String accountNumber = '',
    String description = '',
  }) async {
    try {
      final db = await dbHelper.database;
      await db.insert('cheques', {
        'customer_code': customerCode,
        'cheque_number': chequeNumber,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        'bank_name': bankName,
        'account_number': accountNumber,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create cheque: $e');
    }
  }

  @override
  Future<List<dynamic>> getAllCheques() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'cheques',
        orderBy: 'due_date ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get all cheques: $e');
    }
  }

  @override
  Future<List<dynamic>> getChequesByCustomer(String customerCode) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'cheques',
        where: 'customer_code = ?',
        whereArgs: [customerCode],
        orderBy: 'due_date ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get cheques by customer: $e');
    }
  }

  @override
  Future<List<dynamic>> getChequesByStatus(String status) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'cheques',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'due_date ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get cheques by status: $e');
    }
  }

  @override
  Future<void> updateChequeStatus(String chequeNumber, String status) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'cheques',
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'cheque_number = ?',
        whereArgs: [chequeNumber],
      );
    } catch (e) {
      throw Exception('Failed to update cheque status: $e');
    }
  }

  @override
  Future<List<dynamic>> getOverdueCheques() async {
    try {
      final db = await dbHelper.database;
      final today = DateTime.now().toIso8601String();
      final results = await db.query(
        'cheques',
        where: 'due_date < ? AND status = ?',
        whereArgs: [today, 'pending'],
        orderBy: 'due_date ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get overdue cheques: $e');
    }
  }

  @override
  Future<List<dynamic>> getChequesDueToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = await dbHelper.database;
      final results = await db.query(
        'cheques',
        where: 'due_date >= ? AND due_date < ? AND status = ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String(), 'pending'],
        orderBy: 'due_date ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get cheques due today: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getChequesSummary() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as total_cheques,
          SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) as pending_amount,
          SUM(CASE WHEN status = 'cleared' THEN amount ELSE 0 END) as cleared_amount,
          SUM(CASE WHEN status = 'bounced' THEN amount ELSE 0 END) as bounced_amount
        FROM cheques
      ''');

      final row = result.first;
      return {
        'total_cheques': row['total_cheques'] ?? 0,
        'pending_amount': (row['pending_amount'] as num?)?.toDouble() ?? 0.0,
        'cleared_amount': (row['cleared_amount'] as num?)?.toDouble() ?? 0.0,
        'bounced_amount': (row['bounced_amount'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get cheques summary: $e');
    }
  }

  @override
  Future<void> processChequePayment(String chequeNumber, double amount) async {
    try {
      await updateChequeStatus(chequeNumber, 'cleared');

      // Create a transaction record for the cheque payment
      final db = await dbHelper.database;
      final chequeResult = await db.query(
        'cheques',
        where: 'cheque_number = ?',
        whereArgs: [chequeNumber],
      );

      if (chequeResult.isNotEmpty) {
        final cheque = chequeResult.first;
        await createTransaction(
          amount,
          'Cheque payment - $chequeNumber',
          cheque['customer_code'] as String,
          'system', // Or get current user
        );
      }
    } catch (e) {
      throw Exception('Failed to process cheque payment: $e');
    }
  }

  @override
  Future<void> cancelCheque(String chequeNumber, String reason) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'cheques',
        {
          'status': 'cancelled',
          'description': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'cheque_number = ?',
        whereArgs: [chequeNumber],
      );
    } catch (e) {
      throw Exception('Failed to cancel cheque: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerTransactionHistory(String carikod) async {
    try {
      final db = await dbHelper.database;
      final results = await db.rawQuery('''
        SELECT
          fisno,
          tutar,
          aciklama,
          created_at,
          'transaction' as type
        FROM transactions
        WHERE carikod = ?
        UNION ALL
        SELECT
          cheque_number as fisno,
          amount as tutar,
          description as aciklama,
          created_at,
          'cheque' as type
        FROM cheques
        WHERE customer_code = ?
        ORDER BY created_at DESC
      ''', [carikod, carikod]);

      return results;
    } catch (e) {
      throw Exception('Failed to get customer transaction history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDailyCollectionReport(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as total_transactions,
          SUM(tutar) as total_amount,
          COUNT(DISTINCT carikod) as unique_customers,
          COUNT(DISTINCT username) as unique_users
        FROM transactions
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      final row = result.first;
      return {
        'date': date.toIso8601String(),
        'total_transactions': row['total_transactions'] ?? 0,
        'total_amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
        'unique_customers': row['unique_customers'] ?? 0,
        'unique_users': row['unique_users'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get daily collection report: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getMonthlyCollectionReport(int year, int month) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as total_transactions,
          SUM(tutar) as total_amount,
          COUNT(DISTINCT carikod) as unique_customers,
          AVG(tutar) as avg_amount
        FROM transactions
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      final row = result.first;
      return {
        'year': year,
        'month': month,
        'total_transactions': row['total_transactions'] ?? 0,
        'total_amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
        'unique_customers': row['unique_customers'] ?? 0,
        'avg_amount': (row['avg_amount'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get monthly collection report: $e');
    }
  }

  @override
  Future<String> exportTransactionsToCSV(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await getTransactionsByDateRange(startDate, endDate);

      final StringBuffer csv = StringBuffer();
      csv.writeln('Fisno,Tutar,Aciklama,Carikod,Username,Tarih');

      for (final transaction in transactions) {
        csv.writeln(
          '${transaction.fisno},${transaction.tutar},${transaction.aciklama},${transaction.carikod},${transaction.username},${DateTime.now().toIso8601String()}'
        );
      }

      return csv.toString();
    } catch (e) {
      throw Exception('Failed to export transactions to CSV: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOutstandingBalances() async {
    try {
      final db = await dbHelper.database;
      final results = await db.rawQuery('''
        SELECT
          c.id,
          c.name,
          c.phone,
          c.balance as outstanding_balance
        FROM customers c
        WHERE c.balance > 0
        ORDER BY c.balance DESC
      ''');

      return results;
    } catch (e) {
      throw Exception('Failed to get outstanding balances: $e');
    }
  }

  @override
  Future<double> calculateCustomerBalanceAfterTransaction(String carikod, double transactionAmount) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        'customers',
        columns: ['balance'],
        where: 'id = ? OR phone = ?',
        whereArgs: [carikod, carikod],
      );

      if (result.isNotEmpty) {
        final currentBalance = (result.first['balance'] as num?)?.toDouble() ?? 0.0;
        return currentBalance - transactionAmount; // Subtract because it's a payment
      }

      return -transactionAmount; // If customer not found, return negative transaction amount
    } catch (e) {
      throw Exception('Failed to calculate customer balance after transaction: $e');
    }
  }

  TahsilatModel _mapToTahsilatModel(Map<String, dynamic> map) {
    return TahsilatModel(
      fisno: map['fisno'] as String,
      tutar: (map['tutar'] as num).toDouble(),
      aciklama: map['aciklama'] as String,
      carikod: map['carikod'] as String,
      username: map['username'] as String,
    );
  }
}