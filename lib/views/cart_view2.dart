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
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart';

class CartView2 extends StatefulWidget {
  const CartView2({super.key});

  @override
  State<CartView2> createState() => _CartView2State();
}

class _CartView2State extends State<CartView2> {
  // Controller'ları her item için saklayacağız
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};

  @override
  void dispose() {
    // Controller'ları temizle
    _priceControllers.forEach((_, controller) => controller.dispose());
    _discountControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items.values.toList();

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
                              // Provider'ı temizle
                              cartProvider.clearCart();

                              // Controller'ları temizle
                              _priceControllers.forEach((_, controller) => controller.clear());
                              _discountControllers.forEach((_, controller) => controller.clear());
                              _priceControllers.clear();
                              _discountControllers.clear();

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

                          // Controller'ları başlat veya al
                          if (!_priceControllers.containsKey(stokKodu)) {
                            _priceControllers[stokKodu] = TextEditingController();
                          }
                          if (!_discountControllers.containsKey(stokKodu)) {
                            _discountControllers[stokKodu] = TextEditingController();
                          }

                          final priceController = _priceControllers[stokKodu]!;
                          final discountController = _discountControllers[stokKodu]!;

                          // İndirimli fiyatı hesapla
                          // birimFiyat zaten provider'da tutuluyor ve cart_view'dan geliyor
                          final discountAmount = (item.birimFiyat * item.iskonto) / 100;
                          final discountedPrice = item.birimFiyat - discountAmount;

                          // Güncel değerleri controller'lara yaz
                          priceController.text = discountedPrice.toStringAsFixed(2);
                          discountController.text = item.iskonto > 0 ? item.iskonto.toString() : '0';

                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(
                              horizontal: 0.5.w,
                              vertical: 0.5.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Sol: Ürün görseli
                                          item.imsrc == null
                                              ? Icon(Icons.shopping_bag_sharp, size: 25.w)
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

                                            // İlk satır: Dropdown | Fiyat
                                            Row(
                                              children: [
                                                // Dropdown (Unit/Box)
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: DropdownButton<String>(
                                                    value: item.birimTipi,
                                                    isDense: true,
                                                    underline: Container(),
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    items: ['Unit', 'Box'].map((value) {
                                                      return DropdownMenuItem(
                                                        value: value,
                                                        child: Text(value),
                                                      );
                                                    }).toList(),
                                                    onChanged: (newValue) {
                                                      if ((newValue == 'Unit' && item.adetFiyati != 0) ||
                                                          (newValue == 'Box' && item.kutuFiyati != "0")) {
                                                        final fiyatStr = (newValue == 'Unit') ? item.adetFiyati : item.kutuFiyati;
                                                        final fiyat = double.tryParse(fiyatStr.replaceAll(',', '.')) ?? 0.0;
                                                        final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                        cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                        cartProvider.addOrUpdateItem(
                                                          urunAdi: item.urunAdi,
                                                          stokKodu: item.stokKodu,
                                                          birimFiyat: fiyat,
                                                          urunBarcode: item.urunBarcode,
                                                          adetFiyati: item.adetFiyati,
                                                          kutuFiyati: item.kutuFiyati,
                                                          miktar: 0,
                                                          iskonto: item.iskonto,
                                                          birimTipi: newValue ?? "Box",
                                                          durum: item.durum,
                                                          vat: item.vat,
                                                          imsrc: item.imsrc,
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('⚠️ Unit type not available for this product.'),
                                                            behavior: SnackBarBehavior.floating,
                                                            backgroundColor: Colors.orange.shade700,
                                                            duration: Duration(seconds: 3),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),

                                                SizedBox(width: 2.w),

                                                // Fiyat alanı
                                                Expanded(
                                                  child: TextField(
                                                        controller: priceController,
                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                        decoration: InputDecoration(
                                                          filled: true,
                                                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide.none,
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide.none,
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide.none,
                                                          ),
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        onChanged: (value) {
                                                          final yeniFiyat = double.tryParse(value.replaceAll(',', '.'));
                                                          if (yeniFiyat != null && yeniFiyat >= 0) {
                                                            // Orjinal fiyatı al (birim tipine göre)
                                                            final orjinalFiyat = item.birimTipi == 'Unit'
                                                                ? double.tryParse(item.adetFiyati.toString()) ?? 0.0
                                                                : double.tryParse(item.kutuFiyati.toString()) ?? 0.0;

                                                            if (orjinalFiyat > 0) {
                                                              // İndirim yüzdesini hesapla
                                                              final indirimOrani = yeniFiyat < orjinalFiyat
                                                                  ? ((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100).round()
                                                                  : 0;

                                                              // İndirim controller'ını güncelle
                                                              discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';

                                                              // Provider'ı güncelle
                                                              final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                              cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                              cartProvider.addOrUpdateItem(
                                                                stokKodu: item.stokKodu,
                                                                urunAdi: item.urunAdi,
                                                                birimFiyat: orjinalFiyat,
                                                                urunBarcode: item.urunBarcode,
                                                                miktar: 0,
                                                                iskonto: indirimOrani,
                                                                birimTipi: item.birimTipi,
                                                                durum: item.durum,
                                                                vat: item.vat,
                                                                imsrc: item.imsrc,
                                                                adetFiyati: item.adetFiyati,
                                                                kutuFiyati: item.kutuFiyati,
                                                              );
                                                            }
                                                          }
                                                        },
                                                      ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 1.h),

                                            // İkinci satır: İndirim | Miktar kontrolleri
                                            Row(
                                              children: [
                                                // İndirim alanı
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.local_offer,
                                                        size: 18.sp,
                                                        color: Theme.of(context).colorScheme.error,
                                                      ),
                                                      SizedBox(width: 1.w),
                                                      Expanded(
                                                        child: TextField(
                                                          keyboardType: TextInputType.number,
                                                          controller: discountController,
                                                          decoration: InputDecoration(
                                                            prefixText: '%',
                                                            prefixStyle: TextStyle(
                                                              fontSize: 14.sp,
                                                              fontWeight: FontWeight.bold,
                                                              color: Theme.of(context).colorScheme.error,
                                                            ),
                                                            isDense: true,
                                                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                            filled: true,
                                                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                              borderSide: BorderSide.none,
                                                            ),
                                                          ),
                                                          onChanged: (value) {
                                                            // İndirim yüzdesini al ve sınırla
                                                            int discountPercent = int.tryParse(value) ?? 0;
                                                            discountPercent = discountPercent.clamp(0, 100);

                                                            // İmleç konumunu kaydet
                                                            final cursorPos = discountController.selection.baseOffset;

                                                            // Orjinal fiyatı al (birim tipine göre)
                                                            final originalPrice = item.birimTipi == 'Unit'
                                                                ? double.tryParse(item.adetFiyati.toString()) ?? 0.0
                                                                : double.tryParse(item.kutuFiyati.toString()) ?? 0.0;

                                                            // İndirim miktarını hesapla
                                                            final discountAmount = (originalPrice * discountPercent) / 100;

                                                            // İndirimli fiyatı hesapla
                                                            final discountedPrice = originalPrice - discountAmount;

                                                            // Fiyat controller'ını güncelle
                                                            priceController.text = discountedPrice.toStringAsFixed(2);

                                                            // Provider'ı güncelle
                                                            final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                            cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                            cartProvider.addOrUpdateItem(
                                                              urunAdi: item.urunAdi,
                                                              stokKodu: item.stokKodu,
                                                              birimFiyat: originalPrice,
                                                              urunBarcode: item.urunBarcode,
                                                              miktar: 0,
                                                              iskonto: discountPercent,
                                                              birimTipi: item.birimTipi,
                                                              durum: item.durum,
                                                              vat: item.vat,
                                                              imsrc: item.imsrc,
                                                              adetFiyati: item.adetFiyati,
                                                              kutuFiyati: item.kutuFiyati,
                                                            );

                                                            // İmleç pozisyonunu geri yükle
                                                            if (cursorPos >= 0 && cursorPos <= discountController.text.length) {
                                                              discountController.selection = TextSelection.fromPosition(
                                                                TextPosition(offset: cursorPos),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                SizedBox(width: 2.w),

                                                // Miktar kontrolleri (cart_view benzeri)
                                                Flexible(
                                                  flex: 3,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      // Miktar azaltma butonu (-)
                                                      Container(
                                                        width: 8.w,
                                                        height: 8.w,
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: IconButton(
                                                          padding: EdgeInsets.zero,
                                                          onPressed: () {
                                                            int newMiktar = item.miktar - 1;
                                                            if (newMiktar <= 0) {
                                                              cartProvider.removeItem(stokKodu);
                                                            } else {
                                                              final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                              cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
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
                                                          icon: Icon(
                                                            Icons.remove,
                                                            size: 4.w,
                                                            color: Theme.of(context).colorScheme.error,
                                                          ),
                                                        ),
                                                      ),

                                                      SizedBox(width: 1.w),

                                                      // Miktar TextField
                                                      Container(
                                                        width: 12.w,
                                                        height: 8.w,
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: TextField(
                                                          controller: TextEditingController(
                                                            text: "${Provider.of<CartProvider>(context, listen: true).items[stokKodu]?.miktar ?? 0}",
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                                          decoration: InputDecoration(
                                                            contentPadding: EdgeInsets.zero,
                                                            border: InputBorder.none,
                                                          ),
                                                          keyboardType: TextInputType.number,
                                                          onSubmitted: (value) {
                                                            final newMiktar = int.tryParse(value) ?? 0;
                                                            if (newMiktar <= 0) {
                                                              cartProvider.removeItem(stokKodu);
                                                            } else {
                                                              final difference = newMiktar - item.miktar;
                                                              if (difference != 0) {
                                                                final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                                cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                                cartProvider.addOrUpdateItem(
                                                                  urunAdi: item.urunAdi,
                                                                  stokKodu: stokKodu,
                                                                  birimFiyat: item.birimFiyat,
                                                                  urunBarcode: item.urunBarcode,
                                                                  miktar: difference,
                                                                  iskonto: item.iskonto,
                                                                  birimTipi: item.birimTipi,
                                                                  durum: item.durum,
                                                                  vat: item.vat,
                                                                  imsrc: item.imsrc,
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ),

                                                      SizedBox(width: 1.w),

                                                      // Miktar artırma butonu (+)
                                                      Container(
                                                        width: 8.w,
                                                        height: 8.w,
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: IconButton(
                                                          padding: EdgeInsets.zero,
                                                          onPressed: () {
                                                            final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                            cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
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
                                                          icon: Icon(
                                                            Icons.add,
                                                            size: 4.w,
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                      Divider(),
                                      Center(
                                        child: Text(
                                          'Final Price: ${item.indirimliTutar.toStringAsFixed(2)} - VAT:${item.vatTutari.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.sp,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                          DatabaseHelper dbHelper = DatabaseHelper();
                          final db = await dbHelper.database;

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

                          // Set customer name for saved cart
                          if (customer?.unvan != null) {
                            cartProvider.customerName = customer!.unvan!;
                          }

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

                          final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);

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

                            if (connectivityResult[0] ==
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
                            } else {
                              // 🌐 İnternet varsa doğrudan gönder
                              final apikey =
                                  Provider.of<UserProvider>(
                                    context,
                                    listen: false,
                                  ).apikey;

                              await orderController.satisGonder(
                                fisModel: fisModel,
                                satirlar: cartProvider.items.values.toList(),
                                bearerToken: apikey,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: SizedBox(
                                    height:
                                        10.h, // istediğin yüksekliği buraya ver
                                    child: Center(
                                      child: Text(
                                        'Order placed successfully!',
                                        style: TextStyle(
                                          fontSize:
                                              20.sp, // Burada metin büyüklüğünü ayarlayabilirsin
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              final cartString = cartProvider.items.values
                                  .map((item) => item.toFormattedString())
                                  .join('\n----------------------\n');

                              await RecentActivityController.addActivity(
                                "Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString",
                              );

                              cartProvider.items.clear();
                              cartProvider.clearCart();
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
