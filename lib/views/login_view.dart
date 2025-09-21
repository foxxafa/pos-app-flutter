import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_app/providers/user_provider.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:pos_app/controllers/login_controller.dart';
import 'package:pos_app/models/login_model.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

   @override
  void initState() {
    super.initState();
    _loadLastLogin();
  }

  
void _loadLastLogin() async {
  final lastLogin = await getLastLogin();
  if (lastLogin != null) {
    setState(() {
      _usernameController.text = lastLogin['username'];
      _passwordController.text = lastLogin['password'];
    });
  }
}

Future<Map<String, dynamic>?> getLastLogin() async {
  try {
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');

    // Dosya yoksa direkt null dön
    if (!File(path).existsSync()) {
      return null;
    }

    Database db = await openDatabase(path);

    // Önce tablo var mı kontrol et
    final checkTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='Login';"
    );

    if (checkTable.isEmpty) {
      await db.close();
      return null; // tablo yoksa
    }

    // Tablo varsa son kaydı al
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT * FROM Login ORDER BY id DESC LIMIT 1'
    );

    await db.close();

    if (result.isNotEmpty) {
      return result.first;
    }
    return null; // tablo var ama kayıt yoksa
  } catch (e) {
    print("❌ getLastLogin error: $e");
    return null;
  }
}


  void _login() async{
    try {
  final username = _usernameController.text;
  final password = _passwordController.text;
  
    final controller = LoginController();
    LoginModel? loginResult = await controller.postLogin(username, password);
  
  if (loginResult!=null) {
    if (loginResult.status=="success") {
  
    //kolay erismek icin provider icine at
    Provider.of<UserProvider>(context, listen: false).setUser(
    username: username,
    password: password,
    apikey: loginResult.apikey!,
    day: DateTime.now().day,
  );
  
  //menu sayfaya git
  Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const MenuView()),
    );
  
    } else {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Login Error#35"),
      content: Text(loginResult.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Okay"),
        )
      ],
    ),
  );
    }
  }else {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Connection Error#34"),
      content: const Text("Please connect to the internet"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Okay"),
        )
      ],
    ),
  );
    }
} on Exception {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error#133: Check your Internet connection.')),
    );
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Welcome",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 3.h),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: 60.w,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _login,
                  child: Text("LOGIN", style: TextStyle(fontSize: 16.sp)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
