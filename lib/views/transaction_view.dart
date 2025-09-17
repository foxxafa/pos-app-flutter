import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:pos_app/controllers/transaction_controller.dart';
import 'package:pos_app/models/cheque_model.dart';
import 'package:pos_app/models/transaction_model.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/providers/user_provider.dart';
import 'package:pos_app/views/customer_view.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController _tutarController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _chequeNoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _chequeExpiryDate = DateTime.now();
  String _documentNo = '';
  bool _loading = false;
  String _selectedPaymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
_documentNo = 'MO${DateTime.now().millisecondsSinceEpoch.toString().padLeft(10, '0').substring(0, 10)}';
print("fisnooooooooo $_documentNo");
  }

  Future<void> _sendTahsilat(String method, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final carikod = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer?.kod;

    if (carikod == null || _tutarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter description and amount.", style: TextStyle(fontSize: 14.sp))),
      );
      return;
    }

    final tahsilat = TahsilatModel(          fisno: _documentNo,

      tutar: double.tryParse(_tutarController.text) ?? 0.0,
      aciklama: _aciklamaController.text,
      carikod: carikod,
      username: userProvider.username,
    );

        final tahsilatCheque = ChequeModel(
          fisno: _documentNo,
      tutar: double.tryParse(_tutarController.text) ?? 0.0,
      aciklama: _aciklamaController.text,
      carikod: carikod,
      username: userProvider.username,
      cekno: _chequeNoController.text,
      vade: _chequeExpiryDate.toIso8601String().substring(0, 10)
    );

    setState(() => _loading = true);

    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity[0] == ConnectivityResult.none) {
      final path = join(await getDatabasesPath(), 'pos_database.db');
      final db = await openDatabase(path, version: 1);
      var result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='tahsilatlar';");
      if (result.isEmpty) {
        await db.execute('''
          CREATE TABLE tahsilatlar (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT,
            method TEXT
          )
        ''');
      }

      if (_chequeNoController.text==null || _chequeNoController.text=='') {
  await db.insert('tahsilatlar', {
    'data': jsonEncode(tahsilat.toJson()),
    'method': method,
  });
}else{
    await db.insert('tahsilatlar', {
    'data': jsonEncode(tahsilatCheque.toJson()),
    'method': method,
  });
}

print("DB CLOSE TIME 12");
      await db.close();

      await RecentActivityController.addActivity("Collected \nCode:${tahsilat.carikod} \nAmount:${tahsilat.tutar} \nDesc:${tahsilat.aciklama}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SizedBox(
            height: 10.h,
            child: Center(
              child: Text(
                'No internet, order saved to Pending.',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    final selectedCustomer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
      final controller = CustomerBalanceController();
    final customer = await controller.getCustomerByUnvan(selectedCustomer!.kod??"TURAN");
      String bakiye = customer?.bakiye??"0.0";
print("bakişyeee: $bakiye");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CustomerView(bakiye: bakiye,)),
        (route) => false,
      );
    } else {
      final success = await TahsilatController().sendTahsilat(context, tahsilat, method, cheque_model: tahsilatCheque);

      if (success) {
        await RecentActivityController.addActivity("Collected \nCode:${tahsilat.carikod} \nAmount:${tahsilat.tutar} \nDesc:${tahsilat.aciklama}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SizedBox(
              height: 10.h,
              child: Center(
                child: Text(
                  'Transaction successful.',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
    final selectedCustomer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
      final controller = CustomerBalanceController();
    final customer = await controller.getCustomerByUnvan(selectedCustomer!.kod??"TURAN");
      String bakiye = customer?.bakiye??"0.0";
print("bakişyeee: $bakiye");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CustomerView(bakiye: bakiye,)),
          (route) => false,
        );

        _tutarController.clear();
        _aciklamaController.clear();
        _chequeNoController.clear();
      } else {
ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SizedBox(
              height: 10.h,
              child: Center(
                child: Text(
                  'Transaction error.',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );      }
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tutarController.dispose();
    _aciklamaController.dispose();
    _chequeNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCustomer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;

    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction", style: TextStyle(fontSize: 22.sp)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(6.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildPaymentOption('Cash', Icons.money, 'Cash'),
                  SizedBox(width: 5.w),
                  _buildPaymentOption('Credit Card', Icons.credit_card, 'Credit Card'),
                  SizedBox(width: 5.w),
                  _buildPaymentOption('Cheque', Icons.receipt_long, 'Cheque'),
                  SizedBox(width: 5.w),
                  _buildPaymentOption('Bank', Icons.account_balance, 'Bank'),
                ],
              ),

              SizedBox(height: 1.h),
              Text("Document No: $_documentNo", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 2.h),
              Text("Customer: ${selectedCustomer?.unvan ?? '-'}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),

              TextField(
                controller: _tutarController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(fontSize: 18.sp),
                decoration: InputDecoration(
                  labelText: "Enter Amount £",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),

              TextField(
                controller: _aciklamaController,
                style: TextStyle(fontSize: 18.sp),
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),

              if (_selectedPaymentMethod == 'Cheque') ...[
                TextField(
                  controller: _chequeNoController,
                  decoration: InputDecoration(
                    labelText: "Cheque No",
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 2.h),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _chequeExpiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _chequeExpiryDate = picked);
                    }
                  },
                  style: TextButton.styleFrom(
                    side: BorderSide(color: Colors.blue, width: 1.5),
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  ),
                  child: Text("Choose Cheque Date: ${_chequeExpiryDate.toLocal().toString().split(' ')[0]}", style: TextStyle(fontSize: 14.sp)),
                ),
              ],

              SizedBox(height: 3.h),
              if (_loading)
                Center(child: CircularProgressIndicator())
              else
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTahsilat(_selectedPaymentMethod, context),
                    icon: Icon(Icons.send, size: 18.sp),
                    label: Text("SUBMIT", style: TextStyle(fontSize: 16.sp)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, IconData icon, String label) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _selectedPaymentMethod,
            onChanged: (val) {
              setState(() => _selectedPaymentMethod = val!);
            },
          ),
          Icon(icon, size: 18.sp),
          Text(label, style: TextStyle(fontSize: 14.sp)),
        ],
      ),
    );
  }
}
