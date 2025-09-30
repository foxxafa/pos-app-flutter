// lib/core/network/api_config.dart
import 'package:pos_app/core/network/api_environments.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // POS uygulama ortam seçimi
  static const ApiEnvironment currentEnvironment = ApiEnvironment.production;

  static final ApiEnvConfig _config = ApiEnvironments.getEnv(currentEnvironment);

  // Environment bilgileri
  static String get baseUrl => _config.baseUrl;
  static String get environmentName => _config.name;
  static String get environmentDescription => _config.description;
  static bool get isProduction => currentEnvironment == ApiEnvironment.production;
  static bool get isStaging => currentEnvironment == ApiEnvironment.staging;
  static bool get isLocal => currentEnvironment == ApiEnvironment.local;

  // POS API endpoints
  static String get auth => '/api/auth';
  static String get products => '/api/products';
  static String get customers => '/api/customers';
  static String get orders => '/api/orders';
  static String get transactions => '/api/transactions';
  static String get sync => '/api/sync';

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final config = ApiEnvironments.getEnv(currentEnvironment);

    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 1),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Debug logging
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    // API Key interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final apiKey = prefs.getString('api_key');
        if (apiKey != null) {
          options.headers['Authorization'] = 'Bearer $apiKey';
        }
        return handler.next(options);
      },
    ));

    return dio;
  }
}