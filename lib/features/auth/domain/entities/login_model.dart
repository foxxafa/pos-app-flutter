import 'package:pos_app/features/auth/domain/entities/user_model.dart';

class LoginModel {
  final String status;
  final String message;
  final String? apikey;

  LoginModel({
    required this.status,
    required this.message,
    this.apikey,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status'],
      message: json['message'],
      apikey: json.containsKey('apikey') ? json['apikey'] : null,
    );
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final UserModel? user;
  final String? apiKey;

  LoginResponse({
    required this.success,
    required this.message,
    this.user,
    this.apiKey,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? UserModel.fromMap(json['user']) : null,
      apiKey: json['api_key'],
    );
  }
}
