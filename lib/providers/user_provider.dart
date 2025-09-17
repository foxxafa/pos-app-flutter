import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String _username = '';
  String _password = '';
  String _apikey = '';
  int _day = 0;

  // Getter'lar
  String get username => _username;
  String get password => _password;
  String get apikey => _apikey;
  int get day => _day;

  // Setter'lar
  void setUser({
    required String username,
    required String password,
    required String apikey,
    required int day,
  }) {
    _username = username;
    _password = password;
    _apikey = apikey;
    _day = day;
    notifyListeners();
  }

  void clearUser() {
    _username = '';
    _password = '';
    _apikey = '';
    _day = 0;
    notifyListeners();
  }
}
