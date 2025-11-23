import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path/path.dart';
import 'package:pos_app/features/transactions/presentation/screens/collection_activity.dart';
import 'package:pos_app/features/customer/presentation/customerdetail_view.dart';
import 'package:pos_app/features/reports/presentation/screens/invoice_activity.dart';
import 'package:pos_app/core/widgets/menu_view.dart';
import 'package:pos_app/features/refunds/presentation/screens/refund_activity.dart';
import 'package:pos_app/features/reports/presentation/screens/statement_pdf_view.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/theme/app_theme.dart';

class CustomerView extends StatefulWidget {
    final String bakiye;
  const CustomerView({super.key,required this.bakiye});


  @override
  State<CustomerView> createState() => _CustomerViewState();
}



class _CustomerViewState extends State<CustomerView> {
  // ✅ Double-click protection for navigation buttons
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
  }


Future<Map<String, dynamic>?> loadCustomerBalanceByName(String customerName, BuildContext context) async {
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');

  final db = await openReadOnlyDatabase(path);

  final result = await db.query(
    'CustomerBalance',
    where: 'unvan = ?',
    whereArgs: [customerName],
    limit: 1,
  );
  await db.close();

  if (result.isNotEmpty) {
    return result[0];
  } else {
    return null; // Belirtilen isimde müşteri yoksa
  }
}

  
  @override
  Widget build(BuildContext context) {
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;


    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: Text('customer_menu.no_customer_selected'.tr())),
        body: Center(child: Text('customer_menu.select_customer_first'.tr())),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('customer_menu.title'.tr()),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MenuView()),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Text(
            '${'customer_menu.balance_label'.tr()} £${widget.bakiye}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),

      body: Column(
        children: [
          // Customer Info Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(4.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'customer_menu.customer_label'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  customer.unvan ?? 'customers.unknown_customer'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              children: [
                _buildMenuItem(
                  context,
                  title: 'customer_menu.order'.tr(),
                  icon: Icons.shopping_cart_outlined,
                  onTap: () async {
                    // ✅ Double-click protection
                    if (_isNavigating) return;
                    setState(() => _isNavigating = true);

                    try {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InvoiceActivityView()),
                      );
                    } finally {
                      // ✅ Reset flag when returning from navigation
                      if (mounted) {
                        setState(() => _isNavigating = false);
                      }
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'customer_menu.collection'.tr(),
                  icon: Icons.payment_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CollectionActivity()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'customer_menu.return'.tr(),
                  icon: Icons.keyboard_return_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RefundActivityView()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'customer_menu.customer_detail'.tr(),
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerDetailView()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'customer_menu.statement'.tr(),
                  icon: Icons.description_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatementPdfView()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 4.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
