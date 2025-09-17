import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/models/customer_balance.dart';
import 'package:pos_app/models/customer_model.dart';
import 'package:pos_app/views/cart_view.dart';
import 'package:pos_app/views/collection_activity.dart';
import 'package:pos_app/views/customerdetail_view.dart';
import 'package:pos_app/views/invoice_activity.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:pos_app/views/refund_activity.dart';
import 'package:pos_app/views/refundlist2_view.dart';
import 'package:pos_app/views/sales_view.dart';
import 'package:pos_app/views/statement_view.dart';
import 'package:pos_app/views/transaction_view.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';

class CustomerView extends StatefulWidget {
    final String bakiye;
  const CustomerView({super.key,required this.bakiye});


  @override
  State<CustomerView> createState() => _CustomerViewState();
}



class _CustomerViewState extends State<CustomerView> {

  final controller = CustomerBalanceController();
  String? _bakiye;

  @override
  void initState() {
    super.initState();
  }


Future<CustomerBalanceModel?> loadCustomerBalanceByName(String customerName) async {
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');

  final db = await openReadOnlyDatabase(path);
  
  final result = await db.query(
    'CustomerBalance',
    where: 'unvan = ?',
    whereArgs: [customerName],
    limit: 1,
  );
print("DB CLOSE TIME 6");
  await db.close();

  if (result.isNotEmpty) {
    return CustomerBalanceModel(
      kod: result[0]['kod'] as String?,
      unvan: result[0]['unvan'] as String?,
      bakiye: result[0]['bakiye'] as String?,
    );
  } else {
    return null; // Belirtilen isimde müşteri yoksa
  }
}

  
  @override
  Widget build(BuildContext context) {
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;


    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("No Customer Selected")),
        body: const Center(child: Text("Please select a customer first.")),
      );
    }

    return Scaffold(
      bottomNavigationBar: Container(
        height: 10.h,
        width: 100.w,
  color: Colors.red,
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  child: Center(
    child: Text(
      "Balance: ${widget.bakiye} GBP",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.home),
    tooltip: 'Ana Menü',
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuView()),
      );
    },
  ),
  title: Text('CUSTOMER MENU', style: TextStyle(fontSize: 22.sp)),
  centerTitle: true,
),

      body: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sadece müşteri unvanı
            Text(
              'Customer: ${customer.unvan}',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),

            // Menü listesi
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(
                    context,
                    title: 'Order',
                    icon: Icons.shopping_cart,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InvoiceActivityView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Collection',
                    icon: Icons.monetization_on,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CollectionActivity()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Return',
                    icon: Icons.undo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RefundActivityView()),
                      );
                    },
                  ),_buildMenuItem(
                    context,
                    title: 'Customer Detail',
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CustomerDetailView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Statement',
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StatementScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Back to Customer List',
                    icon: Icons.arrow_back,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SalesView()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 24.sp),
        title: Text(title, style: TextStyle(fontSize: 18.sp)),
        onTap: onTap,
      ),
    );
  }
}
