import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pos_app/providers/user_provider.dart';
import 'package:pos_app/views/cartsavedview.dart';
import 'package:pos_app/views/login_view.dart';
import 'package:pos_app/views/report_view.dart';
import 'package:pos_app/views/sales_view.dart';
import 'package:pos_app/views/sync_view.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class MenuView extends StatefulWidget {
  const MenuView({Key? key}) : super(key: key);

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  String _userName = '...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _userName = userProvider.username ?? 'Kullanıcı';
      });
    }
  }

  Future<void> _handleLogoutAttempt() async {
    _showLogoutConfirmationDialog();
  }

  Future<void> _performLogout() async {
    try {
      // Veritabanı yolunu al
      var databasesPath = await getDatabasesPath();
      String path = p.join(databasesPath, 'pos_database.db');

      // Veritabanını aç ve tabloyu sil
      Database db = await openDatabase(path);
      await db.delete('Login');
      await db.close();

      // Login ekranına yönlendir
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginView()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Uygulamadan çıkış yapmak istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Çıkış'),
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('POS Terminal'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              tooltip: 'Çıkış Yap',
              onPressed: _handleLogoutAttempt,
            ),
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final double verticalPadding = constraints.maxHeight * 0.03;
          final double horizontalPadding = constraints.maxWidth * 0.05;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (verticalPadding * 2)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _HomeButton(
                      icon: Icons.people_outline,
                      label: 'Müşteri Listesi',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalesView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _HomeButton(
                      icon: Icons.assessment_outlined,
                      label: 'Raporlar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _HomeButton(
                      icon: Icons.sync_outlined,
                      label: 'Terminal Sync',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SyncView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _HomeButton(
                      icon: Icons.settings_outlined,
                      label: 'Ayarlar',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ayarlar sayfası hazırlanıyor...'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _HomeButton(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Kayıtlı Sepetler',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartListPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person_outline,
                size: 28,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş Geldiniz',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DIAPALET'teki _HomeButton widget'ını birebir kopyalıyoruz
class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      icon: Icon(icon, size: 32),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
    );
  }
}