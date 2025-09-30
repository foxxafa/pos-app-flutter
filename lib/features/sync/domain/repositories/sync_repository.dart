// lib/features/sync/domain/repositories/sync_repository.dart

abstract class SyncRepository {
  /// Sync all data with server
  Future<void> syncAllData();

  /// Sync products data
  Future<void> syncProducts();

  /// Sync customers data
  Future<void> syncCustomers();

  /// Sync orders data
  Future<void> syncOrders();

  /// Sync transactions data
  Future<void> syncTransactions();

  /// Upload pending data to server
  Future<void> uploadPendingData();

  /// Upload pending orders
  Future<void> uploadPendingOrders();

  /// Upload pending transactions
  Future<void> uploadPendingTransactions();

  /// Download latest data from server
  Future<void> downloadLatestData();

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus();

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime();

  /// Set last sync timestamp
  Future<void> setLastSyncTime(DateTime timestamp);

  /// Check if sync is required
  Future<bool> isSyncRequired();

  /// Get pending sync count
  Future<Map<String, int>> getPendingSyncCount();

  /// Force sync (ignore last sync time)
  Future<void> forceSync();

  /// Get sync progress
  Stream<Map<String, dynamic>> getSyncProgress();

  /// Cancel ongoing sync
  Future<void> cancelSync();

  /// Check connectivity and sync if possible
  Future<void> autoSync();

  /// Schedule automatic sync
  Future<void> scheduleAutoSync();

  /// Cancel scheduled sync
  Future<void> cancelAutoSync();

  /// Get sync history
  Future<List<Map<String, dynamic>>> getSyncHistory();

  /// Log sync operation
  Future<void> logSyncOperation(String operation, bool success, {String? error});

  /// Clear sync history
  Future<void> clearSyncHistory();

  /// Get sync settings
  Future<Map<String, dynamic>> getSyncSettings();

  /// Update sync settings
  Future<void> updateSyncSettings(Map<String, dynamic> settings);

  /// Enable/disable auto sync
  Future<void> setAutoSyncEnabled(bool enabled);

  /// Check if auto sync is enabled
  Future<bool> isAutoSyncEnabled();

  /// Set sync interval (in minutes)
  Future<void> setSyncInterval(int intervalMinutes);

  /// Get sync interval
  Future<int> getSyncInterval();

  /// Sync specific data types
  Future<void> syncDataTypes(List<String> dataTypes);

  /// Get available data types for sync
  Future<List<String>> getAvailableDataTypes();

  /// Reset sync status
  Future<void> resetSyncStatus();

  /// Get conflicts and handle them
  Future<List<Map<String, dynamic>>> getConflicts();

  /// Resolve sync conflict
  Future<void> resolveConflict(String conflictId, String resolution);

  /// Backup data before sync
  Future<void> backupDataBeforeSync();

  /// Restore data from backup
  Future<void> restoreDataFromBackup();

  /// Validate data integrity after sync
  Future<bool> validateDataIntegrity();

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics();

  /// Clear all local data and re-sync
  Future<void> fullResync();
}