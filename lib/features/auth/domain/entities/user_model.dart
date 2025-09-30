class UserModel {
  final String username;
  final String password;
  final String apikey;
  final int day; // Yeni alan

  UserModel({
    required this.username,
    required this.password,
    required this.apikey,
    required this.day, // Constructor'a ekledik
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'apikey': apikey,
      'day': day, // Map'e ekledik
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'],
      password: map['password'],
      apikey: map['apikey'],
      day: map['day'] ?? 0, // Map'ten aldık, eksikse 0
    );
  }
}
