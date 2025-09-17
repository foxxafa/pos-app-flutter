import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/views/cart_view.dart';
import 'package:pos_app/views/expandabletext_widget.dart';
import 'package:pos_app/views/invoice2_activity.dart';
import 'package:pos_app/views/refundlist2_view.dart';
import 'package:pos_app/views/sale_edit_page.dart'; // EKLENDİ
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:path/path.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:sqflite/sqflite.dart';

class InvoiceActivityView extends StatefulWidget {
  const InvoiceActivityView({Key? key}) : super(key: key);

  @override
  State<InvoiceActivityView> createState() => _InvoiceActivityViewState();
}

class _InvoiceActivityViewState extends State<InvoiceActivityView> {
  List<String> _refundActivities = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadRefundActivities(BuildContext context) async {
    final allActivities = await RecentActivityController.loadActivities();
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _refundActivities = [];
      });
      return;
    }

    final filtered = allActivities.where((activity) {
      return activity.contains("Order") && activity.contains("$customerCode");
    }).toList();

    setState(() {
      _refundActivities = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    _loadRefundActivities(context);
    final parsedOrders = parseRefundActivities(_refundActivities);

    return Scaffold(
      appBar: AppBar(title: const Text("-Order-")),
      body: Padding(
        padding: EdgeInsets.all(3.h),
        child: Column(
          children: [
            Expanded(
              child: parsedOrders.isEmpty
                  ? Center(child: Text("No orders found.", style: TextStyle(fontSize: 18.sp)))
                  : Column(
                      children: [
                        // Başlık
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                          color: Colors.grey.shade300,
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 3, child: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        Divider(height: 1),

                        // Satırlar
                        Expanded(
                          child: ListView.separated(
                            itemCount: parsedOrders.length,
                            separatorBuilder: (_, __) => Divider(height: 1),
                            itemBuilder: (context, index) {
                              final order = parsedOrders[index];
                              final cleanedTotal = double.parse(order.total).toStringAsFixed(2);

                              return Container(
                                height: 10.h,
                                child: InkWell(
                                  onTap: () async {
                                    final shouldProceed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text("Load this order? \n \nNO: ${order.no} \nPrice: ${order.total} \nDate: ${order.date}"),
                                        content: Text(
                                            "The current cart will be cleared, this pending order deleted and products from this order will be loaded. \n\nDo you want to continue?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text("Continue"),
                                          ),
                                        ],
                                      ),
                                    );
                                
                                    if (shouldProceed != true) return;
                                
                                    final dbPath = await getDatabasesPath();
                                    final path = join(dbPath, 'pos_database.db');
                                    final db = await openDatabase(path);
                                
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
                                        SnackBar(content: Text("No matching order found.")),
                                      );
                                      return;
                                    }
                                
                                    final productRows = await db.query('Product');
                                
                                    final provider = Provider.of<CartProvider>(context, listen: false);
                                    provider.clearCart();
                                    provider.customerName = fis['CariUnvan'] ?? '';
                                
                                    for (var s in satirlar) {
                                      final stokKodu = s['StokKodu']?.toString() ?? '';
                                      final product = productRows.firstWhere(
                                        (p) => p['stokKodu'] == stokKodu,
                                        orElse: () => {},
                                      );
                                
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
                                
                                    if (matchingId != null) {
                                      await db.delete('PendingSales', where: 'id = ?', whereArgs: [matchingId]);
                                    }
                                
                                    await RecentActivityController.removeActivityByOrderNo(order.no);
                                
                                
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "${satirlar.length} product(s) loaded into cart and saved order has been removed.",
                                        ),
                                      ),
                                    );
                                  },
                                
                                
                                    
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (_) => SaleEditPage(
                                    //       orderNo: order.no, // gerekiyorsa parametre
                                    //     ),
                                    //   ),
                                    // );
                                  
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(order.date)),
                                        Expanded(flex: 3, child: Text(order.no)),
                                        Expanded(
                                          flex: 1,
                                          child: Text(order.type == 'Nakit' ? 'Cash' : order.type,style: TextStyle(fontSize: 13.sp)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            cleanedTotal,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 20.w,
        height: 20.w,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => Invoice2Activity()));
          },
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(
            Icons.add,
            size: 10.w,
          ),
        ),
      ),
    );
  }
}
