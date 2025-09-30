// lib/features/sync/data/repositories/sync_repository_impl.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:pos_app/features/products/domain/repositories/product_repository.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/orders/domain/repositories/order_repository.dart';
import 'package:pos_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncRepositoryImpl implements SyncRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;
  final ProductRepository productRepository;
  final CustomerRepository customerRepository;
  final OrderRepository orderRepository;
  final TransactionRepository transactionRepository;

  StreamController<Map<String, dynamic>>? _syncProgressController;
  bool _isSyncInProgress = false;
  bool _syncCancelled = false;

  SyncRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
    required this.productRepository,
    required this.customerRepository,
    required this.orderRepository,
    required this.transactionRepository,
  });

  @override
  Future<void> syncAllData() async {
    if (_isSyncInProgress) {
      throw Exception('Sync already in progress');
    }

    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    _isSyncInProgress = true;
    _syncCancelled = false;
    _syncProgressController = StreamController<Map<String, dynamic>>.broadcast();

    try {
      await logSyncOperation('sync_all_start', true);

      // Step 1: Backup data before sync
      _emitProgress('Backing up data...', 10);
      await backupDataBeforeSync();

      if (_syncCancelled) return;

      // Step 2: Upload pending data
      _emitProgress('Uploading pending data...', 20);
      await uploadPendingData();

      if (_syncCancelled) return;

      // Step 3: Download latest data
      _emitProgress('Downloading products...', 40);
      await syncProducts();

      if (_syncCancelled) return;

      _emitProgress('Downloading customers...', 60);
      await syncCustomers();

      if (_syncCancelled) return;

      _emitProgress('Downloading orders...', 80);
      await syncOrders();

      if (_syncCancelled) return;

      _emitProgress('Downloading transactions...', 90);
      await syncTransactions();

      if (_syncCancelled) return;

      // Step 4: Validate data integrity
      _emitProgress('Validating data...', 95);
      final isValid = await validateDataIntegrity();

      if (!isValid) {
        throw Exception('Data integrity validation failed');
      }

      // Step 5: Update sync timestamp
      await setLastSyncTime(DateTime.now());

      _emitProgress('Sync completed successfully', 100);
      await logSyncOperation('sync_all_complete', true);

    } catch (e) {
      _emitProgress('Sync failed: $e', -1);
      await logSyncOperation('sync_all_failed', false, error: e.toString());
      throw Exception('Sync failed: $e');
    } finally {
      _isSyncInProgress = false;
      await _syncProgressController?.close();
      _syncProgressController = null;
    }
  }

  void _emitProgress(String message, int percentage) {
    if (_syncProgressController != null && !_syncProgressController!.isClosed) {
      _syncProgressController!.add({
        'message': message,
        'percentage': percentage,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> syncProducts() async {
    try {
      await productRepository.syncProducts();
    } catch (e) {
      throw Exception('Failed to sync products: $e');
    }
  }

  @override
  Future<void> syncCustomers() async {
    try {
      await customerRepository.syncCustomers();
    } catch (e) {
      throw Exception('Failed to sync customers: $e');
    }
  }

  @override
  Future<void> syncOrders() async {
    try {
      await orderRepository.syncOrders();
    } catch (e) {
      throw Exception('Failed to sync orders: $e');
    }
  }

  @override
  Future<void> syncTransactions() async {
    try {
      await transactionRepository.syncTransactions();
    } catch (e) {
      throw Exception('Failed to sync transactions: $e');
    }
  }

  @override
  Future<void> uploadPendingData() async {
    try {
      await uploadPendingOrders();
      await uploadPendingTransactions();
    } catch (e) {
      throw Exception('Failed to upload pending data: $e');
    }
  }

  @override
  Future<void> uploadPendingOrders() async {
    try {
      await orderRepository.uploadPendingOrders();
    } catch (e) {
      throw Exception('Failed to upload pending orders: $e');
    }
  }

  @override
  Future<void> uploadPendingTransactions() async {
    try {
      await transactionRepository.uploadPendingTransactions();
    } catch (e) {
      throw Exception('Failed to upload pending transactions: $e');
    }
  }

  @override
  Future<void> downloadLatestData() async {
    try {
      await syncProducts();
      await syncCustomers();
      await syncOrders();
      await syncTransactions();
    } catch (e) {
      throw Exception('Failed to download latest data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final lastSyncTime = await getLastSyncTime();
      final pendingCounts = await getPendingSyncCount();
      final autoSyncEnabled = await isAutoSyncEnabled();
      final syncInterval = await getSyncInterval();

      return {
        'last_sync_time': lastSyncTime?.toIso8601String(),
        'pending_counts': pendingCounts,
        'is_sync_in_progress': _isSyncInProgress,
        'auto_sync_enabled': autoSyncEnabled,
        'sync_interval_minutes': syncInterval,
        'is_sync_required': await isSyncRequired(),
      };
    } catch (e) {
      throw Exception('Failed to get sync status: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('last_sync_time');
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setLastSyncTime(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', timestamp.toIso8601String());
    } catch (e) {
      throw Exception('Failed to set last sync time: $e');
    }
  }

  @override
  Future<bool> isSyncRequired() async {
    try {
      final lastSyncTime = await getLastSyncTime();
      if (lastSyncTime == null) return true;

      final syncInterval = await getSyncInterval();
      final nextSyncTime = lastSyncTime.add(Duration(minutes: syncInterval));
      return DateTime.now().isAfter(nextSyncTime);
    } catch (e) {
      return true; // Default to requiring sync if there's an error
    }
  }

  @override
  Future<Map<String, int>> getPendingSyncCount() async {
    try {
      final pendingOrders = await orderRepository.getPendingOrders();
      final pendingTransactions = await transactionRepository.getPendingTransactions();

      return {
        'orders': pendingOrders.length,
        'transactions': pendingTransactions.length,
        'total': pendingOrders.length + pendingTransactions.length,
      };
    } catch (e) {
      throw Exception('Failed to get pending sync count: $e');
    }
  }

  @override
  Future<void> forceSync() async {
    // Reset last sync time to force sync
    await setLastSyncTime(DateTime.fromMillisecondsSinceEpoch(0));
    await syncAllData();
  }

  @override
  Stream<Map<String, dynamic>> getSyncProgress() {
    if (_syncProgressController == null) {
      _syncProgressController = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _syncProgressController!.stream;
  }

  @override
  Future<void> cancelSync() async {
    _syncCancelled = true;
    _emitProgress('Sync cancelled by user', -2);
    await logSyncOperation('sync_cancelled', false, error: 'Cancelled by user');
  }

  @override
  Future<void> autoSync() async {
    if (await networkInfo.isConnected && !_isSyncInProgress) {
      if (await isSyncRequired()) {
        try {
          await syncAllData();
        } catch (e) {
          // Log error but don't throw for auto sync
          await logSyncOperation('auto_sync_failed', false, error: e.toString());
        }
      }
    }
  }

  @override
  Future<void> scheduleAutoSync() async {
    // This would typically use a background task scheduler
    // For now, just enable auto sync setting
    await setAutoSyncEnabled(true);
  }

  @override
  Future<void> cancelAutoSync() async {
    await setAutoSyncEnabled(false);
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncHistory() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'sync_history',
        orderBy: 'created_at DESC',
        limit: 50,
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get sync history: $e');
    }
  }

  @override
  Future<void> logSyncOperation(String operation, bool success, {String? error}) async {
    try {
      final db = await dbHelper.database;
      await db.insert('sync_history', {
        'operation': operation,
        'success': success ? 1 : 0,
        'error_message': error,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Keep only last 100 records
      await db.rawQuery('''
        DELETE FROM sync_history
        WHERE id NOT IN (
          SELECT id FROM sync_history
          ORDER BY created_at DESC
          LIMIT 100
        )
      ''');
    } catch (e) {
      // Ignore logging errors
    }
  }

  @override
  Future<void> clearSyncHistory() async {
    try {
      final db = await dbHelper.database;
      await db.delete('sync_history');
    } catch (e) {
      throw Exception('Failed to clear sync history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'auto_sync_enabled': prefs.getBool('auto_sync_enabled') ?? false,
        'sync_interval_minutes': prefs.getInt('sync_interval_minutes') ?? 60,
        'sync_on_startup': prefs.getBool('sync_on_startup') ?? true,
        'sync_on_network_change': prefs.getBool('sync_on_network_change') ?? true,
        'wifi_only': prefs.getBool('wifi_only_sync') ?? false,
      };
    } catch (e) {
      throw Exception('Failed to get sync settings: $e');
    }
  }

  @override
  Future<void> updateSyncSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (settings.containsKey('auto_sync_enabled')) {
        await prefs.setBool('auto_sync_enabled', settings['auto_sync_enabled']);
      }

      if (settings.containsKey('sync_interval_minutes')) {
        await prefs.setInt('sync_interval_minutes', settings['sync_interval_minutes']);
      }

      if (settings.containsKey('sync_on_startup')) {
        await prefs.setBool('sync_on_startup', settings['sync_on_startup']);
      }

      if (settings.containsKey('sync_on_network_change')) {
        await prefs.setBool('sync_on_network_change', settings['sync_on_network_change']);
      }

      if (settings.containsKey('wifi_only')) {
        await prefs.setBool('wifi_only_sync', settings['wifi_only']);
      }
    } catch (e) {
      throw Exception('Failed to update sync settings: $e');
    }
  }

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_sync_enabled', enabled);
    } catch (e) {
      throw Exception('Failed to set auto sync enabled: $e');
    }
  }

  @override
  Future<bool> isAutoSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('auto_sync_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setSyncInterval(int intervalMinutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sync_interval_minutes', intervalMinutes);
    } catch (e) {
      throw Exception('Failed to set sync interval: $e');
    }
  }

  @override
  Future<int> getSyncInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('sync_interval_minutes') ?? 60; // Default 1 hour
    } catch (e) {
      return 60;
    }
  }

  @override
  Future<void> syncDataTypes(List<String> dataTypes) async {
    if (!await networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    for (final dataType in dataTypes) {
      switch (dataType.toLowerCase()) {
        case 'products':
          await syncProducts();
          break;
        case 'customers':
          await syncCustomers();
          break;
        case 'orders':
          await syncOrders();
          break;
        case 'transactions':
          await syncTransactions();
          break;
        default:
          throw Exception('Unknown data type: $dataType');
      }
    }
  }

  @override
  Future<List<String>> getAvailableDataTypes() async {
    return ['products', 'customers', 'orders', 'transactions'];
  }

  @override
  Future<void> resetSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sync_time');
      await clearSyncHistory();
    } catch (e) {
      throw Exception('Failed to reset sync status: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getConflicts() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'sync_conflicts',
        orderBy: 'created_at DESC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get conflicts: $e');
    }
  }

  @override
  Future<void> resolveConflict(String conflictId, String resolution) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'sync_conflicts',
        {
          'resolution': resolution,
          'resolved_at': DateTime.now().toIso8601String(),
          'status': 'resolved',
        },
        where: 'id = ?',
        whereArgs: [conflictId],
      );
    } catch (e) {
      throw Exception('Failed to resolve conflict: $e');
    }
  }

  @override
  Future<void> backupDataBeforeSync() async {
    try {
      final db = await dbHelper.database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create backup tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS backup_products_$timestamp AS
        SELECT * FROM products
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS backup_customers_$timestamp AS
        SELECT * FROM customers
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS backup_orders_$timestamp AS
        SELECT * FROM orders
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS backup_transactions_$timestamp AS
        SELECT * FROM transactions
      ''');

      // Store backup timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_timestamp', timestamp.toString());

    } catch (e) {
      throw Exception('Failed to backup data before sync: $e');
    }
  }

  @override
  Future<void> restoreDataFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString('last_backup_timestamp');

      if (timestampStr == null) {
        throw Exception('No backup found');
      }

      final db = await dbHelper.database;
      final timestamp = timestampStr;

      // Restore from backup tables
      await db.execute('DELETE FROM products');
      await db.execute('INSERT INTO products SELECT * FROM backup_products_$timestamp');

      await db.execute('DELETE FROM customers');
      await db.execute('INSERT INTO customers SELECT * FROM backup_customers_$timestamp');

      await db.execute('DELETE FROM orders');
      await db.execute('INSERT INTO orders SELECT * FROM backup_orders_$timestamp');

      await db.execute('DELETE FROM transactions');
      await db.execute('INSERT INTO transactions SELECT * FROM backup_transactions_$timestamp');

      // Clean up backup tables
      await db.execute('DROP TABLE IF EXISTS backup_products_$timestamp');
      await db.execute('DROP TABLE IF EXISTS backup_customers_$timestamp');
      await db.execute('DROP TABLE IF EXISTS backup_orders_$timestamp');
      await db.execute('DROP TABLE IF EXISTS backup_transactions_$timestamp');

    } catch (e) {
      throw Exception('Failed to restore data from backup: $e');
    }
  }

  @override
  Future<bool> validateDataIntegrity() async {
    try {
      final db = await dbHelper.database;

      // Check if core tables exist and have data
      final productsCount = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final customersCount = await db.rawQuery('SELECT COUNT(*) as count FROM customers');

      // Basic validation - ensure we have some core data
      final hasProducts = (productsCount.first['count'] as int) > 0;
      final hasCustomers = (customersCount.first['count'] as int) > 0;

      return hasProducts && hasCustomers;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final db = await dbHelper.database;

      // Get sync history statistics
      final syncStats = await db.rawQuery('''
        SELECT
          COUNT(*) as total_syncs,
          SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_syncs,
          SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failed_syncs
        FROM sync_history
        WHERE created_at >= datetime('now', '-30 days')
      ''');

      final pendingCounts = await getPendingSyncCount();
      final lastSyncTime = await getLastSyncTime();

      final stats = syncStats.first;
      return {
        'total_syncs_last_30_days': stats['total_syncs'] ?? 0,
        'successful_syncs_last_30_days': stats['successful_syncs'] ?? 0,
        'failed_syncs_last_30_days': stats['failed_syncs'] ?? 0,
        'success_rate': (stats['total_syncs'] as int?) != null && (stats['total_syncs'] as int) > 0
            ? (((stats['successful_syncs'] as int) / (stats['total_syncs'] as int)) * 100).toStringAsFixed(2)
            : '0.00',
        'pending_counts': pendingCounts,
        'last_sync_time': lastSyncTime?.toIso8601String(),
        'days_since_last_sync': lastSyncTime != null
            ? DateTime.now().difference(lastSyncTime).inDays
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get sync statistics: $e');
    }
  }

  @override
  Future<void> fullResync() async {
    try {
      // Clear all local data
      final db = await dbHelper.database;

      await db.delete('products');
      await db.delete('customers');
      await db.delete('orders');
      await db.delete('transactions');

      // Reset sync status
      await resetSyncStatus();

      // Perform full sync
      await syncAllData();

    } catch (e) {
      throw Exception('Failed to perform full resync: $e');
    }
  }
}