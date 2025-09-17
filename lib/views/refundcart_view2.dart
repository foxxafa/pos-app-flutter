import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/controllers/order_controller.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:pos_app/controllers/refundsend_controller.dart';
import 'package:pos_app/models/order_model.dart';
import 'package:pos_app/models/refundsend_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/cart_provider_refund.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/providers/orderinfo_provider.dart';
import 'package:pos_app/views/customer_view.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class RefundCartView2 extends StatefulWidget {
  final RefundFisModel fisModel;
  const RefundCartView2({super.key, required this.fisModel});

  @override
  State<RefundCartView2> createState() => _RefundCartView2State();
}

class _RefundCartView2State extends State<RefundCartView2> {
  final TextEditingController _priceController = TextEditingController();

  void sendRefundItems(
    RefundFisModel fisModel,
    List<RefundItemModel> selectedItems,
  ) async {
    RefundSendModel refundSendModel = RefundSendModel(
      fis: fisModel,
      satirlar: selectedItems,
    );

    RefundSendController().sendRefund(refundSendModel);
  }

  List<String> _iadeNedenleri = [
    'Short Item',
    'Misdelivery (Useful)',
    'Refused (Useful)',
    'Other (Useful)',
    'Trial Returned (Useful)',
    'Short Dated (Useless)',
    'Price Difference',
    'Expired (Useless)',
    'Damaged (Useless)',
    'Faulty Pack (Useless)',
    'Others (Useless)',
    'Trial Returned (Useless)',
  ];

  void _showIadeNedeniSecimi(
    BuildContext context,
    String stokKodu,
    RCartProvider cartProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.h)),
      ),
      constraints: BoxConstraints(maxHeight: 28.h),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: 1.h,
              bottom: 2.h,
            ), // ekstra görünürlük için boşluk
            itemCount: _iadeNedenleri.length,
            itemBuilder: (context, index) {
              final neden = _iadeNedenleri[index];
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(neden, style: TextStyle(fontSize: 15.sp)),
                value: neden,
                groupValue: cartProvider.items[stokKodu]?.aciklama,
                onChanged: (value) {
                  if (value != null) {
                    cartProvider.updateAciklama(stokKodu, value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  List<RefundItemModel> convertCartToRefundItems(RCartProvider cartProvider) {
    return cartProvider.items.values.map((cartItem) {
      return RefundItemModel(
        stokKodu: cartItem.stokKodu,
        urunAdi: cartItem.urunAdi,
        miktar: cartItem.miktar,
        birimFiyat: cartItem.birimFiyat,
        toplamTutar: cartItem.indirimliTutar, // indirimliTutar var CartItem'da
        vat: cartItem.vat,
        birimTipi: cartItem.birimTipi,
        durum:
            cartItem.durum
                .toString(), // RefundItemModel'da durum String, burada int olduğu için toString ile çevirdim
        urunBarcode: cartItem.urunBarcode,
        iskonto: cartItem.iskonto,
        aciklama: cartItem.aciklama,
      );
    }).toList();
  }

  double toplamTutarFromRefundList(List<RefundItemModel> refundList) {
    return refundList.fold(0.0, (sum, item) => sum + item.toplamTutar);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<RCartProvider>(context);
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

                          return GestureDetector(
                            onDoubleTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    ///ALERT DIALOG DİALOG
                                    (context) => AlertDialog(
                                      title: Text(item.urunAdi ?? 'No name'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          item.imsrc == null
                                              ? Icon(
                                                Icons.shopping_bag,
                                                size: 40.w,
                                              )
                                              : FutureBuilder<String?>(
                                                future: () async {
                                                  try {
  final imsrc = item.imsrc;
  if (imsrc == null || imsrc.isEmpty) return null;

  final uri = Uri.parse(imsrc);
  final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  if (fileName == null) return null;

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$fileName';

  final file = File(filePath);
  if (await file.exists()) {
    return filePath;
  } else {
    return null;
  }
} catch (e) {
  return null;
}

                                                }(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState !=
                                                      ConnectionState.done) {
                                                    return SizedBox(
                                                      width: 20.w,
                                                      height: 20.w,
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
                                                      size: 40.w,
                                                    );
                                                  }
                                                  return Column(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        child: Image.file(
                                                          File(snapshot.data!),
                                                          width: 40.w,
                                                          height: 40.w,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                          SizedBox(height: 2.h),

                                          // Text("Barcodes: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}"),
                                          Consumer<RCartProvider>(
                                            builder: (
                                              context,
                                              cartProvider,
                                              child,
                                            ) {
                                              final item =
                                                  cartProvider.items[stokKodu];
                                              final currentAciklama =
                                                  item?.aciklama ?? '';

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item?.urunAdi ?? ''),
                                                  SizedBox(height: 4),
                                                  InkWell(
                                                    onTap: () {
                                                      _showIadeNedeniSecimi(
                                                        context,
                                                        stokKodu,
                                                        cartProvider,
                                                      );
                                                    },
                                                    child: InputDecorator(
                                                      decoration: InputDecoration(
                                                        labelText:
                                                            '(Enter Quantity First) Reason for return',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                      child: Text(
                                                        currentAciklama
                                                                .isNotEmpty
                                                            ? currentAciklama
                                                            : 'Seçiniz...',
                                                        style: TextStyle(
                                                          color:
                                                              currentAciklama
                                                                      .isNotEmpty
                                                                  ? Colors.black
                                                                  : Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),

                                          Text(
                                            "Unit Price: ${item.adetFiyati ?? '-'}",
                                          ),
                                          Text(
                                            "Box Price: ${item.kutuFiyati ?? '-'}",
                                          ),

                                          // Text("Active: ${product.aktif == 1 ? 'YES' : 'NO'}"),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Close'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Card(
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
                                            ? Icon(
                                              Icons.shopping_bag,
                                              size: 16.w,
                                            )
                                            : FutureBuilder<String?>(
                                              future: () async {
                                                try {
  final imsrc = item.imsrc;
  if (imsrc == null || imsrc.isEmpty) return null;

  final uri = Uri.parse(imsrc);
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
                                                            .removeItem(
                                                              stokKodu,
                                                            ),
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
                                                    child: Text(
                                                      'Price: ${item.birimFiyat.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 2.w),
                                                  // Icon(Icons.change_circle),
                                                  // Expanded(
                                                  //   flex: 3,
                                                  //   child: TextField(
                                                  //     keyboardType:
                                                  //         TextInputType.numberWithOptions(
                                                  //           decimal: true,
                                                  //         ),
                                                  //     decoration: const InputDecoration(
                                                  //       // labelText:
                                                  //       //     'Change Price',
                                                  //       border:
                                                  //           OutlineInputBorder(),
                                                  //       isDense: true,

                                                  //       contentPadding:
                                                  //           EdgeInsets.symmetric(
                                                  //             vertical: 8,
                                                  //             horizontal: 8,
                                                  //           ),
                                                  //     ),
                                                  //     onChanged: (value) {
                                                  //       final parsed =
                                                  //           double.tryParse(
                                                  //             value,
                                                  //           );
                                                  //       if (parsed != null) {
                                                  //         final customerProvider =
                                                  //             Provider.of<
                                                  //               SalesCustomerProvider
                                                  //             >(
                                                  //               context,
                                                  //               listen: false,
                                                  //             );
                                                  //         cartProvider
                                                  //                 .customerName =
                                                  //             customerProvider
                                                  //                 .selectedCustomer!
                                                  //                 .kod!;
                                                  //         cartProvider.addOrUpdateItem(
                                                  //           urunAdi:
                                                  //               item.urunAdi,
                                                  //           stokKodu:
                                                  //               item.stokKodu,
                                                  //           birimFiyat: parsed,

                                                  //           urunBarcode:
                                                  //               item.urunBarcode,
                                                  //           adetFiyati:
                                                  //               item.adetFiyati,
                                                  //           kutuFiyati:
                                                  //               item.kutuFiyati,
                                                  //           miktar: 0,
                                                  //           iskonto:
                                                  //               item.iskonto,
                                                  //           birimTipi:
                                                  //               item.birimTipi,
                                                  //           durum: item.durum,
                                                  //           vat: item.vat,
                                                  //           imsrc: item.imsrc,
                                                  //         );
                                                  //       }
                                                  //     },
                                                  //   ),
                                                  // ),
                                                ],
                                              ),

                                              SizedBox(height: 1.h),

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
                                                if (newValue != null) {
                                                  final fiyat =
                                                      (newValue == 'Unit')
                                                          ? double.parse(
                                                            item.adetFiyati,
                                                          )
                                                          : double.parse(
                                                            item.kutuFiyati,
                                                          );
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
                                                    birimFiyat: fiyat,
                                                    urunBarcode:
                                                        item.urunBarcode,
                                                    adetFiyati: item.adetFiyati,
                                                    kutuFiyati: item.kutuFiyati,
                                                    miktar: 0,
                                                    iskonto: item.iskonto,
                                                    birimTipi: newValue,
                                                    durum: item.durum,
                                                    vat: item.vat,
                                                    imsrc: item.imsrc,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),

                                        // İskonto TextField
                                        // Row(
                                        //   children: [
                                        //     Icon(
                                        //       Icons.local_offer,
                                        //       size: 20.sp,
                                        //       color: Colors.red,
                                        //     ),
                                        //     SizedBox(
                                        //       width: 70,
                                        //       child: TextField(
                                        //         keyboardType:
                                        //             TextInputType.number,
                                        //         decoration: InputDecoration(
                                        //           isDense: true,
                                        //           border: OutlineInputBorder(),
                                        //         ),
                                        //         controller:
                                        //             TextEditingController(
                                        //               text:
                                        //                   item.iskonto
                                        //                       .toString(),
                                        //             ),
                                        //         onSubmitted: (value) {
                                        //           int parsed = 0;
                                        //           if (value.isNotEmpty) {
                                        //             parsed =
                                        //                 int.tryParse(value) ??
                                        //                 0;
                                        //           }
                                        //           final customerProvider =
                                        //               Provider.of<
                                        //                 SalesCustomerProvider
                                        //               >(context, listen: false);
                                        //           cartProvider.customerName =
                                        //               customerProvider
                                        //                   .selectedCustomer!
                                        //                   .kod!;
                                        //           cartProvider.addOrUpdateItem(
                                        //             urunAdi: item.urunAdi,
                                        //             stokKodu: item.stokKodu,
                                        //             birimFiyat: item.birimFiyat,
                                        //             urunBarcode:
                                        //                 item.urunBarcode,
                                        //             miktar: 0,
                                        //             iskonto: parsed,
                                        //             birimTipi: item.birimTipi,
                                        //             durum: item.durum,
                                        //             vat: item.vat,
                                        //             imsrc: item.imsrc,
                                        //           );
                                        //         },
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
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
                                                    urunBarcode:
                                                        item.urunBarcode,
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
                                      'Final Price: ${item.indirimliTutar.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.sp,
                                        fontStyle: FontStyle.italic,
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
                                  fontSize: 18.sp,
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
                        child: Text("Return"),
                        onPressed: () async {
                          RefundFisModel fisModelCopy =
                              widget
                                  .fisModel; // final olmayan bir değişkene atama

                          List<RefundItemModel> refundList =
                              convertCartToRefundItems(cartProvider);
                          final toplamTutare = toplamTutarFromRefundList(
                            refundList,
                          );
                          print('Toplam Tutar: $toplamTutare');
                          fisModelCopy.toplamtutar = toplamTutare;
                          sendRefundItems(widget.fisModel, refundList);
                          cartProvider.items.clear();

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Returned')));

                          await RecentActivityController.addActivity(
                            "Return Receipt \n${fisModelCopy.toFormattedString()} \n${cartItems.map((item) => item.toFormattedString()).join('\n-----------------\n')}",
                          );

                          cartProvider.items.clear();
                          cartProvider.clearCart();

                          final selectedCustomer =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              ).selectedCustomer;
                          final controller = CustomerBalanceController();
                          final customer = await controller.getCustomerByUnvan(
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
                        },
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
