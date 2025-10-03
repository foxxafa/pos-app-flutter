import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';
import 'package:pos_app/core/sync/sync_service.dart';
import 'package:pos_app/features/orders/domain/entities/order_model.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/orders/presentation/providers/orderinfo_provider.dart';
import 'package:pos_app/features/customer/presentation/customer_view.dart';
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
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _priceFocusNodes = {};
  final Map<String, FocusNode> _discountFocusNodes = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};

  // Focus değişikliklerinde eski değerleri saklamak için
  final Map<String, String> _oldPriceValues = {};
  final Map<String, String> _oldDiscountValues = {};
  final Map<String, String> _oldQuantityValues = {};

  // Image cache sistemi
  Map<String, Future<String?>> _imageFutures = {};
  Timer? _imageDownloadTimer;

  void _clearUIState() {
    // Controller'ları temizle
    _priceControllers.forEach((_, controller) => controller.clear());
    _discountControllers.forEach((_, controller) => controller.clear());
    _priceControllers.clear();
    _discountControllers.clear();
    
    // Focus node'ları temizle
    _priceFocusNodes.clear();
    _discountFocusNodes.clear();
    
    // Image cache'ini temizle
    _imageFutures.clear();
    
    // Image download timer'ını iptal et
    _imageDownloadTimer?.cancel();
  }

  @override
  void dispose() {
    // Controller'ları dispose et
    _priceControllers.forEach((_, controller) => controller.dispose());
    _discountControllers.forEach((_, controller) => controller.dispose());
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _priceFocusNodes.forEach((_, node) => node.dispose());
    _discountFocusNodes.forEach((_, node) => node.dispose());
    _quantityFocusNodes.forEach((_, node) => node.dispose());
    _imageDownloadTimer?.cancel();
    super.dispose();
  }

  Future<String?> _loadImage(String? imsrc) async {
    try {
      if (imsrc == null || imsrc.isEmpty) {
        return null;
      }

      final uri = Uri.parse(imsrc);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

      if (fileName.isEmpty) {
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _generateImageFutures(List<CartItem> items, {bool forceUpdate = false}) {
    for (final item in items) {
      final stokKodu = item.stokKodu;
      if (!_imageFutures.containsKey(stokKodu) || forceUpdate) {
        _imageFutures[stokKodu] = _loadImage(item.imsrc);
      }
    }
  }

  void _downloadMissingImages(List<CartItem> items) {
    _imageDownloadTimer?.cancel();
    _imageDownloadTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        SyncService.downloadCartItemImages(items, onImagesDownloaded: () {
          if (mounted) {
            setState(() {
              _generateImageFutures(items, forceUpdate: true);
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items.values.toList();

    // Cache sistemi ve eksik resimleri indir
    _generateImageFutures(cartItems);
    _downloadMissingImages(cartItems);

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
                            onPressed: () async {
                              // Provider'ı temizle
                              await cartProvider.clearCart();

                              // UI state'ini de temizle
                              _clearUIState();
                              
                              // UI'yi yenile
                              setState(() {});

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
                          // Unique key: stokKodu + birimTipi (aynı ürünün farklı birimleri için)
                          final controllerKey = '${stokKodu}_${item.birimTipi}';

                          // Controller'ları başlat veya al
                          if (!_priceControllers.containsKey(controllerKey)) {
                            _priceControllers[controllerKey] = TextEditingController();
                            _priceFocusNodes[controllerKey] = FocusNode();

                            // Price focus listener ekle
                            _priceFocusNodes[controllerKey]!.addListener(() {
                              final focusNode = _priceFocusNodes[controllerKey]!;
                              final controller = _priceControllers[controllerKey]!;

                              if (focusNode.hasFocus) {
                                // Focus kazanıldığında eski değeri sakla ve temizle
                                _oldPriceValues[controllerKey] = controller.text;
                                controller.clear();
                              } else {
                                // Focus kaybedildiğinde, alan boşsa eski değeri geri yükle
                                if (controller.text.isEmpty && _oldPriceValues.containsKey(controllerKey)) {
                                  controller.text = _oldPriceValues[controllerKey]!;
                                }
                              }
                            });
                          }
                          if (!_discountControllers.containsKey(controllerKey)) {
                            _discountControllers[controllerKey] = TextEditingController();
                            _discountFocusNodes[controllerKey] = FocusNode();

                            // Discount focus listener ekle
                            _discountFocusNodes[controllerKey]!.addListener(() {
                              final focusNode = _discountFocusNodes[controllerKey]!;
                              final controller = _discountControllers[controllerKey]!;

                              if (focusNode.hasFocus) {
                                // Focus kazanıldığında eski değeri sakla ve temizle
                                _oldDiscountValues[controllerKey] = controller.text;
                                controller.clear();
                              } else {
                                // Focus kaybedildiğinde, alan boşsa eski değeri geri yükle
                                if (controller.text.isEmpty && _oldDiscountValues.containsKey(controllerKey)) {
                                  controller.text = _oldDiscountValues[controllerKey]!;
                                }
                              }
                            });
                          }
                          if (!_quantityControllers.containsKey(controllerKey)) {
                            _quantityControllers[controllerKey] = TextEditingController();
                            _quantityFocusNodes[controllerKey] = FocusNode();

                            // Quantity focus listener ekle
                            _quantityFocusNodes[controllerKey]!.addListener(() {
                              final focusNode = _quantityFocusNodes[controllerKey]!;
                              final controller = _quantityControllers[controllerKey]!;

                              if (focusNode.hasFocus) {
                                // Focus kazanıldığında eski değeri sakla ve temizle
                                _oldQuantityValues[controllerKey] = controller.text;
                                controller.clear();
                              } else {
                                // Focus kaybedildiğinde, alan boşsa eski değeri geri yükle
                                if (controller.text.isEmpty && _oldQuantityValues.containsKey(controllerKey)) {
                                  controller.text = _oldQuantityValues[controllerKey]!;
                                }
                              }
                            });
                          }

                          final priceController = _priceControllers[controllerKey]!;
                          final discountController = _discountControllers[controllerKey]!;
                          final quantityController = _quantityControllers[controllerKey]!;
                          final priceFocusNode = _priceFocusNodes[controllerKey]!;
                          final discountFocusNode = _discountFocusNodes[controllerKey]!;
                          final quantityFocusNode = _quantityFocusNodes[controllerKey]!;

                          // İlk kez oluşturuluyorsa controller'a ORJINAL fiyatı ata (indirim sonrası değil!)
                          if (priceController.text.isEmpty) {
                            priceController.text = item.birimFiyat.toStringAsFixed(2);
                          }
                          // İndirim controller'ını sadece ilk kez doldur, sonra kullanıcıya bırak
                          if (discountController.text.isEmpty && !discountFocusNode.hasFocus) {
                            discountController.text = item.iskonto > 0 ? item.iskonto.toString() : '';
                          }
                          // Quantity controller'ı her zaman güncelle (provider'dan gelen miktar değişebilir)
                          if (quantityController.text != item.miktar.toString()) {
                            quantityController.text = item.miktar.toString();
                          }

                          return Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.w),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Sol: Ürün görseli
                                          item.imsrc == null || item.imsrc!.isEmpty
                                              ? Icon(Icons.shopping_bag_sharp, size: 25.w)
                                              : FutureBuilder<String?>(
                                                future: _imageFutures[item.stokKodu],
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState !=
                                                  ConnectionState.done) {
                                                return SizedBox(
                                                  width: 30.w,
                                                  height: 30.w,
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
                                                  size: 25.w,
                                                );
                                              }
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image.file(
                                                  File(snapshot.data!),
                                                  width: 30.w,
                                                  height: 30.w,
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
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
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
                                                          .removeItem(stokKodu, item.birimTipi),
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
                                                              // Birim kontrolü - tek birim varsa text, birden fazla varsa dropdown
                                                              () {
                                                                // Mevcut birimleri kontrol et - akıllı kontrol
                                                                // Eğer ürün zaten bir birimle sepette varsa, o birim kesinlikle mevcuttur
                                                                final hasUnit = (item.birimTipi == 'Unit') || // Mevcut birim Unit ise Unit var demektir
                                                                    (item.birimKey1 > 0) || 
                                                                    (item.adetFiyati != "0" && 
                                                                     item.adetFiyati.isNotEmpty &&
                                                                     (double.tryParse(item.adetFiyati.toString().replaceAll(',', '.')) ?? 0) > 0);
                                                                final hasBox = (item.birimTipi == 'Box') || // Mevcut birim Box ise Box var demektir  
                                                                    (item.birimKey2 > 0) || 
                                                                    (item.kutuFiyati != "0" && 
                                                                     item.kutuFiyati.isNotEmpty &&
                                                                     (double.tryParse(item.kutuFiyati.toString().replaceAll(',', '.')) ?? 0) > 0);
                                                                
                                                                // Debug için
                                                                print("DEBUG - ${item.urunAdi}: birimTipi=${item.birimTipi}, hasUnit=$hasUnit (key1=${item.birimKey1}, fiyat=${item.adetFiyati}), hasBox=$hasBox (key2=${item.birimKey2}, fiyat=${item.kutuFiyati})");
                                                                final availableUnits = (hasUnit ? 1 : 0) + (hasBox ? 1 : 0);                                                  if (availableUnits == 1) {
                                                    // Tek birim varsa sadece text göster
                                                    return Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        item.birimTipi,
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          color: Theme.of(context).colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    // Birden fazla birim varsa dropdown göster
                                                    return Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: DropdownButton<String>(
                                                        value: (item.birimTipi == 'Unit' && hasUnit) || (item.birimTipi == 'Box' && hasBox) 
                                                            ? item.birimTipi 
                                                            : (hasUnit ? 'Unit' : (hasBox ? 'Box' : 'Unit')),
                                                        isDense: true,
                                                        underline: Container(),
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          color: Theme.of(context).colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        items: [
                                                          if (hasUnit)
                                                            DropdownMenuItem(
                                                              value: 'Unit',
                                                              child: Text('Unit'),
                                                            ),
                                                          if (hasBox)
                                                            DropdownMenuItem(
                                                              value: 'Box',
                                                              child: Text('Box'),
                                                            ),
                                                        ],
                                                        onChanged: (newValue) {
                                                          if (newValue != null) {
                                                            // Yeni birim tipinin fiyatını kontrol et
                                                            final fiyatStr = (newValue == 'Unit') ? item.adetFiyati : item.kutuFiyati;
                                                            final fiyat = double.tryParse(fiyatStr.replaceAll(',', '.')) ?? 0.0;
                                                            
                                                            print("DROPDOWN DEBUG - ${item.urunAdi}: ${newValue} seçildi, fiyatStr='$fiyatStr', fiyat=$fiyat");
                                                            
                                                            // Fiyat kontrolü - eğer 0 veya null ise hata göster
                                                            if (fiyat <= 0) {
                                                              print("DROPDOWN ERROR - ${newValue} fiyat hatası: $fiyat");
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('⚠️ ${newValue} fiyatı bulunamadı (${fiyat}).'),
                                                                  behavior: SnackBarBehavior.floating,
                                                                  backgroundColor: Colors.orange.shade700,
                                                                  duration: Duration(seconds: 3),
                                                                ),
                                                              );
                                                              return;
                                                            }
                                                            
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
                                                              birimTipi: newValue,
                                                              durum: item.durum,
                                                              vat: item.vat,
                                                              imsrc: item.imsrc,
                                                              birimKey1: item.birimKey1,
                                                              birimKey2: item.birimKey2,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  }
                                                }(),

                                                SizedBox(width: 2.w),

                                                // Fiyat alanı
                                                Expanded(
                                                  flex: 2,
                                                  child: TextField(
                                                        enabled: item.miktar > 0,
                                                        controller: priceController,
                                                        focusNode: priceFocusNode,
                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                        textAlign: TextAlign.center,
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
                                                          // Virgülü noktaya çevir
                                                          final cleanValue = value.replaceAll(',', '.');

                                                          final yeniFiyat = double.tryParse(cleanValue);
                                                          if (yeniFiyat != null && yeniFiyat >= 0) {
                                                            // Orjinal fiyatı al (birim tipine göre)
                                                            var orjinalFiyat = item.birimTipi == 'Unit'
                                                                ? double.tryParse(item.adetFiyati.toString()) ?? 0.0
                                                                : double.tryParse(item.kutuFiyati.toString()) ?? 0.0;

                                                            // Eğer orjinal fiyat 0 ise, yeni fiyatı orjinal fiyat olarak kabul et
                                                            if (orjinalFiyat <= 0) {
                                                              orjinalFiyat = yeniFiyat;
                                                            }

                                                            // İndirim yüzdesini hesapla
                                                            final indirimOrani = (orjinalFiyat > 0 && yeniFiyat < orjinalFiyat)
                                                                ? ((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100).round()
                                                                : 0;

                                                            // İndirim controller'ını güncelle - sadece focus değilse
                                                            if (!discountFocusNode.hasFocus) {
                                                              discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';
                                                            }

                                                            print("FIYAT DEBUG - yeniFiyat: $yeniFiyat, orjinalFiyat: $orjinalFiyat, indirimOrani: $indirimOrani");

                                                            // Provider'ı güncelle
                                                            final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                            cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                            cartProvider.addOrUpdateItem(
                                                              stokKodu: item.stokKodu,
                                                              urunAdi: item.urunAdi,
                                                              birimFiyat: orjinalFiyat, // Gerçek orjinal fiyatı kullan
                                                              urunBarcode: item.urunBarcode,
                                                              miktar: 0,
                                                              iskonto: indirimOrani,
                                                              birimTipi: item.birimTipi,
                                                              durum: item.durum,
                                                              vat: item.vat,
                                                              imsrc: item.imsrc,
                                                              adetFiyati: item.adetFiyati,
                                                              kutuFiyati: item.kutuFiyati,
                                                              birimKey1: item.birimKey1,
                                                              birimKey2: item.birimKey2,
                                                            );
                                                          }
                                                        },
                                                        onEditingComplete: () {
                                                          // Formatlama işlemi
                                                          final value = priceController.text;
                                                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                                                          if (parsed != null) {
                                                            final formattedValue = parsed.toStringAsFixed(2);
                                                            if (priceController.text != formattedValue) {
                                                              priceController.text = formattedValue;
                                                              priceController.selection = TextSelection.fromPosition(
                                                                TextPosition(offset: formattedValue.length),
                                                              );
                                                            }
                                                          }
                                                          priceFocusNode.unfocus();
                                                        },
                                                        onSubmitted: (value) {
                                                          // Submit edildiğinde formatlama işlemi
                                                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                                                          if (parsed != null) {
                                                            final formattedValue = parsed.toStringAsFixed(2);
                                                            priceController.text = formattedValue;
                                                          }
                                                          priceFocusNode.unfocus();
                                                        },
                                                      ),
                                                ),

                                                SizedBox(width: 2.w),

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
                                                          focusNode: discountFocusNode,
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
                                                            // İmleç konumunu kaydet
                                                            final cursorPos = discountController.selection.baseOffset;

                                                            // Eğer kullanıcı alanı boşaltmak istiyorsa, indirimi sıfırla
                                                            if (value.isEmpty) {
                                                              // Fiyatı orjinal fiyata döndür
                                                              priceController.text = item.birimFiyat.toStringAsFixed(2);
                                                              
                                                              // Provider'ı 0 indirim ile güncelle
                                                              final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                              cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                              cartProvider.addOrUpdateItem(
                                                                urunAdi: item.urunAdi,
                                                                stokKodu: item.stokKodu,
                                                                birimFiyat: item.birimFiyat, // Orjinal fiyatı kullan
                                                                urunBarcode: item.urunBarcode,
                                                                miktar: 0,
                                                                iskonto: 0, // İndirimi sıfırla
                                                                birimTipi: item.birimTipi,
                                                                durum: item.durum,
                                                                vat: item.vat,
                                                                imsrc: item.imsrc,
                                                                adetFiyati: item.adetFiyati,
                                                                kutuFiyati: item.kutuFiyati,
                                                                birimKey1: item.birimKey1,
                                                                birimKey2: item.birimKey2,
                                                              );
                                                              return;
                                                            }
                                                            
                                                            // İndirim yüzdesini al ve sınırla
                                                            int discountPercent = int.tryParse(value) ?? 0;
                                                            discountPercent = discountPercent.clamp(0, 100);

                                                            // Orjinal fiyat HER ZAMAN item'ın kendi birim fiyatıdır.
                                                            final originalPrice = item.birimFiyat;

                                                            // İndirim miktarını hesapla
                                                            final discountAmount = (originalPrice * discountPercent) / 100;

                                                            // İndirimli fiyatı hesapla  
                                                            final discountedPrice = originalPrice - discountAmount;

                                                            // Fiyat controller'ını güncelle
                                                            priceController.text = discountedPrice.toStringAsFixed(2);

                                                            print("İNDİRİM DEBUG - originalPrice: $originalPrice, discountPercent: $discountPercent, discountedPrice: $discountedPrice");

                                                            // Provider'ı güncelle
                                                            final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
                                                            cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
                                                            cartProvider.addOrUpdateItem(
                                                              urunAdi: item.urunAdi,
                                                              stokKodu: item.stokKodu,
                                                              birimFiyat: originalPrice, // Her zaman orjinal fiyatı gönder
                                                              urunBarcode: item.urunBarcode,
                                                              miktar: 0,
                                                              iskonto: discountPercent,
                                                              birimTipi: item.birimTipi,
                                                              durum: item.durum,
                                                              vat: item.vat,
                                                              imsrc: item.imsrc,
                                                              adetFiyati: item.adetFiyati,
                                                              kutuFiyati: item.kutuFiyati,
                                                              birimKey1: item.birimKey1,
                                                              birimKey2: item.birimKey2,
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
                                              ],
                                            ),

                                            SizedBox(height: 1.h),

                                            // İkinci satır: Miktar kontrolleri
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Miktar azaltma butonu (-)
                                                Container(
                                                  width: 12.w,
                                                  height: 8.w,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Center(
                                                    child: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        int newMiktar = item.miktar - 1;
                                                        if (newMiktar <= 0) {
                                                          cartProvider.removeItem(stokKodu, item.birimTipi);
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
                                                            adetFiyati: item.adetFiyati,
                                                            kutuFiyati: item.kutuFiyati,
                                                            birimKey1: item.birimKey1,
                                                            birimKey2: item.birimKey2,
                                                          );
                                                        }
                                                      },
                                                      icon: Icon(
                                                        Icons.remove,
                                                        size: 6.w,
                                                        color: Theme.of(context).colorScheme.error,
                                                      ),
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
                                                    controller: quantityController,
                                                    focusNode: quantityFocusNode,
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
                                                        cartProvider.removeItem(stokKodu, item.birimTipi);
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
                                                            adetFiyati: item.adetFiyati,
                                                            kutuFiyati: item.kutuFiyati,
                                                            birimKey1: item.birimKey1,
                                                            birimKey2: item.birimKey2,
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),

                                                SizedBox(width: 1.w),

                                                // Miktar artırma butonu (+)
                                                Container(
                                                  width: 12.w,
                                                  height: 8.w,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Center(
                                                    child: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
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
                                                          adetFiyati: item.adetFiyati,
                                                          kutuFiyati: item.kutuFiyati,
                                                          birimKey1: item.birimKey1,
                                                          birimKey2: item.birimKey2,
                                                        );
                                                      },
                                                      icon: Icon(
                                                        Icons.add,
                                                        size: 6.w,
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                    ),
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
                              // Divider ekliyoruz - son item değilse göster
                              if (index < cartItems.length - 1)
                                Divider(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                  thickness: 1,
                                  height: 1,
                                ),
                            ],
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

                          // final orderController = OrderController(); // İleride kullanılacak

                          try {
                            // Gerekli veriler
                            final fisJson = fisModel.toJson();
                            final satirlarJson =
                                cartProvider.items.values
                                    .map((item) => item.toJson())
                                    .toList();

                            // HER ZAMAN PendingSales'e kaydet (internet olsa bile)
                            // İleride sync butonuna basıldığında gönderilecek

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

                            final activityRepository = Provider.of<ActivityRepository>(context, listen: false);
                            await activityRepository.addActivity(
                              "Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString",
                            );
                            print("Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString");

                            await cartProvider.clearCart();
                            
                            // UI state'ini de temizle
                            _clearUIState();
                            
                            // UI'yi yenile
                            setState(() {});

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
                            final customerRepository = Provider.of<CustomerRepository>(
                              context,
                              listen: false,
                            );
                            final customer = await customerRepository
                                .getCustomerByUnvan(
                                  selectedCustomer!.kod ?? "TURAN",
                                );
                            String bakiye = customer?['bakiye']?.toString() ?? "0.0";
                            print("bakişyeee: $bakiye");
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => CustomerView(bakiye: bakiye),
                              ),
                              (route) => false,
                            );

                            // İLERİDE YAPILACAK: Otomatik gönderim
                            // if (connectivityResult[0] != ConnectivityResult.none) {
                            //   // İnternet varsa doğrudan gönder
                            //   final apikey = Provider.of<UserProvider>(
                            //     context,
                            //     listen: false,
                            //   ).apikey;
                            //
                            //   await orderController.satisGonder(
                            //     fisModel: fisModel,
                            //     satirlar: cartProvider.items.values.toList(),
                            //     bearerToken: apikey,
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
