import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';
import 'package:pos_app/features/auth/presentation/screens/login_view.dart';
import 'package:pos_app/features/cart/presentation/cartsavedview.dart';
import 'package:pos_app/features/reports/presentation/screens/report_view.dart';
import 'package:pos_app/features/orders/presentation/screens/sales_view.dart';
import 'package:pos_app/features/sync/presentation/screens/sync_view.dart';
import 'package:pos_app/features/sync/presentation/sync_controller.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';

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
    _checkPendingImageDownloads();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _userName = userProvider.username;
      });
    }
  }

  // Yarım kalan resim indirmelerini kontrol et
  Future<void> _checkPendingImageDownloads() async {
    try {
      final syncController = SyncController();
      await syncController.checkAndResumeImageDownload();
    } catch (e) {
      print('⚠️ Resim indirme kontrol hatası: $e');
    }
  }

  Future<void> _handleLogoutAttempt() async {
    _showLogoutConfirmationDialog();
  }

  Future<void> _performLogout() async {
    try {
      // Get database path

      // Open database and delete table
      DatabaseHelper dbHelper = DatabaseHelper();
  Database db = await dbHelper.database;
      await db.delete('Login');
      // Database açık kalacak - App Inspector için

      // Navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginView()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.logout_error'.tr(args: [e.toString()])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('auth.logout_title'.tr()),
          content: Text('auth.logout_confirmation'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('auth.cancel'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text('auth.logout'.tr()),
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
          title: Text('app.title'.tr()),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              tooltip: 'auth.logout'.tr(),
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
                      label: 'home.customer_list'.tr(),
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
                      label: 'home.reports'.tr(),
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
                      label: 'home.terminal_sync'.tr(),
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
                      icon: Icons.shopping_cart_outlined,
                      label: 'home.saved_carts'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartListPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _HomeButton(
                      icon: Icons.settings_outlined,
                      label: 'home.settings'.tr(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('home.settings_not_ready'.tr()),
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
                    'home.welcome'.tr(),
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

// DIAPALET style _HomeButton widget
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