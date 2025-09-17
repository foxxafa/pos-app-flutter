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
