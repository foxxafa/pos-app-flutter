import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';
import 'package:pos_app/core/widgets/menu_view.dart';
import 'package:pos_app/core/local/database_helper.dart';
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

    DatabaseHelper dbHelper = DatabaseHelper();
  Database db = await dbHelper.database;

    // Önce tablo var mı kontrol et
    final checkTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='Login';"
    );

    if (checkTable.isEmpty) {
      // Database açık kalacak - App Inspector için
      return null; // tablo yoksa
    }

    // Tablo varsa son kaydı al
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT * FROM Login ORDER BY id DESC LIMIT 1'
    );

    // Database açık kalacak - App Inspector için

    if (result.isNotEmpty) {
      return result.first;
    }
    return null; // tablo var ama kayıt yoksa
  } catch (e) {
    print("❌ getLastLogin error: $e");
    return null;
  }
}


  void _login() async {
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Validate input
      if (username.isEmpty || password.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Validation Error"),
            content: const Text("Please enter both username and password"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Okay"),
              )
            ],
          ),
        );
        return;
      }

      // ✅ Use UserProvider.login() instead of LoginController
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      print('🔑 Login attempt - Username: $username');

      // Call repository-based login
      final success = await userProvider.login(username, password);

      if (success) {
        print('🔑 ✅ Login successful');

        // Navigate to MenuView
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuView()),
          );
        }
      } else {
        print('🔑 ❌ Login failed: ${userProvider.errorMessage}');

        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Login Error"),
              content: Text(userProvider.errorMessage ?? "Login failed. Please check your credentials."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Okay"),
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('🔑 ❌ Login View Exception: $e');
      print('🔑 ❌ Exception type: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Login failed - $e')),
        );
      }
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
                height: 8.h.clamp(56.0, double.infinity),
                child: ElevatedButton(
                  onPressed: _login,
                  child: Text(
                    "LOGIN",
                    style: TextStyle(fontSize: 18.sp.clamp(16.0, double.infinity)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
