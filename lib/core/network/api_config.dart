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

  // POS API endpoints - Base paths
  static String get auth => '/index.php?r=apimobil';
  static String get products => '/index.php?r=apimobil';
  static String get customers => '/index.php?r=apimobil';
  static String get orders => '/index.php?r=apimobil';
  static String get transactions => '/index.php?r=apimobil';
  static String get sync => '/index.php?r=apimobil';

  // Helper method - construct full URL
  static String getFullUrl(String endpoint) {
    return baseUrl + endpoint;
  }

  // Specific endpoint URLs
  // Auth endpoints
  static String get loginUrl => getFullUrl('/index.php?r=apimobil/login');

  // Transaction endpoints
  static String get nakitTahsilatUrl => getFullUrl('/index.php?r=apimobil/nakittahsilat');
  static String get cekTahsilatUrl => getFullUrl('/index.php?r=apimobil/cektahsilat');
  static String get bankaTahsilatUrl => getFullUrl('/index.php?r=apimobil/bankatahsilat');
  static String get krediKartiTahsilatUrl => getFullUrl('/index.php?r=apimobil/kredikartitahsilat');

  // Order endpoints
  static String get satisUrl => getFullUrl('/index.php?r=apimobil/satis');

  // Customer endpoints
  static String get musteriListesiUrl => getFullUrl('/index.php?r=apimobil/musterilistesi');

  // Refund endpoints
  static String get iadeUrl => getFullUrl('/index.php?r=apimobil/iade');
  static String get musteriUrunleriUrl => getFullUrl('/index.php?r=apimobil/musteriurunleri');
  static String get iademusterileriUrl => getFullUrl('/index.php?r=apimobil/iademusterileri');

  // Unit (Birimler) and Barcode endpoints
  static String get birimCountsUrl => getFullUrl('/index.php?r=apimobil/birimcounts');
  static String get birimlerListesiUrl => getFullUrl('/index.php?r=apimobil/birimlerlistesi');
  static String get getNewBirimlerUrl => getFullUrl('/index.php?r=apimobil/getnewbirimler');

  // Product count endpoint
  static String get productCountsUrl => getFullUrl('/index.php?r=apimobil/productcounts');

  // Customer count endpoint
  static String get customerCountsUrl => getFullUrl('/index.php?r=apimobil/customercounts');

  // Generic index.php base
  static String get indexPhpBase => getFullUrl('/index.php');

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