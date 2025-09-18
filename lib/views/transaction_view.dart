import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'package:path/path.dart' as p;
import 'package:pos_app/core/theme/app_theme.dart';

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
        SnackBar(content: Text('transaction.validation_message'.tr(), style: TextStyle(fontSize: 14.sp))),
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
      final path = p.join(await getDatabasesPath(), 'pos_database.db');
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
                'transaction.offline_message'.tr(),
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
                  'transaction.success_message'.tr(),
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
                  'transaction.error_message'.tr(),
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
    final theme = Theme.of(context);
    final selectedCustomer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('transaction.title'.tr()),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  // Document Number Card (moved to top)
                  _buildInfoCard(
                    title: 'transaction.document_no'.tr(),
                    content: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _documentNo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    isCompact: true,
                  ),

                  SizedBox(height: 1.h),

                  // Customer Card
                  _buildInfoCard(
                    title: 'transaction.customer'.tr(),
                    content: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                      child: Text(
                        selectedCustomer?.unvan ?? '-',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    isCompact: true,
                  ),

                  SizedBox(height: 1.h),

                  // Payment Method Selection Card
                  _buildInfoCard(
                    title: 'transaction.payment_method'.tr(),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPaymentOption('Cash', Icons.money, 'transaction.payment_methods.cash'.tr()),
                        _buildPaymentOption('Credit Card', Icons.credit_card, 'transaction.payment_methods.credit_card'.tr()),
                        _buildPaymentOption('Cheque', Icons.receipt_long, 'transaction.payment_methods.cheque'.tr()),
                        _buildPaymentOption('Bank', Icons.account_balance, 'transaction.payment_methods.bank'.tr()),
                      ],
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Amount Card
                  _buildInfoCard(
                    title: 'transaction.enter_amount'.tr(),
                    content: TextField(
                      controller: _tutarController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(2.w),
                        isDense: true,
                      ),
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Description Card with more lines
                  _buildInfoCard(
                    title: 'transaction.description'.tr(),
                    content: TextField(
                      controller: _aciklamaController,
                      maxLines: 4,
                      minLines: 4,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(2.w),
                        isDense: true,
                      ),
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Cheque Fields (if cheque is selected)
                  if (_selectedPaymentMethod == 'Cheque') ...[
                    _buildInfoCard(
                      title: 'transaction.cheque_no'.tr(),
                      content: TextField(
                        controller: _chequeNoController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(2.w),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildActionCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'transaction.choose_cheque_date'.tr(),
                      subtitle: dateFormat.format(_chequeExpiryDate),
                      onTap: () async {
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
                    ),
                    SizedBox(height: 1.h),
                  ],
                ],
              ),
            ),
          ),
          // Submit Button at absolute bottom
          Container(
            padding: EdgeInsets.only(left: 3.w, right: 3.w, top: 2.h, bottom: 5.h),
            child: Card(
              child: SizedBox(
                width: double.infinity,
                height: 6.h,
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: () => _sendTahsilat(_selectedPaymentMethod, context),
                        icon: Icon(Icons.send_outlined, size: 5.w),
                        label: Text(
                          'transaction.submit'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == value;

    return Flexible(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedPaymentMethod = value),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.5.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.05)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 7.w,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey[600],
                ),
                SizedBox(height: 0.8.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content, bool isCompact = false}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isCompact ? 0.5.h : 1.h),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
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