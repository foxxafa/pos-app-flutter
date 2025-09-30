// lib/core/constants/app_constants.dart
class AppConstants {
  // App info
  static const String appName = 'POS Terminal';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'pos_database.db';
  static const int databaseVersion = 1;

  // SharedPreferences keys
  static const String keyApiKey = 'api_key';
  static const String keyUsername = 'username';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLastSyncTime = 'last_sync_time';

  // Cart settings
  static const int maxCartItems = 999;
  static const double maxItemQuantity = 9999.0;

  // UI Constants
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration apiTimeout = Duration(seconds: 30);
}