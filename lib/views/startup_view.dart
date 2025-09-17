import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:pos_app/controllers/database_helper.dart';
import 'package:pos_app/providers/user_provider.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/views/login_view.dart';


class StartupView extends StatefulWidget {
  @override
  _StartupViewState createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    // 1. İnternet bağlantısı kontrolü
    var connectivityResult = await Connectivity().checkConnectivity();
    bool hasInternet = connectivityResult != ConnectivityResult.none;

    // 2. Veritabanı kontrolü
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');
    
    DatabaseHelper dbhelper=DatabaseHelper();
    Database db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
    await dbhelper.createTablesIfNotExists(db);
  },
  onOpen: (Database db) async {
    await dbhelper.createTablesIfNotExists(db); // onOpen'da da çağırabilirsin
  },

);

    List<Map> list = await db.rawQuery('SELECT * FROM Login');print("DB CLOSE TIME 10");
    await db.close();

    // 3. Bugünün day değeri
    int today = DateTime.now().day;

//daha önce bir kez internet ile giriş yapıldıysa
    if (
      (list.isNotEmpty && list[0]['day'] == today)
) {
  //kolay erismek icin provider icine at
  Provider.of<UserProvider>(context, listen: false).setUser(
  username: list[0]['username'],
  password: list[0]['password'],
  apikey: list[0]['apikey'],
  day: list[0]['day'],
);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuView()),
      );
    } 

    else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yönlendirme yapılana kadar basit bir yükleniyor ekranı
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
