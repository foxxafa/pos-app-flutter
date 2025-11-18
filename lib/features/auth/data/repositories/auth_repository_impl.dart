// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/auth/domain/entities/user_model.dart';
import 'package:pos_app/features/auth/domain/entities/login_model.dart';
import 'package:pos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  AuthRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  @override
  Future<LoginResponse?> login(String username, String password) async {
    try {
      if (await networkInfo.isConnected) {
        return await _loginOnline(username, password);
      } else {
        return await _loginOffline(username, password);
      }
    } catch (e) {
      // Fallback to offline login if online fails
      return await _loginOffline(username, password);
    }
  }

  Future<LoginResponse?> _loginOnline(String username, String password) async {
    try {
      // Rowhub API uses form-data, not JSON
      final response = await dio.post(
        ApiConfig.auth + '/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      print('🔑 Online login response: ${response.data}');

      // Rowhub API response format: {status: "success", message: "...", apikey: "..."}
      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['status'] == 'success') {
          final apiKey = responseData['apikey'] ?? '';
          final int day = DateTime.now().day;

          final user = UserModel(
            username: username,
            password: password, // Store for offline access
            apikey: apiKey,
            day: day,
          );

          final loginResponse = LoginResponse(
            success: true,
            message: responseData['message'] ?? 'Login successful',
            user: user,
            apiKey: apiKey,
          );

          // Save to local database for offline access
          await _saveUserToDatabase(user);
          await saveUserSession(user, apiKey);

          print('🔑 ✅ Online login successful');
          return loginResponse;
        } else {
          // ✅ Backend'den gelen error mesajlarını yakalayalım
          final errorMessage = responseData['message'] ?? 'Login failed';
          print('🔑 ❌ Login failed: $errorMessage');

          return LoginResponse(
            success: false,
            message: errorMessage,
          );
        }
      } else {
        return LoginResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('🔑 ❌ Online login exception: $e');
      throw Exception('Online login failed: $e');
    }
  }

  Future<LoginResponse?> _loginOffline(String username, String password) async {
    try {
      final db = await dbHelper.database;
      // Use 'Login' table (same as LoginController used)
      final result = await db.query(
        'Login',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (result.isNotEmpty) {
        final userData = result.first;
        final user = UserModel(
          username: userData['username'] as String,
          password: userData['password'] as String,
          apikey: userData['apikey'] as String,
          day: userData['day'] as int,
        );

        await saveUserSession(user, user.apikey);

        return LoginResponse(
          success: true,
          message: 'Offline login successful',
          user: user,
          apiKey: user.apikey,
        );
      } else {
        return LoginResponse(
          success: false,
          message: 'Invalid credentials',
        );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Offline login failed: $e',
      );
    }
  }

  Future<void> _saveUserToDatabase(UserModel user) async {
    final db = await dbHelper.database;
    // Use 'Login' table (same as LoginController used)
    // Delete old records first, then insert new one
    await db.transaction((txn) async {
      await txn.delete('Login');
      await txn.insert(
        'Login',
        {
          'username': user.username,
          'password': user.password,
          'apikey': user.apikey,
          'day': user.day,
        },
      );
    });
  }

  @override
  Future<void> saveUserSession(UserModel user, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user.username);
    await prefs.setString('password', user.password);
    await prefs.setString('api_key', apiKey);
    await prefs.setInt('day', user.day);
    await prefs.setBool('is_logged_in', true);
  }

  @override
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('api_key');
    await prefs.remove('day');
    await prefs.setBool('is_logged_in', false);
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final apiKey = prefs.getString('api_key');
    final day = prefs.getInt('day');

    if (username != null && password != null && apiKey != null) {
      return UserModel(
        username: username,
        password: password,
        apikey: apiKey,
        day: day ?? 0,
      );
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await clearUserSession();

    // Optional: Call logout API if online
    if (await networkInfo.isConnected) {
      try {
        await dio.post(ApiConfig.auth + '/logout');
      } catch (e) {
        // Ignore network errors during logout
      }
    }
  }

  @override
  Future<bool> validateOfflineCredentials(String username, String password) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty;
  }

  @override
  Future<void> syncUserData() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await getCurrentUser();
        if (user != null) {
          // Sync user data with server if needed
          final response = await dio.get(ApiConfig.auth + '/profile');
          if (response.statusCode == 200) {
            // Update local user data
            await _saveUserToDatabase(user);
          }
        }
      } catch (e) {
        // Handle sync error
        throw Exception('User data sync failed: $e');
      }
    }
  }
}