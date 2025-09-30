// lib/core/network/api_environments.dart
enum ApiEnvironment { local, staging, production }

class ApiEnvConfig {
  final String name;
  final String baseUrl;
  final String description;

  const ApiEnvConfig({
    required this.name,
    required this.baseUrl,
    required this.description,
  });
}

class ApiEnvironments {
  // POS uygulaması için API endpoint'leri
  static const String _localBaseUrl = 'http://localhost:8080';
  static const String _stagingBaseUrl = 'https://pos-staging.example.com';
  static const String _productionBaseUrl = 'https://pos-api.example.com';

  static const Map<ApiEnvironment, ApiEnvConfig> _environments = {
    ApiEnvironment.local: ApiEnvConfig(
      name: 'Local',
      baseUrl: _localBaseUrl,
      description: 'Local development server',
    ),
    ApiEnvironment.staging: ApiEnvConfig(
      name: 'Staging',
      baseUrl: _stagingBaseUrl,
      description: 'Staging test environment',
    ),
    ApiEnvironment.production: ApiEnvConfig(
      name: 'Production',
      baseUrl: _productionBaseUrl,
      description: 'Production live system',
    ),
  };

  static ApiEnvConfig getEnv(ApiEnvironment env) {
    return _environments[env]!;
  }

  static List<ApiEnvConfig> getAllEnvironments() {
    return _environments.values.toList();
  }
}