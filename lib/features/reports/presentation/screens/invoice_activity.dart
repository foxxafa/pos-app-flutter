import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/reports/presentation/screens/invoice2_activity.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/features/orders/presentation/providers/orderinfo_provider.dart';

class InvoiceActivityView extends StatefulWidget {
  const InvoiceActivityView({Key? key}) : super(key: key);

  @override
  State<InvoiceActivityView> createState() => _InvoiceActivityViewState();
}

class _InvoiceActivityViewState extends State<InvoiceActivityView> {
  List<String> _refundActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRefundActivities();
    });
  }

  Future<void> _loadRefundActivities() async {
    setState(() => _isLoading = true);

    final activityRepository = Provider.of<ActivityRepository>(context, listen: false);
    final allActivities = await activityRepository.loadActivities();
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _refundActivities = [];
        _isLoading = false;
      });
      return;
    }

    final filtered = allActivities.where((activity) {
      return activity.contains("Order") && activity.contains(customerCode!);
    }).toList();

    setState(() {
      _refundActivities = filtered;
      _isLoading = false;
    });
  }

  List<OrderItem> parseRefundActivities(List<String> activities) {
    List<OrderItem> orders = [];

    for (var activity in activities) {
      // Activity is multi-line string, parse it line by line
      final lines = activity.split('\n');

      String? orderNo;
      String? date;
      String? paymentType;
      String? total;

      for (var line in lines) {
        if (line.contains('Fiş No')) {
          orderNo = line.split(':').last.trim();
        } else if (line.contains('Fiş Tarihi')) {
          date = line.split(':').last.trim();
        } else if (line.contains('Ödeme Türü')) {
          paymentType = line.split(':').last.trim();
        } else if (line.contains('Toplam Tutar')) {
          total = line.split(':').last.trim();
        }
      }

      if (orderNo != null && date != null && paymentType != null && total != null) {
        orders.add(OrderItem(
          date: date,
          no: orderNo,
          type: paymentType,
          total: total,
        ));
      }
    }

    return orders;
  }

  Future<void> _loadOrder(OrderItem order) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'order.load_order'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('order.order_no'.tr(), order.no),
                  SizedBox(height: 0.5.h),
                  _buildInfoRow('order.price'.tr(), '£${order.total}'),
                  SizedBox(height: 0.5.h),
                  _buildInfoRow('order.date'.tr(), order.date),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'order.load_confirmation'.tr(),
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('common.continue'.tr()),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // ✅ Load ONLY from PendingSales (orders not yet synced to server)
    final rows = await db.query('PendingSales');
    Map<String, dynamic> fis = {};
    List<Map<String, dynamic>> satirlar = [];
    int? matchingId;

    for (var row in rows) {
      final rawFis = row['fis'];
      final fisJson = jsonDecode(rawFis.toString());
      if (fisJson['FisNo'] == order.no) {
        fis = fisJson;
        satirlar = List<Map<String, dynamic>>.from(
          jsonDecode(row['satirlar'].toString()),
        );
        matchingId = row['id'] as int?;
        break;
      }
    }

    if (satirlar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('order.no_matching_order'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ OPTIMIZATION: Query only products we need, not entire Product table
    final stokKodlari = satirlar
        .map((s) => s['StokKodu']?.toString() ?? '')
        .where((kod) => kod.isNotEmpty)
        .toList();

    final productRows = await db.query(
      'Product',
      where: 'stokKodu IN (${List.filled(stokKodlari.length, '?').join(',')})',
      whereArgs: stokKodlari,
    );

    // Create a map for faster lookup
    final productMap = <String, Map<String, dynamic>>{};
    for (var product in productRows) {
      final stokKodu = product['stokKodu']?.toString() ?? '';
      if (stokKodu.isNotEmpty) {
        productMap[stokKodu] = product;
      }
    }

    final provider = Provider.of<CartProvider>(context, listen: false);
    final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);
    final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

    // ✅ KRITIK: Load Order yaparken fisNo, customerKod set et
    final customerKod = fis['MusteriId']?.toString() ?? '';
    provider.fisNo = fis['FisNo']?.toString() ?? order.no;
    provider.customerKod = customerKod;

    // ✅ CustomerBalance'dan customer bilgisini çek
    String customerName = '';
    if (customerKod.isNotEmpty) {
      final customerRows = await db.query(
        'CustomerBalance',
        where: 'kod = ?',
        whereArgs: [customerKod],
      );

      if (customerRows.isNotEmpty) {
        customerName = customerRows.first['unvan']?.toString() ?? '';
      }
    }

    provider.customerName = customerName;

    // ✅ OrderInfoProvider'a da fisNo set et
    orderInfoProvider.orderNo = provider.fisNo;

    // ✅ Clear cart AFTER setting fisNo and customer info
    await provider.clearCart();

    print("DEBUG: Load Order - fisNo: ${provider.fisNo}, customerKod: ${provider.customerKod}, customerName: ${provider.customerName}");

    // ✅ OPTIMIZATION: Add all items in batch without triggering notifyListeners each time
    for (var s in satirlar) {
      final stokKodu = s['StokKodu']?.toString() ?? '';
      final product = productMap[stokKodu] ?? {};

      final double miktar = (s['Miktar'] is num)
          ? s['Miktar'].toDouble()
          : double.tryParse(s['Miktar'].toString()) ?? 0.0;
      final int miktarInt = miktar.round();

      final double birimFiyat = (s['BirimFiyat'] is num)
          ? s['BirimFiyat'].toDouble()
          : double.tryParse(s['BirimFiyat'].toString()) ?? 0.0;
      final int iskonto = (s['Iskonto'] is num)
          ? (s['Iskonto'] as num).round()
          : int.tryParse(s['Iskonto'].toString()) ?? 0;
      final int vat = (s['vat'] is num)
          ? (s['vat'] as num).round()
          : int.tryParse(s['vat'].toString()) ?? 18;
      final String birimTipi = s['BirimTipi']?.toString() ?? 'Box';

      provider.addOrUpdateItem(
        stokKodu: stokKodu,
        urunAdi: s['UrunAdi']?.toString() ?? '',
        birimFiyat: birimFiyat,
        urunBarcode: product['barcode1']?.toString() ?? '',
        miktar: miktarInt,
        iskonto: iskonto,
        birimTipi: birimTipi,
        vat: vat,
        durum: s['Durum'] ?? 1,
        imsrc: product['imsrc']?.toString(),
        adetFiyati: s['AdetFiyati']?.toString() ?? '',
        kutuFiyati: s['KutuFiyati']?.toString() ?? '',
      );
    }

    // ✅ KRITIK: Force immediate save to database after loading all items
    // This ensures the cart persists even if app is closed before debounce timer fires
    print("DEBUG: Load Order - Forcing immediate database save (${satirlar.length} items loaded)");
    await provider.forceSaveToDatabase();

    if (matchingId != null) {
      await db.delete('PendingSales', where: 'id = ?', whereArgs: [matchingId]);
    }

    final activityRepository = Provider.of<ActivityRepository>(context, listen: false);
    await activityRepository.removeActivityByOrderNo(order.no);

    // ✅ Navigate to cart screen (invoice2_activity)
    if (mounted) {
      // Find invoice2_activity import
      final route = MaterialPageRoute(
        builder: (_) => Invoice2Activity(),
      );

      // Pop current screen and push cart screen
      Navigator.of(context).pop();
      Navigator.of(context).push(route);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'order.products_loaded'.tr(args: [satirlar.length.toString()]),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    final theme = Theme.of(context);
    final isPositive = double.tryParse(order.total) != null && double.parse(order.total) >= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _loadOrder(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order number and date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightPrimaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: AppTheme.lightPrimaryColor,
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.no,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          Text(
                            order.date,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '£${double.parse(order.total).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: order.type == 'Nakit'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.type == 'Nakit' ? 'order.cash'.tr() : order.type,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: order.type == 'Nakit' ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsedOrders = parseRefundActivities(_refundActivities);

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('order.title'.tr()),
        backgroundColor: AppTheme.lightPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.lightPrimaryColor,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'messages.loading'.tr(),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            )
          : parsedOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 20.w,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'order.no_orders_found'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'order.create_new_order_hint'.tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRefundActivities,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: parsedOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(parsedOrders[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Invoice2Activity()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        child: Icon(
          Icons.add,
          size: 7.w,
          color: Colors.white,
        ),
      ),
    );
  }
}

class OrderItem {
  final String date;
  final String no;
  final String type;
  final String total;

  OrderItem({
    required this.date,
    required this.no,
    required this.type,
    required this.total,
  });
}