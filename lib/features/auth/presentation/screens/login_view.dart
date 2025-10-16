import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';
import 'package:pos_app/core/widgets/menu_view.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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


  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        print('🔑 Login attempt - Username: ${_usernameController.text}');

        final success = await userProvider.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (success && mounted) {
          print('🔑 ✅ Login successful');

          // Navigate to MenuView
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MenuView()),
          );
        } else if (mounted) {
          setState(() {
            _errorMessage = userProvider.errorMessage ?? "Login failed. Please check your credentials.";
          });
        }
      } catch (e) {
        print('🔑 ❌ Login View Exception: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Error: Login failed - $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please login to continue',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('LOGIN'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
