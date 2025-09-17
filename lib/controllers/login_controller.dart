import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_app/models/login_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
    // Get a location using getDatabasesPath
      var databasesPath = await getDatabasesPath();
      String path = p.join(databasesPath, 'pos_database.db');
      
      // open the database
Database db = await openDatabase(path, version: 1,
          onCreate: (db, version) async {
  await db.execute('CREATE TABLE Login (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, password TEXT NOT NULL, apikey TEXT NOT NULL, day INTEGER NOT NULL)');
});

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
print("DB CLOSE TIME 3");

      await db.close();
   }
}
