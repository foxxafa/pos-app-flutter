import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_app/models/login_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';

class LoginController {
  final String _baseUrl = 'https://test.rowhub.net/index.php?r=apimobil/login';

//POST
  Future<LoginModel?> postLogin(String username, String password) async {

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'success') {

             int today = DateTime.now().day; // 23 Mayıs 2025
          // final userModel = UserModel(
          //   username: username,
          //   password: password,
          //   apikey: json['apikey'],
          //   day: tarih.day,
          // );

          loginDatabase(username, password, json['apikey'], today);

          return LoginModel.fromJson(json);
        } else {
          print('Login failed: ${json['message']}');
          return LoginModel.fromJson(json);
        }
      } else {
        print('Server error: ${response.statusCode}');
        return null;
      }
    
  }

  loginDatabase(String username, String password,String apikey,int day)async{
    // Use DatabaseHelper instead of openDatabase
    DatabaseHelper dbHelper = DatabaseHelper();
    Database db = await dbHelper.database;

 // Silme ve ekleme işlemi
  await db.transaction((txn) async {
    // Önce tüm kayıtları sil
    await txn.delete('Login');

    // Yeni veriyi ekle
    int id1 = await txn.rawInsert(
      'INSERT INTO Login(username, password, apikey, day) VALUES(?, ?, ?, ?)',
      [username, password, apikey, day],
    );
    print('inserted1: $id1');
  });

List<Map> list = await db.rawQuery('SELECT * FROM Login');
print("selected $list");

      // Database açık kalacak - App Inspector için
   }
}
