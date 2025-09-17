import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/controllers/order_controller.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:pos_app/models/order_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/providers/orderinfo_provider.dart';
import 'package:pos_app/providers/user_provider.dart';
import 'package:pos_app/views/customer_view.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class CartView2 extends StatefulWidget {
  const CartView2({super.key});

  @override
  State<CartView2> createState() => _CartView2State();
}

class _CartView2State extends State<CartView2> {
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items.values.toList();
    final orderInfoProvider = Provider.of<OrderInfoProvider>(
      context,
      listen: false,
    );

    final unitCount = cartItems
        .where((item) => item.birimTipi == 'Unit')
        .fold<int>(0, (prev, item) => prev + item.miktar);

    final boxCount = cartItems
        .where((item) => item.birimTipi == 'Box')
        .fold<int>(0, (prev, item) => prev + item.miktar);

    final totalCount = unitCount + boxCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Cart Details", style: TextStyle(fontSize: 20.sp)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              if (cartProvider.items.isNotEmpty) {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text("Clear Cart"),
                        content: const Text(
                          "Are you sure you want to remove all items?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              cartProvider.items.clear();
                              cartProvider.clearCart();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cart cleared.')),
                              );
                            },
                            child: const Text("Clear All"),
                          ),
                        ],
                      ),
                );
              }
            },
            tooltip: 'Clear All Items',
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(3.w),
        child:
            cartItems.isEmpty
                ? Center(
                  child: Text(
                    "Your cart is empty.",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final stokKodu = item.stokKodu;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 0.5.h),
                            child: Padding(
                              padding: EdgeInsets.all(2.w),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Ürün görseli
                                      item.imsrc == null
                                          ? Icon(Icons.shopping_bag, size: 16.w)
                                          : FutureBuilder<String?>(
                                            future: () async {
                                              try {
  final uri = Uri.parse(item.imsrc!);
  final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  if (fileName == null) return null;

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);

  return await file.exists() ? filePath : null;
} catch (e) {
  return null;
}

                                            }(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState !=
                                                  ConnectionState.done) {
                                                return SizedBox(
                                                  width: 16.w,
                                                  height: 16.w,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                );
                                              }
                                              if (!snapshot.hasData ||
                                                  snapshot.data == null) {
                                                return Icon(
                                                  Icons.shopping_bag,
                                                  size: 16.w,
                                                );
                                              }
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image.file(
                                                  File(snapshot.data!),
                                                  width: 16.w,
                                                  height: 16.w,
                                                  fit: BoxFit.cover,
                                                ),
                                              );
                                            },
                                          ),
                                      SizedBox(width: 3.w),

                                      // Sağ taraf
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Ürün Adı ve Sil Butonu
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.urunAdi,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16.sp,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => cartProvider
                                                          .removeItem(stokKodu),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                  iconSize: 2.2.h,
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 0.5.h),

                                            // Fiyat, iskonto, final fiyat
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Consumer<CartProvider>(
  builder: (context, cartProvider, child) {
    final item = cartProvider.items[stokKodu]!; // stokKodu dışarıdan alınıyor olmalı

    // final controller = TextEditingController(
    //   text:  (item.indirimliTutar-item.vatTutari-1).toStringAsFixed(0),
    // );

    return SizedBox(
      width: 80,
      child: TextField(
       // controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Original Price ${item.birimFiyat}',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {

    final yeniFiyat = double.tryParse(value.replaceAll(',', '.'));

    if (yeniFiyat != null && yeniFiyat >= 0) {
      final orjinalFiyat = item.birimFiyat;

      if (yeniFiyat < orjinalFiyat) {
        final indirimOrani =
            100 * (orjinalFiyat - yeniFiyat) / orjinalFiyat;

        cartProvider.addOrUpdateItem(
          stokKodu: item.stokKodu,
          urunAdi: item.urunAdi,
          birimFiyat: orjinalFiyat, // orijinal fiyatı koru
          urunBarcode: item.urunBarcode,
          miktar: 0,
          iskonto: indirimOrani.toInt(),
          birimTipi: item.birimTipi,
          durum: item.durum,
          vat: item.vat,
          imsrc: item.imsrc,
          adetFiyati: item.adetFiyati,
          kutuFiyati: item.kutuFiyati,
        );
      }

      // TextField içinde yine kullanıcının girdiği fiyat görünsün
      value = yeniFiyat.toStringAsFixed(2);
    }

          // final yeniFiyat = double.tryParse(value.replaceAll(',', '.'));
          // if (yeniFiyat != null && yeniFiyat >= 0) {
          //   cartProvider.addOrUpdateItem(
          //     stokKodu: item.stokKodu,
          //     urunAdi: item.urunAdi,
          //     birimFiyat: yeniFiyat,
          //     urunBarcode: item.urunBarcode,
          //     miktar: 0, // miktarı artırmak istemiyorsan 0 gönder
          //     iskonto: item.iskonto,
          //     birimTipi: item.birimTipi,
          //     durum: item.durum,
          //     vat: item.vat,
          //     imsrc: item.imsrc,
          //     adetFiyati: item.adetFiyati,
          //     kutuFiyati: item.kutuFiyati,
          //   );
          // }
        },
      ),
    );
  },
)

                                                ),
                                                SizedBox(width: 1.w),
                                                                                            Text("Vat: %${item.vat}"),

                                                //                   Icon(Icons.change_circle),
                                                //                   Expanded(
                                                //                     flex: 3,
                                                //                     child: TextField(
                                                //                       keyboardType:
                                                //                           TextInputType.numberWithOptions(
                                                //                             decimal: true,
                                                //                           ),
                                                //                       decoration: const InputDecoration(
                                                //                         labelText: 'Change Price',
                                                //                         border:
                                                //                             OutlineInputBorder(),
                                                //                         isDense: true,

                                                //                         contentPadding:
                                                //                             EdgeInsets.symmetric(
                                                //                               vertical: 8,
                                                //                               horizontal: 8,
                                                //                             ),
                                                //                       ),
                                                //                       onChanged: (value) {
                                                //                         final parsed =
                                                //                             double.tryParse(
                                                //                               value,
                                                //                             );
                                                //                         if (parsed != null) {
                                                //                            final customerProvider =
                                                // Provider.of<SalesCustomerProvider>(
                                                //   context,
                                                //   listen: false,
                                                // );
                                                //                           cartProvider.customerName = customerProvider.selectedCustomer!.kod!;

                                                //                           cartProvider.addOrUpdateItem(
                                                //                             urunAdi: item.urunAdi,
                                                //                             stokKodu:
                                                //                                 item.stokKodu,
                                                //                             birimFiyat: parsed,

                                                //                             urunBarcode:
                                                //                                 item.urunBarcode,
                                                //                             adetFiyati:
                                                //                                 item.adetFiyati,
                                                //                             kutuFiyati:
                                                //                                 item.kutuFiyati,
                                                //                             miktar: 0,
                                                //                             iskonto: item.iskonto,
                                                //                             birimTipi:
                                                //                                 item.birimTipi,
                                                //                             durum: item.durum,
                                                //                             vat: item.vat,imsrc: item.imsrc
                                                //                           );
                                                //                         }
                                                //                       },
                                                //                     ),
                                                //                   ),
                                              ],
                                            ),

                                            // Alt Satır: Miktar, Birim Tipi Dropdown, İskonto Alanı
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Miktar azalt/arttır

                                      // Dropdown (Unit/Box)
                                      Row(
                                        children: [
                                          Text(
                                            "Type: ",
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          DropdownButton<String>(
                                            value: item.birimTipi,
                                            items:
                                                ['Unit', 'Box'].map((value) {
                                                  return DropdownMenuItem(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                            onChanged: (newValue) {
  if ((newValue == 'Unit' &&
                                                        item.adetFiyati !=
                                                            0) ||
                                                    (newValue == 'Box' &&
                                                        item.kutuFiyati !=
                                                            "0")) {
    final fiyatStr =
        (newValue == 'Unit') ? item.adetFiyati : item.kutuFiyati;

    // Virgül varsa noktaya çevir, sonra double'a çevirmeyi dene
    final fiyat = double.tryParse(fiyatStr.replaceAll(',', '.')) ?? 0.0;

    final customerProvider =
        Provider.of<SalesCustomerProvider>(context, listen: false);
    cartProvider.customerName =
        customerProvider.selectedCustomer!.kod!;

    cartProvider.addOrUpdateItem(
      urunAdi: item.urunAdi,
      stokKodu: item.stokKodu,
      birimFiyat: fiyat,
      urunBarcode: item.urunBarcode,
      adetFiyati: item.adetFiyati,
      kutuFiyati: item.kutuFiyati,
      miktar: 0,
      iskonto: item.iskonto,
      birimTipi: newValue??"Box",
      durum: item.durum,
      vat: item.vat,
      imsrc: item.imsrc,
    );
  }else {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    '⚠️ Unit type not available for this product.',
                                                                  ),
                                                                  behavior:
                                                                      SnackBarBehavior
                                                                          .floating,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .orange
                                                                          .shade700,
                                                                  duration:
                                                                      Duration(
                                                                        seconds:
                                                                            3,
                                                                      ),
                                                                ),
                                                              );
                                                            }
},

                                          ),
                                        ],
                                      ),

                                      // İskonto TextField
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_offer,
                                            size: 20.sp,
                                            color: Colors.red,
                                          ),
                                          SizedBox(
                                            width: 70,
                                            child: TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              controller: TextEditingController(
                                                text: item.iskonto.toString(),
                                              ),
                                              onSubmitted: (value) {
                                                int parsed = 0;
                                                if (value.isNotEmpty) {
                                                  parsed =
                                                      int.tryParse(value) ?? 0;
                                                }
                                                final customerProvider =
                                                    Provider.of<
                                                      SalesCustomerProvider
                                                    >(context, listen: false);
                                                cartProvider.customerName =
                                                    customerProvider
                                                        .selectedCustomer!
                                                        .kod!;
                                                cartProvider.addOrUpdateItem(
                                                  urunAdi: item.urunAdi,
                                                  stokKodu: item.stokKodu,
                                                  birimFiyat: item.birimFiyat,
                                                  urunBarcode: item.urunBarcode,
                                                  miktar: 0,
                                                  iskonto: parsed,
                                                  birimTipi: item.birimTipi,
                                                  durum: item.durum,
                                                  vat: item.vat,
                                                  imsrc: item.imsrc,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove,
                                              size: 10.w,
                                            ),
                                            onPressed: () {
                                              int newMiktar = item.miktar - 1;
                                              if (newMiktar <= 0) {
                                                cartProvider.removeItem(
                                                  stokKodu,
                                                );
                                              } else {
                                                final customerProvider =
                                                    Provider.of<
                                                      SalesCustomerProvider
                                                    >(context, listen: false);
                                                cartProvider.customerName =
                                                    customerProvider
                                                        .selectedCustomer!
                                                        .kod!;
                                                cartProvider.addOrUpdateItem(
                                                  urunAdi: item.urunAdi,
                                                  stokKodu: stokKodu,
                                                  birimFiyat: item.birimFiyat,
                                                  urunBarcode: item.urunBarcode,
                                                  miktar: -1,
                                                  iskonto: item.iskonto,
                                                  birimTipi: item.birimTipi,
                                                  durum: item.durum,
                                                  vat: item.vat,
                                                  imsrc: item.imsrc,
                                                );
                                              }
                                            },
                                          ),
                                          Text(
                                            item.miktar.toString(),
                                            style: TextStyle(fontSize: 18.sp),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add, size: 10.w),
                                            onPressed: () {
                                              final customerProvider =
                                                  Provider.of<
                                                    SalesCustomerProvider
                                                  >(context, listen: false);
                                              cartProvider.customerName =
                                                  customerProvider
                                                      .selectedCustomer!
                                                      .kod!;
                                              cartProvider.addOrUpdateItem(
                                                urunAdi: item.urunAdi,
                                                stokKodu: stokKodu,
                                                birimFiyat: item.birimFiyat,
                                                urunBarcode: item.urunBarcode,
                                                miktar: 1,
                                                iskonto: item.iskonto,
                                                birimTipi: item.birimTipi,
                                                durum: item.durum,
                                                vat: item.vat,
                                                imsrc: item.imsrc,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Divider(),
                                  Text(
                                    'Final Price: ${item.indirimliTutar.toStringAsFixed(2)} - VAT:${item.vatTutari.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Units: $unitCount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                ),
                              ),
                              Text(
                                'Boxes: $boxCount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                ),
                              ),
                              Text(
                                'Total Items: $totalCount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total:",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${cartProvider.indirimsizToplamTutar.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total VAT:",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${cartProvider.toplamKdvTutari.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Discount",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "- ${cartProvider.toplamIndirimTutari.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Grand Total:",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${cartProvider.toplamTutar.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          var databasesPath = await getDatabasesPath();
                          String path = p.join(
                            databasesPath,
                            'pos_database.db',
                          );

                          final db = await openDatabase(
                            path,
                            version: 1,
                            onCreate: (db, version) async {
                              await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingSales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fis TEXT,
        satirlar TEXT
      )
    ''');
                            },
                            onOpen: (db) async {
                              await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingSales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fis TEXT,
        satirlar TEXT
      )
    ''');
                            },
                          );

                          final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                          final cartProvider = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          );
                          final customer = customerProvider.selectedCustomer;

                          if (customer == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a customer first.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (cartProvider.items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cart is empty!')),
                            );
                            return;
                          }

                          final fisModel = FisModel(
                            fisNo: orderInfoProvider.orderNo,
                            fistarihi: orderInfoProvider.paymentDate,
                            musteriId: customerProvider.selectedCustomer!.kod!,
                            toplamtutar: cartProvider.toplamTutar,
                            odemeTuru: orderInfoProvider.paymentType,
                            nakitOdeme: 0,
                            kartOdeme: 0,
                            status: "1",
                            deliveryDate: orderInfoProvider.deliveryDate,
                            comment: orderInfoProvider.comment,
                            // fisNo ve fistarihi OrderController içinde atanacak
                          );

                          final orderController = OrderController();

                          try {
                            // İnternet var mı kontrol et
                            final connectivityResult =
                                await Connectivity().checkConnectivity();

                            // Gerekli veriler
                            final fisJson = fisModel.toJson();
                            final satirlarJson =
                                cartProvider.items.values
                                    .map((item) => item.toJson())
                                    .toList();

                            if (true || connectivityResult[0] ==
                                ConnectivityResult.none) {
                              // 🌐 İnternet yoksa veritabanına kaydet

                              print("FİŞ JSON: ${jsonEncode(fisJson)}");
                              print(
                                "SATIRLAR JSON: ${jsonEncode(satirlarJson)}",
                              );

                              await db.insert('PendingSales', {
                                'fis': jsonEncode(fisJson),
                                'satirlar': jsonEncode(satirlarJson),
                              });

                              final cartString = cartProvider.items.values
                                  .map((item) => item.toFormattedString())
                                  .join('\n----------------------\n');

                              await RecentActivityController.addActivity(
                                "Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString",
                              );
  print("Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString");
                              cartProvider.items.clear();
                              cartProvider.clearCart();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: SizedBox(
                                    height: 10.h,
                                    child: Center(
                                      child: Text(
                                        'Order saved to Pending.',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              final selectedCustomer =
                                  Provider.of<SalesCustomerProvider>(
                                    context,
                                    listen: false,
                                  ).selectedCustomer;
                              final controller = CustomerBalanceController();
                              final customer = await controller
                                  .getCustomerByUnvan(
                                    selectedCustomer!.kod ?? "TURAN",
                                  );
                              String bakiye = customer?.bakiye ?? "0.0";
                              print("bakişyeee: $bakiye");
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => CustomerView(bakiye: bakiye),
                                ),
                                (route) => false,
                              );
                            } 
                            // else {
                            //   // 🌐 İnternet varsa doğrudan gönder
                            //   final apikey =
                            //       Provider.of<UserProvider>(
                            //         context,
                            //         listen: false,
                            //       ).apikey;

                            //   await orderController.satisGonder(
                            //     fisModel: fisModel,
                            //     satirlar: cartProvider.items.values.toList(),
                            //     bearerToken: apikey,
                            //   );

                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     SnackBar(
                            //       content: SizedBox(
                            //         height:
                            //             10.h, // istediğin yüksekliği buraya ver
                            //         child: Center(
                            //           child: Text(
                            //             'Order placed successfully!',
                            //             style: TextStyle(
                            //               fontSize:
                            //                   20.sp, // Burada metin büyüklüğünü ayarlayabilirsin
                            //               fontWeight: FontWeight.bold,
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   );
                            //   final cartString = cartProvider.items.values
                            //       .map((item) => item.toFormattedString())
                            //       .join('\n----------------------\n');

                            //   await RecentActivityController.addActivity(
                            //     "Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString",
                            //   );

                            //   cartProvider.items.clear();
                            //   cartProvider.clearCart();
                            //   final selectedCustomer =
                            //       Provider.of<SalesCustomerProvider>(
                            //         context,
                            //         listen: false,
                            //       ).selectedCustomer;
                            //   final controller = CustomerBalanceController();
                            //   final customer = await controller
                            //       .getCustomerByUnvan(
                            //         selectedCustomer!.kod ?? "TURAN",
                            //       );
                            //   String bakiye = customer?.bakiye ?? "0.0";
                            //   print("bakişyeee: $bakiye");
                            //   Navigator.of(context).pushAndRemoveUntil(
                            //     MaterialPageRoute(
                            //       builder: (_) => CustomerView(bakiye: bakiye),
                            //     ),
                            //     (route) => false,
                            //   );
                            // }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Order failed: $e')),
                            );
                          }
                        },

                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          child: Text(
                            "Place Order",
                            style: TextStyle(fontSize: 18.sp),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    const Divider(),
                  ],
                ),
      ),
    );
  }

  String generateFisNo(DateTime now) {
    final yy = now.year % 100; // Yılın son iki hanesi
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');

    final random = Random();
    final randomNumber = random
        .nextInt(1000)
        .toString()
        .padLeft(4, '0'); // 0000 - 9999

    return "MO$yy$mm$dd$randomNumber";
  }
}
