// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:pos_app/features/auth/domain/entities/user_model.dart';
import 'package:pos_app/features/auth/domain/entities/login_model.dart';

abstract class AuthRepository {
  /// User authentication with username and password
  Future<LoginResponse?> login(String username, String password);

  /// Logout current user
  Future<void> logout();

  /// Check if user is currently logged in
  Future<bool> isLoggedIn();

  /// Get current user information
  Future<UserModel?> getCurrentUser();

  /// Save user session to local storage
  Future<void> saveUserSession(UserModel user, String apiKey);

  /// Clear user session from local storage
  Future<void> clearUserSession();

  /// Validate user credentials offline
  Future<bool> validateOfflineCredentials(String username, String password);

  /// Sync user data with server
  Future<void> syncUserData();
}