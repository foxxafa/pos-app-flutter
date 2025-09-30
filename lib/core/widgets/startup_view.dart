import 'package:flutter/material.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';
import 'package:pos_app/features/auth/presentation/screens/login_view.dart';
import 'package:pos_app/core/widgets/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';


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
    // var connectivityResult = await Connectivity().checkConnectivity();
    // bool hasInternet = connectivityResult != ConnectivityResult.none; // Kullanılmıyor

    // 2. Veritabanı kontrolü
    DatabaseHelper dbhelper = DatabaseHelper();

    // Database'i singleton olarak al (Tables already created automatically in _onCreate)
    Database db = await dbhelper.database;

    List<Map> list = await db.rawQuery('SELECT * FROM Login');
    // DB'yi kapatmıyoruz - App Inspector için açık kalması gerekiyor
    // await db.close();

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
