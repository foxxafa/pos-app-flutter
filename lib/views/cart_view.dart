import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/controllers/refundlist_controller.dart';
import 'package:pos_app/models/refundlist_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/views/cart_view2.dart';
import 'package:pos_app/views/cartsuggestion_view.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/controllers/database_helper.dart';
import 'package:sizer/sizer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product_model.dart';
import '../providers/cartcustomer_provider.dart';
import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class CartView extends StatefulWidget {
  final List<String> refundProductNames;
  final List<Refund> refunds;
  const CartView({
    super.key,
    required this.refundProductNames,

    required this.refunds,
  });

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _barcodeFocusNode2 = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  void onBarcodeScanned(String scannedValue) {
    //_barcodeFocusNode.requestFocus();
    _searchController.text = scannedValue;
  }

  String _scannerBuffer = '';

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  final TextEditingController _iskontoController = TextEditingController();
  bool _isLoading = true;

  final Map<String, bool> _isBoxMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, int> _iskontoMap = {};

  @override
  void initState() {
    super.initState();
    print("sasssss ${widget.refunds}");
    print("sasssss ${widget.refundProductNames}");

    _loadProducts();
    //_searchController.addListener(_filterProducts);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playWrong() async {
    await _audioPlayer.play(AssetSource('wrong.mp3'));
  }

  void _generateImageFutures(List<ProductModel> products) {
    for (final product in products) {
      final stokKodu = product.stokKodu ?? '';
      if (!_imageFutures.containsKey(stokKodu)) {
        _imageFutures[stokKodu] = _loadImage(product.imsrc);
      }
    }
  }

  Future<String?> _loadImage(String? imsrc) async {
    try {
      if (imsrc == null || imsrc.isEmpty) return null;

      final uri = Uri.parse(imsrc);
      final fileName =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;

      if (fileName == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadProducts() async {
    final raw = await DatabaseHelper().getAll("Product");
    final products = raw.map((e) => ProductModel.fromMap(e)).toList();

    // Tüm ürünleri al, sonra sıralayıp ilk 50 tanesini göster
    final sortedFiltered =
        products.toList()..sort((a, b) {
          final nameA = a.urunAdi ?? '';
          final nameB = b.urunAdi ?? '';

          final startsWithLetterA = RegExp(
            r'^[a-zA-ZğüşöçİĞÜŞÖÇ]',
          ).hasMatch(nameA);
          final startsWithLetterB = RegExp(
            r'^[a-zA-ZğüşöçİĞÜŞÖÇ]',
          ).hasMatch(nameB);

          if (startsWithLetterA && !startsWithLetterB) return -1;
          if (!startsWithLetterA && startsWithLetterB) return 1;

          return nameA.compareTo(nameB);
        });

    setState(() {
      _allProducts = products;
      _filteredProducts = sortedFiltered.take(50).toList();

      for (var product in products) {
        final key = product.stokKodu ?? '';
        // Box varsa varsayılan olarak Box seçili gelsin
        _isBoxMap[key] = product.birimKey2 != "0" ? true : false;
        _quantityMap[key] = 0;
        _iskontoMap[key] = 0;
      }
      // Gösterilen tüm ürünler için resim yükle
      _generateImageFutures(_filteredProducts);
      _isLoading = false;
    });
  }

  void _filterProducts2({bool isFromBarcodeScan = false}) {
    print("FİLTER STARTEDDDDDD");
    final provider = Provider.of<CartProvider>(context, listen: false);

    final query = _searchController2.text.trimRight().toLowerCase();
    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();

    final filtered =
        _allProducts.where((product) {
          final name = product.urunAdi?.toLowerCase() ?? '';
          final barcodes =
              [
                product.barcode1,
                product.barcode2,
                product.barcode3,
                product.barcode4,
              ].where((b) => b != null).map((b) => b!.toLowerCase()).toList();

          final matchesAllWords = queryWords.every((word) {
            final inName = name.contains(word);
            final inBarcodes = barcodes.any((b) => b.contains(word));
            return inName || inBarcodes;
          });

          return matchesAllWords;
        }).toList();

    // 🔤 Alfabetik sırala, özel karakterle başlayanlar en sona
    filtered.sort((a, b) {
      final aName = a.urunAdi ?? '';
      final bName = b.urunAdi ?? '';

      final aStartsWithLetter = RegExp(
        r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]',
      ).hasMatch(aName);
      final bStartsWithLetter = RegExp(
        r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]',
      ).hasMatch(bName);

      if (aStartsWithLetter && !bStartsWithLetter) return -1;
      if (!aStartsWithLetter && bStartsWithLetter) return 1;

      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    setState(() {
      _filteredProducts = filtered.take(50).toList();
      _generateImageFutures(_filteredProducts);
    });

    if (_filteredProducts.length == 1 &&
        RegExp(r'^\d+$').hasMatch(_searchController2.text)) {
      final product = _filteredProducts.first;
      final key = product.stokKodu ?? 'unknown';
      final isBox = provider.getBirimTipi(key) == 'Box';

      if ((provider.getBirimTipi(product.stokKodu) == 'Unit' &&
              product.birimKey1 != 0) ||
          (provider.getBirimTipi(product.stokKodu) == 'Box' &&
              product.birimKey2 != "0")) {
        provider.addOrUpdateItem(
          urunAdi: product.urunAdi,
          adetFiyati: product.adetFiyati,
          kutuFiyati: product.kutuFiyati,
          stokKodu: key,
          vat: product.vat,
          birimFiyat:
              isBox
                  ? double.tryParse(product.kutuFiyati.toString()) ?? 0
                  : double.tryParse(product.adetFiyati.toString()) ?? 0,
          imsrc: product.imsrc,
          urunBarcode: product.barcode1 ?? '',
          miktar: 1,
          iskonto: _iskontoMap[key] ?? 0,
          birimTipi: provider.getBirimTipi(product.stokKodu),
        );
      } else {}

      _searchController2.clear();
      FocusScope.of(context).unfocus();
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _barcodeFocusNode.requestFocus();
      });
    }

    if (_filteredProducts.length == 0 &&
        _searchController2.text.length > 10 &&
        RegExp(r'^\d+$').hasMatch(_searchController2.text)) {
      playWrong();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Container(
      //       padding: const EdgeInsets.symmetric(
      //         vertical: 24,
      //       ), // yüksekliği artırır
      //       child: Text(
      //         "No product found with this barcode.",
      //         style: TextStyle(fontSize: 16),
      //       ),
      //     ),
      //     behavior: SnackBarBehavior.floating, // ekranın üstüne çıkmasın
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     backgroundColor: Colors.red.shade600,
      //     duration: Duration(seconds: 2),
      //   ),
      // );

      _searchController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
        Future.delayed(Duration(milliseconds: 500), () {
          _searchController.clear();

          if (mounted) _barcodeFocusNode.requestFocus();
        });
      }
    }
  }

  bool redscan = false;
  void _filterProducts({bool isFromBarcodeScan = false}) {
    print("FİLTER STARTEDDDDDD");
    final provider = Provider.of<CartProvider>(context, listen: false);

    final query = _searchController.text.trimRight().toLowerCase();
    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();

    final filtered =
        _allProducts.where((product) {
          final name = product.urunAdi?.toLowerCase() ?? '';
          final barcodes =
              [
                product.barcode1,
                product.barcode2,
                product.barcode3,
                product.barcode4,
              ].where((b) => b != null).map((b) => b!.toLowerCase()).toList();

          final matchesAllWords = queryWords.every((word) {
            final inName = name.contains(word);
            final inBarcodes = barcodes.any((b) => b.contains(word));
            return inName || inBarcodes;
          });

          return matchesAllWords;
        }).toList();

    // 🔤 Alfabetik sırala, özel karakterle başlayanlar en sona
    filtered.sort((a, b) {
      final aName = a.urunAdi ?? '';
      final bName = b.urunAdi ?? '';

      final aStartsWithLetter = RegExp(
        r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]',
      ).hasMatch(aName);
      final bStartsWithLetter = RegExp(
        r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]',
      ).hasMatch(bName);

      if (aStartsWithLetter && !bStartsWithLetter) return -1;
      if (!aStartsWithLetter && bStartsWithLetter) return 1;

      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    setState(() {
      _filteredProducts = filtered.take(50).toList();
      _generateImageFutures(_filteredProducts);
    });

    if (_filteredProducts.length == 1 &&
        RegExp(r'^\d+$').hasMatch(_searchController.text)) {
      final product = _filteredProducts.first;
      final key = product.stokKodu ?? 'unknown';
      final isBox = provider.getBirimTipi(key) == 'Box';

      if ((provider.getBirimTipi(product.stokKodu) == 'Unit' &&
              product.birimKey1 != 0) ||
          (provider.getBirimTipi(product.stokKodu) == 'Box' &&
              product.birimKey2 != "0")) {
        provider.addOrUpdateItem(
          urunAdi: product.urunAdi,
          adetFiyati: product.adetFiyati,
          kutuFiyati: product.kutuFiyati,
          stokKodu: key,
          vat: product.vat,
          birimFiyat:
              isBox
                  ? double.tryParse(product.kutuFiyati.toString()) ?? 0
                  : double.tryParse(product.adetFiyati.toString()) ?? 0,
          imsrc: product.imsrc,
          urunBarcode: product.barcode1 ?? '',
          miktar: 1,
          iskonto: _iskontoMap[key] ?? 0,
          birimTipi: provider.getBirimTipi(product.stokKodu),
        );
      } else {}
      
      //_searchController2.clear(); burayı dene 

      _searchController.clear();
      FocusScope.of(context).unfocus();
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _barcodeFocusNode.requestFocus();
      });
    }

    if (_filteredProducts.length == 0 &&
        _searchController.text.length > 10 &&
        RegExp(r'^\d+$').hasMatch(_searchController.text)) {
      playWrong();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Container(
      //       padding: const EdgeInsets.symmetric(
      //         vertical: 24,
      //       ), // yüksekliği artırır
      //       child: Text(
      //         "No product found with this barcode.",
      //         style: TextStyle(fontSize: 16),
      //       ),
      //     ),
      //     behavior: SnackBarBehavior.floating, // ekranın üstüne çıkmasın
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     backgroundColor: Colors.red.shade600,
      //     duration: Duration(seconds: 2),
      //   ),
      // );

      _searchController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
        Future.delayed(Duration(milliseconds: 500), () {
          _searchController.clear();
          if (mounted) _barcodeFocusNode.requestFocus();
        });
      }
    }
  }

  // void _filterProducts() {

  //   final provider = Provider.of<CartProvider>(context, listen: false);

  //   final query = _searchController.text.trimRight().toLowerCase();

  //   final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();

  //   final filtered =
  //       _allProducts.where((product) {
  //         final name = product.urunAdi?.toLowerCase() ?? '';
  //         final barcodes =
  //             [
  //               product.barcode1,
  //               product.barcode2,
  //               product.barcode3,
  //               product.barcode4,
  //             ].where((b) => b != null).map((b) => b!.toLowerCase()).toList();

  //         // Her kelimenin, ürün adı veya barkodlardan en az birinde geçip geçmediğini kontrol et
  //         final matchesAllWords = queryWords.every((word) {
  //           final inName = name.contains(word);
  //           final inBarcodes = barcodes.any((b) => b.contains(word));
  //           return inName || inBarcodes;
  //         });

  //         return matchesAllWords;
  //       }).toList();

  //   setState(() {
  //     _filteredProducts = filtered.take(50).toList();

  //       // Sadece 1 ürün varsa otomatik sepete ekle
  // if (_filteredProducts.length == 1) {
  //   final product = _filteredProducts.first;
  //   final key = product.stokKodu ?? 'unknown';
  //   final isBox = provider.getBirimTipi(key) == 'Box';

  //   provider.addOrUpdateItem(
  //     urunAdi: product.urunAdi,
  //     adetFiyati: product.adetFiyati,
  //     kutuFiyati: product.kutuFiyati,
  //     stokKodu: key,
  //     vat: product.vat,
  //     birimFiyat: isBox
  //         ? double.tryParse(product.kutuFiyati.toString()) ?? 0
  //         : double.tryParse(product.adetFiyati.toString()) ?? 0,
  //     imsrc: product.imsrc,
  //     urunBarcode: product.barcode1 ?? '',
  //     miktar: 1,
  //     iskonto: _iskontoMap[key] ?? 0,
  //     birimTipi: provider.getBirimTipi(product.stokKodu),
  //   );
  // }

  //     _generateImageFutures(_filteredProducts);
  //   });
  // }

  void _clearSearch() {
    _searchController.clear();
    _filterProducts();
  }

  void _clearSearch2() {
    _searchController2.clear();
    _filterProducts2();
  }

  void _onBarcodeScanned(String barcode) {
    _searchController.text = barcode;
    print("buradaki filter");
    _filterProducts(isFromBarcodeScan: true);
    // Navigator.of(context).pop(); // Kamera sayfasını kapat
  }

  Future<void> _openBarcodeScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(onScanned: _onBarcodeScanned),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CartProvider>(context, listen: true);
    final customer =
        Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    String musteriId = customer?.kod ?? "";

    final cartItems = provider.items.values.toList();

    final unitCount = cartItems
        .where((item) => item.birimTipi == 'Unit')
        .fold<int>(0, (prev, item) => prev + item.miktar);

    final boxCount = cartItems
        .where((item) => item.birimTipi == 'Box')
        .fold<int>(0, (prev, item) => prev + item.miktar);

    return WillPopScope(
      onWillPop: () async {
        //   Provider.of<CartProvider>(context, listen: false).clearCart();
        return true; // sayfanın geri gitmesine izin ver
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.menu, size: 25.sp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CartsuggestionView(musteriId: musteriId),
                ),
              );
            },
          ),
          title: Container(
            height: 40,
            child: TextField(
              focusNode: _barcodeFocusNode2,
              controller: _searchController2,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'cart.search_placeholder'.tr(),
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController2.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: _clearSearch2,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          maxWidth: 40,
                          maxHeight: 40,
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white.withOpacity(0.9),
                        size: 22,
                      ),
                      onPressed: _openBarcodeScanner,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        maxWidth: 40,
                        maxHeight: 40,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              onChanged: (value) {
                final onlyDigits = RegExp(r'^\d+$');

                if (value.isEmpty) {
                  setState(() {}); // Sadece buton görünürlüğü için
                  _filterProducts2();
                } else if (onlyDigits.hasMatch(value)) {
                  if (value.length >= 11) {
                    setState(() {}); // Sadece buton görünürlüğü için
                    _filterProducts2();
                  }
                } else {
                  setState(() {}); // Sadece buton görünürlüğü için
                  _filterProducts2();
                }
              },
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartView2(),
                  ),
                );
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: 18.w,
                height: 10.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 8.w),
                    Positioned(
                      right: 1.w,
                      top: 0.2.h,
                      child: Container(
                        padding: EdgeInsets.all(0.4.w),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 6.w,
                          minHeight: 6.w,
                        ),
                        child: Center(
                          child: Text(
                            '${cartItems.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1.w,
                      bottom: 0.2.h,
                      child: Container(
                        padding: EdgeInsets.all(0.4.w),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 6.w,
                          minHeight: 6.w,
                        ),
                        child: Center(
                          child: Text(
                            '${unitCount + boxCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              final keyId = event.logicalKey.keyId;
              
              // print('KEY debug: ${event.logicalKey.debugName}');
              // print('KEY id: $keyId');

              if (keyId == 0x01100000209 ||
                  keyId == 0x01100000208 ||
                  keyId == 4294967556 ||
                  keyId == 73014445159|| // barkod okumuyor
                  keyId==4294967309       //
                  ) {
                    _searchController.clear();
                    _searchController2.clear();
_barcodeFocusNode.requestFocus();
      //           _searchController.clear();

      //           print('Özel tuş yakalandı: ${event.logicalKey.debugName}');
      //           _searchController2.clear();
      //            FocusScope.of(context).unfocus();
      // Future.delayed(Duration(milliseconds: 500), () {
      //   if (mounted) _barcodeFocusNode.requestFocus();
      // });
                return KeyEventResult.handled; // İstersen işlem yap
              }
            }

            return KeyEventResult.ignored; // Diğer tuşlar serbest
          },
          child: Column(
            children: [
                  Opacity(
                    opacity: 0.0,
                    child: SizedBox(
                      width: 1.w,
                      height: 1.h,
                      child: TextField(
                        focusNode: _barcodeFocusNode,
                        controller: _searchController,
                        style: TextStyle(fontSize: 1.sp),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          final onlyDigits = RegExp(r'^\d+$');

                          if (value.isEmpty) {
                            _filterProducts();
                          } else if (onlyDigits.hasMatch(value)) {
                            if (value.length >= 11) {
                              _filterProducts();
                            }
                          } else {
                            _filterProducts();
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'cart.loading_products'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : _filteredProducts.isEmpty
                            ? Center(
                              child: Text(
                                'cart.no_products'.tr(),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                            : ListView.builder(
                          padding: EdgeInsets.only(
                            left: 1.w,
                            right: 1.w,
                            top: 0.w,
                            bottom: 1.h,
                          ),
                          addAutomaticKeepAlives: true, // Widget'ları canlı tut
                          addRepaintBoundaries: true, // Repaint boundary ekle
                          cacheExtent: 100, // Cache extent artır
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final selectedType = provider.getBirimTipi(
                              product.stokKodu,
                            );

                            // String? initialPrice = selectedType == 'Unit'
                            //     ? product.adetFiyati
                            //     : selectedType == 'Box'
                            //         ? product.kutuFiyati
                            //         : '';

                            // _priceController = TextEditingController(text: initialPrice ?? '');

                            final key2 = product.stokKodu ?? 'unknown_$index';

                            // Sepette ürün var mı kontrol et
                            final cartItem =
                                context.read<CartProvider>().items[key2];

                            // Eğer cart'tan gelen varsa onu yaz, yoksa adet/kutu fiyatı
                            final initialPrice =
                                cartItem != null
                                    ? cartItem.birimFiyat.toString()
                                    : selectedType == 'Unit'
                                    ? product.adetFiyati
                                    : selectedType == 'Box'
                                    ? product.kutuFiyati
                                    : '';

                            // Sadece ilk kez oluşturuluyorsa controller'a fiyat yaz
                            if (!_priceControllers.containsKey(key2)) {
                              _priceControllers[key2] = TextEditingController(
                                text: initialPrice ?? '',
                              );
                            }

                            final _priceController = _priceControllers[key2]!;

                            // Discount controller setup - similar to price controller
                            final discountValue = context.read<CartProvider>().getIskonto(key2);
                            if (!_discountControllers.containsKey(key2)) {
                              _discountControllers[key2] = TextEditingController(
                                text: discountValue == 0 ? '' : discountValue.toString(),
                              );
                            }
                            final _discountController = _discountControllers[key2]!;

                            final key = product.stokKodu ?? 'unknown_$index';
                            final providersafdas = Provider.of<CartProvider>(
                              context,
                              listen: true,
                            );

                            _quantityMap[key] = providersafdas.getmiktar(key);
                            final isBox = _isBoxMap[key] ?? false;
                            final quantity = _quantityMap[key] ?? 0;
                            final iskonto = _iskontoMap[key] ?? 0;
                            final future = _imageFutures[product.stokKodu];

                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(
                                horizontal: 0.5.w,
                                vertical: 0.5.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
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
                                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(2.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                    GestureDetector(
                                      onDoubleTap: () {
                                        showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(
      product.urunAdi ?? 'cart.no_name'.tr(),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, // 🡐 sadece bu satır eklendi
      children: [
        product.imsrc == null
            ? Icon(
                Icons.shopping_bag,
                size: 40.w,
              )
            : FutureBuilder<String?>(
                future: () async {
                  try {
                    final imsrc = product.imsrc;
                    if (imsrc == null || imsrc.isEmpty) return null;

                    final uri = Uri.parse(imsrc);
                    final fileName = uri.pathSegments.isNotEmpty
                        ? uri.pathSegments.last
                        : null;
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
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Icon(
                      Icons.shopping_bag,
                      size: 40.w,
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(snapshot.data!),
                      width: 40.w,
                      height: 40.w,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          size: 40.w,
                        );
                      },
                    ),
                  );
                },
              ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: () {
            final firstBarcode = product.barcode1?.trim();
            if (firstBarcode != null && firstBarcode.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: firstBarcode));
            }
          },
          child: Text(
            "${'cart.barcodes'.tr()}: ${[
              product.barcode1,
              product.barcode2,
              product.barcode3,
              product.barcode4
            ].where((b) => b != null && b.trim().isNotEmpty).join(', ')}",
            style: TextStyle(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          "${'cart.code'.tr()}= ${product.stokKodu ?? '-'}",
        ),
        Text(
          "${'cart.unit_price'.tr()}= ${product.adetFiyati ?? '-'}",
        ),
        Text(
          "${'cart.box_price'.tr()}= ${product.kutuFiyati ?? '-'}",
        ),
        Text(
          "${'cart.vat'.tr()}= ${product.vat ?? '-'}",
        ),
        Text(
          "${'cart.code'.tr()}= ${product.imsrc ?? '-'}",
        ),
      ],
    ),
    actions: [
      TextButton(
        child: Text('cart.close'.tr()),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  ),
);

                                      },
                                      child: Row( //// RESİMLER BURASI
                                        children: [
                                          product.imsrc == null
                                              ? Column(
                                                children: [
                                                  Icon(
                                                    Icons.shopping_bag_sharp,
                                                    size: 20.w,
                                                  ),
                                                  Text("${tr('cart.stock')}: 0/0"),
                                                ],
                                              )
                                              : FutureBuilder<String?>(
                                                future: future,
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState != ConnectionState.done) {
                                                    return Column(
                                                      children: [
                                                        SizedBox(
                                                          width: 25.w,
                                                          height: 25.w,
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.image_outlined,
                                                              size: 15.w,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                                        Text("${tr('cart.stock')}: 0/0"),
                                                      ],
                                                    );
                                                  }
                                                  if (!snapshot.hasData || snapshot.data == null) {
                                                    return Column(
                                                      children: [
                                                        Icon(
                                                          Icons.shopping_bag,
                                                          size: 20.w,
                                                        ),
                                                        Text("${tr('cart.stock')}: 0/0"),
                                                      ],
                                                    );
                                                  }
                                                  return Column(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Image.file(
                                                          File(snapshot.data!),
                                                          width: 25.w,
                                                          height: 25.w,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Icon(
                                                              Icons.shopping_bag,
                                                              size: 20.w,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      Text("${tr('cart.stock')}: 0/0"),
                                                    ],
                                                  );
                                                },
                                              ),

                                          SizedBox(width: 5.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  maxLines: 4,
                                                  overflow:
                                                      TextOverflow.ellipsis,

                                                  product.urunAdi ?? '-',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: () {
                                                      final urunAdi =
                                                          product.urunAdi ?? '';
                                                      final isInRefundList = widget
                                                          .refundProductNames
                                                          .any(
                                                            (e) =>
                                                                e
                                                                    .toLowerCase() ==
                                                                (urunAdi ?? '')
                                                                    .toLowerCase(),
                                                          );

                                                      final isPassive =
                                                          product.aktif == 0;

                                                      if (isPassive &&
                                                          isInRefundList) {
                                                        return Colors.blue;
                                                      } else if (isInRefundList) {
                                                        return Colors.green;
                                                      } else if (isPassive) {
                                                        return Colors.red;
                                                      } else {
                                                        return Theme.of(context).colorScheme.onSurface;
                                                      }
                                                    }(),
                                                  ),
                                                ),

                                                SizedBox(height: 0.5.h),

                                                // Text(
                                                //   "Barcodes: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}",
                                                //   style: TextStyle(fontSize: 11.sp),
                                                // ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: TextField(
                                                        controller:
                                                            _priceController,
                                                        keyboardType:
                                                            TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        decoration: InputDecoration(
                                                          enabled: quantity > 0,
                                                          filled: true,
                                                          fillColor: quantity > 0
                                                              ? Theme.of(context).colorScheme.surface
                                                              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.38),
                                                          hintText: selectedType == 'Unit' ? product.adetFiyati : product.kutuFiyati,
                                                          hintStyle: TextStyle(
                                                            fontSize: 12.sp,
                                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Theme.of(context).colorScheme.outline,
                                                            ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Theme.of(context).colorScheme.outline.withOpacity(0.38),
                                                            ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(
                                                              color: Theme.of(context).colorScheme.primary,
                                                              width: 2.0,
                                                            ),
                                                          ),
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 8,
                                                                horizontal: 8,
                                                              ),
                                                        ),
                                                        onChanged: (value) {
                                                          final parsed =
                                                              double.tryParse(
                                                                value,
                                                              );
                                                          if (parsed != null) {
                                                            final customerProvider =
                                                                Provider.of<
                                                                  SalesCustomerProvider
                                                                >(
                                                                  context,
                                                                  listen: false,
                                                                );
                                                            provider.customerName =
                                                                customerProvider
                                                                    .selectedCustomer!
                                                                    .kod!;

                                                            // Normal birim fiyatını al
                                                            final normalPrice = selectedType == 'Unit'
                                                                ? double.tryParse(product.adetFiyati.toString()) ?? 0
                                                                : double.tryParse(product.kutuFiyati.toString()) ?? 0;

                                                            // İndirim miktarını hesapla (normal fiyat - girilen fiyat)
                                                            final calculatedDiscount = normalPrice - parsed;
                                                            final discountPercentage = normalPrice > 0
                                                                ? ((calculatedDiscount / normalPrice) * 100).round()
                                                                : 0;

                                                            // İndirim controller'ını güncelle
                                                            if (discountPercentage >= 0) {
                                                              _iskontoMap[key] = discountPercentage;
                                                              _discountController.text = discountPercentage == 0 ? '' : discountPercentage.toString();
                                                            }

                                                            if ((provider.getBirimTipi(
                                                                          product
                                                                              .stokKodu,
                                                                        ) ==
                                                                        'Unit' &&
                                                                    product.birimKey1 !=
                                                                        0) ||
                                                                (provider.getBirimTipi(
                                                                          product
                                                                              .stokKodu,
                                                                        ) ==
                                                                        'Box' &&
                                                                    product.birimKey2 !=
                                                                        "0")) {
                                                              provider.addOrUpdateItem(
                                                                urunAdi:
                                                                    product
                                                                        .urunAdi,
                                                                adetFiyati:
                                                                    product
                                                                        .adetFiyati,
                                                                kutuFiyati:
                                                                    product
                                                                        .kutuFiyati,
                                                                stokKodu: key,
                                                                vat:
                                                                    product.vat,
                                                                birimFiyat:
                                                                    parsed,
                                                                urunBarcode:
                                                                    product
                                                                        .barcode1,
                                                                miktar: 0,
                                                                iskonto:
                                                                    discountPercentage,
                                                                birimTipi: provider
                                                                    .getBirimTipi(
                                                                      product
                                                                          .stokKodu,
                                                                    ),
                                                              );
                                                            } else {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    '⚠️ ${'cart.unit_not_available'.tr()}',
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
                                                          }
                                                          setState(() {}); // Result alanını güncelle
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(width: 2.w),
                                                    // İndirim alanı buraya taşındı
                                                    Expanded(
                                                      flex: 2,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.local_offer,
                                                            size: 16.sp,
                                                            color: Theme.of(context).colorScheme.error,
                                                          ),
                                                          SizedBox(width: 1.w),
                                                          Expanded(
                                                            child: TextField(
                                                            keyboardType:
                                                                TextInputType.number,
                                                            controller: _discountController,
                                                            decoration: InputDecoration(
                                                              isDense: true,
                                                              filled: true,
                                                              fillColor: Theme.of(context).colorScheme.surface,
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: BorderSide(
                                                                  color: Theme.of(context).colorScheme.outline,
                                                                ),
                                                              ),
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: BorderSide(
                                                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.38),
                                                                ),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: BorderSide(
                                                                  color: Theme.of(context).colorScheme.primary,
                                                                  width: 2.0,
                                                                ),
                                                              ),
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 18.sp,
                                                            ),
                                                            onChanged: (val) {
                                                              final parsed =
                                                                  int.tryParse(val) ?? 0;
                                                              final clamped = parsed.clamp(
                                                                0,
                                                                100,
                                                              );
                                                              setState(() {
                                                                _iskontoMap[key] = clamped;
                                                              });

                                                              // Normal birim fiyatını al
                                                              final normalPrice = selectedType == 'Unit'
                                                                  ? double.tryParse(product.adetFiyati.toString()) ?? 0
                                                                  : double.tryParse(product.kutuFiyati.toString()) ?? 0;

                                                              // İndirim yüzdesine göre yeni fiyatı hesapla
                                                              final discountAmount = (normalPrice * clamped) / 100;
                                                              final discountedPrice = normalPrice - discountAmount;

                                                              // Fiyat controller'ını güncelle
                                                              if (discountedPrice >= 0) {
                                                                _priceController.text = discountedPrice.toStringAsFixed(2);
                                                              }
                                                            },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                //                                                 Text(
                                                //   selectedType == 'Unit'
                                                //       ? "Unit Price: ${product.adetFiyati ?? '-'}"
                                                //       : selectedType == 'Box'
                                                //           ? "Box Price: ${product.kutuFiyati ?? '-'}"
                                                //           : '-',
                                                //   style: TextStyle(fontSize: 17.sp),
                                                // ),

                                                // Text(
                                                //   "Unit Price: ${product.adetFiyati ?? '-'}",
                                                //   style: TextStyle(
                                                //     fontSize: 17.sp,
                                                //   ),
                                                // ),
                                                // Text(
                                                //   "Box Price: ${product.kutuFiyati ?? '-'}",
                                                //   style: TextStyle(
                                                //     fontSize: 17.sp,
                                                //   ),
                                                // ),

                                                // Text(
                                                //   "Active: ${product.aktif == 1 ? 'YES' : 'NO'}",
                                                //   style: TextStyle(fontSize: 11.sp),
                                                // ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(),
                                    // Tek satırda kompakt düzen - Hepsi bir grup
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // Type Dropdown
                                        Text(
                                          'cart.type'.tr() + ":",
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(width: 1.w),
                                        DropdownButton<String>(
                                          value: getBirimTipiFromProduct(product),
                                          isDense: false,
                                          underline: Container(),
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          items: [
                                            if (product.birimKey1 != 0)
                                              DropdownMenuItem(
                                                value: 'Unit',
                                                child: Text('cart.unit'.tr()),
                                              ),
                                            if (product.birimKey2 != 0)
                                              DropdownMenuItem(
                                                value: 'Box',
                                                child: Text('cart.box'.tr()),
                                              ),
                                          ],
                                                onChanged: (val) {
                                                  if ((val == 'Unit' &&
                                                          product.birimKey1 !=
                                                              0) ||
                                                      (val == 'Box' &&
                                                          product.birimKey2 !=
                                                              "0")) {
                                                    final bool newValue =
                                                        (val == 'Box'); // Box seçilmişse true, Unit seçilmişse false
                                                    setState(() {
                                                      _isBoxMap[key] = newValue;
                                                    });

                                                    final provider =
                                                        Provider.of<CartProvider>(
                                                          context,
                                                          listen: false,
                                                        );
                                                    final productFiyat =
                                                        newValue
                                                            ? double.parse(
                                                                  product
                                                                      .kutuFiyati
                                                                      .toString(),
                                                                ) ??
                                                                0
                                                            : double.parse(
                                                                  product
                                                                      .adetFiyati
                                                                      .toString(),
                                                                ) ??
                                                                0;
                                                    print(
                                                      "zzzzzzzzz $productFiyat",
                                                    );
                                                    final miktar =
                                                        _quantityMap[key] ?? 0;
                                                    print(
                                                      "objectttttttttttt $miktar",
                                                    );

                                                    if (miktar > 0) {
                                                      provider.customerName =
                                                          customer!.kod!;

                                                      if ((val == 'Unit' &&
                                                              product.birimKey1 !=
                                                                  0) ||
                                                          (val == 'Box' &&
                                                              product.birimKey2 !=
                                                                  "0")) {
                                                        provider.addOrUpdateItem(
                                                          urunAdi:
                                                              product.urunAdi,
                                                          stokKodu: key,
                                                          birimFiyat:
                                                              productFiyat,
                                                          adetFiyati:
                                                              product.adetFiyati,
                                                          kutuFiyati:
                                                              product.kutuFiyati,
                                                          vat: product.vat,
                                                          urunBarcode:
                                                              product.barcode1 ??
                                                              '',
                                                          miktar: 0,
                                                          iskonto:
                                                              _iskontoMap[key] ??
                                                              0,
                                                          birimTipi: val!,
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              '⚠️ ${'cart.unit_not_available'.tr()}',
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            backgroundColor:
                                                                Colors
                                                                    .orange
                                                                    .shade700,
                                                            duration: Duration(
                                                              seconds: 3,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } else if (miktar == 0) {
                                                      setState(() {
                                                        _quantityMap[key] =
                                                            _quantityMap[key]! +
                                                            1;
                                                      });
                                                      provider.customerName =
                                                          customer!.kod!;

                                                      if ((val == 'Unit' &&
                                                              product.birimKey1 !=
                                                                  0) ||
                                                          (val == 'Box' &&
                                                              product.birimKey2 !=
                                                                  "0")) {
                                                        provider.addOrUpdateItem(
                                                          urunAdi:
                                                              product.urunAdi,
                                                          stokKodu: key,
                                                          birimFiyat:
                                                              productFiyat,
                                                          adetFiyati:
                                                              product.adetFiyati,
                                                          vat: product.vat,

                                                          kutuFiyati:
                                                              product.kutuFiyati,
                                                          urunBarcode:
                                                              product.barcode1 ??
                                                              '',
                                                          miktar: 1,
                                                          iskonto:
                                                              _iskontoMap[key] ??
                                                              0,
                                                          birimTipi: val!,
                                                        );
                                                      }
                                                    }
                                                    _priceController.text =
                                                        productFiyat.toString();
                                                  } else {
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
                                                        duration: Duration(
                                                          seconds: 3,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                        SizedBox(width: 1.w), // Dropdown ve miktar butonları arası küçük boşluk

                                        // Quantity Controls - Direkt devam ediyor
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            size: 5.w,
                                          ),
                                          onPressed: () {
                                                if (_quantityMap[key]! > 0) {
                                                  setState(() {
                                                    _quantityMap[key] =
                                                        _quantityMap[key]! - 1;
                                                  });

                                                  final isBox =
                                                      _isBoxMap[key] ?? false;
                                                  final iskonto =
                                                      _iskontoMap[key] ?? 0;

                                                  final birimTipi =
                                                      isBox ? 'Box' : 'Unit';

                                                  final fiyat =
                                                      isBox
                                                          ? double.parse(
                                                                product
                                                                    .kutuFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0
                                                          : double.parse(
                                                                product
                                                                    .adetFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0;

                                                  final barcode =
                                                      product.barcode1 ??
                                                      '0000000000000';
                                                  final provider =
                                                      Provider.of<CartProvider>(
                                                        context,
                                                        listen: false,
                                                      );
                                                  provider.customerName =
                                                      customer!.kod!;

                                                  if ((provider.getBirimTipi(
                                                                product
                                                                    .stokKodu,
                                                              ) ==
                                                              'Unit' &&
                                                          product.birimKey1 !=
                                                              0) ||
                                                      (provider.getBirimTipi(
                                                                product
                                                                    .stokKodu,
                                                              ) ==
                                                              'Box' &&
                                                          product.birimKey2 !=
                                                              "0")) {
                                                    provider.addOrUpdateItem(
                                                      urunAdi: product.urunAdi,
                                                      adetFiyati:
                                                          product.adetFiyati,
                                                      kutuFiyati:
                                                          product.kutuFiyati,
                                                      stokKodu: key,
                                                      vat: product.vat,

                                                      birimFiyat: fiyat,
                                                      urunBarcode: barcode,
                                                      miktar: -1, // azaltıyoruz
                                                      iskonto: iskonto,
                                                      birimTipi: provider
                                                          .getBirimTipi(
                                                            product.stokKodu,
                                                          ),
                                                    );
                                                  } else {
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
                                                        duration: Duration(
                                                          seconds: 3,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),

                                            SizedBox(
                                              width:
                                                  8.w, // genişlik %30 ekran genişliği
                                              height:
                                                  5.h, // yükseklik %5 ekran yüksekliği
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text:
                                                      "${Provider.of<CartProvider>(context, listen: true).items[key]?.miktar ?? 0}",
                                                ),
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                ),
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 2.w,
                                                        vertical: 1.h,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2.w,
                                                        ),
                                                  ),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(4), // Max 4 haneli sayılar
                                                ],
                                                onSubmitted: (value) {
                                                  final int? newMiktar =
                                                      int.tryParse(value);

                                                  if (newMiktar != null && newMiktar >= 0 && newMiktar <= 9999) {
                                                    final provider =
                                                        Provider.of<
                                                          CartProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        );
                                                    provider.customerName =
                                                        customer!.kod!;

                                                    provider.updateMiktar(
                                                      key,
                                                      newMiktar,
                                                    );
                                                    // provider.addOrUpdateItem(
                                                    //   urunAdi: product.urunAdi,
                                                    //   adetFiyati:
                                                    //       product.adetFiyati,
                                                    //   kutuFiyati:
                                                    //       product.kutuFiyati,
                                                    //   stokKodu: key,
                                                    //   vat: product.vat,

                                                    //   birimFiyat:
                                                    //       isBox
                                                    //           ? double.tryParse(
                                                    //                 product
                                                    //                     .adetFiyati
                                                    //                     .toString(),
                                                    //               ) ??
                                                    //               0
                                                    //           : double.tryParse(
                                                    //                 product
                                                    //                     .kutuFiyati
                                                    //                     .toString(),
                                                    //               ) ??
                                                    //               0,
                                                    //   imsrc: product.imsrc,
                                                    //   urunBarcode:
                                                    //       product.barcode1 ??
                                                    //       '',
                                                    //   miktar: newMiktar,
                                                    //   iskonto:
                                                    //       _iskontoMap[key] ?? 0,
                                                    //   birimTipi: provider
                                                    //       .getBirimTipi(
                                                    //         product.stokKodu,
                                                    //       ),
                                                    // );
                                                    _quantityMap[key] =
                                                        newMiktar;
                                                  }

                                                  setState(() {});
                                                },
                                              ),
                                            ),

                                            IconButton(
                                              icon: Icon(Icons.add, size: 5.w),
                                              onPressed: () {
                                                setState(() {
                                                  _quantityMap[key] =
                                                      _quantityMap[key]! + 1;
                                                });

                                                final provider =
                                                    Provider.of<CartProvider>(
                                                      context,
                                                      listen: false,
                                                    );
                                                provider.customerName =
                                                    customer!.kod!;
                                                if ((provider.getBirimTipi(
                                                              product.stokKodu,
                                                            ) ==
                                                            'Unit' &&
                                                        product.birimKey1 !=
                                                            0) ||
                                                    (provider.getBirimTipi(
                                                              product.stokKodu,
                                                            ) ==
                                                            'Box' &&
                                                        product.birimKey2 !=
                                                            "0")) {
                                                  provider.addOrUpdateItem(
                                                    urunAdi: product.urunAdi,
                                                    adetFiyati:
                                                        product.adetFiyati,
                                                    kutuFiyati:
                                                        product.kutuFiyati,
                                                    stokKodu: key,
                                                    vat: product.vat,

                                                    birimFiyat:
                                                        isBox
                                                            ? double.tryParse(
                                                                  product
                                                                      .kutuFiyati
                                                                      .toString(),
                                                                ) ??
                                                                0
                                                            : double.tryParse(
                                                                  product
                                                                      .adetFiyati
                                                                      .toString(),
                                                                ) ??
                                                                0,
                                                    imsrc: product.imsrc,
                                                    urunBarcode:
                                                        product.barcode1 ?? '',
                                                    miktar: 1,
                                                    iskonto:
                                                        _iskontoMap[key] ?? 0,
                                                    birimTipi: provider
                                                        .getBirimTipi(
                                                          product.stokKodu,
                                                        ),
                                                  );
                                                } else {
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
                                                      duration: Duration(
                                                        seconds: 3,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            // El ikonu burada miktar butonlarının sağında
                                            SizedBox(width: 4.w), // Daha fazla boşluk ekle
                                            Stack(
                                              children: [
                                                GestureDetector(
                                                  behavior: HitTestBehavior.translucent,
                                                  child: Container(
                                                    padding: EdgeInsets.all(1.w),
                                                    width: 15.w,
                                                    height: 12.w,
                                                    child: Image.asset(
                                                      'assets/hand.png',
                                                      width: 10.w,
                                                      height: 10.w,
                                                    ),
                                                  ),
                                              onTap: () async {
                                                String selectedBirimTipi = 'Box';
                                                final TextEditingController miktarController = TextEditingController(text: '1');

                                                final result = await showDialog<Map<String, dynamic>>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text('cart.add_free_product'.tr()),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          DropdownButtonFormField<String>(
                                                            value: selectedBirimTipi,
                                                            items: ['Unit', 'Box'].map((String value) {
                                                              return DropdownMenuItem<String>(
                                                                value: value,
                                                                child: Text(value),
                                                              );
                                                            }).toList(),
                                                            onChanged: (value) {
                                                              if (value != null) {
                                                                selectedBirimTipi = value;
                                                              }
                                                            },
                                                            decoration: InputDecoration(labelText: 'cart.unit_type'.tr()),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          TextField(
                                                            controller: miktarController,
                                                            keyboardType: TextInputType.number,
                                                            decoration: InputDecoration(labelText: 'cart.quantity'.tr()),
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: Text('cart.cancel'.tr()),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            final miktar = int.tryParse(miktarController.text);
                                                            if (miktar != null && miktar > 0) {
                                                              Navigator.pop(context, {
                                                                'birimTipi': selectedBirimTipi,
                                                                'miktar': miktar,
                                                              });
                                                            }
                                                          },
                                                          child: Text('cart.add'.tr()),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                if (result == null) return;

                                                final provider = Provider.of<CartProvider>(context, listen: false);
                                                provider.customerName = customer!.kod!;

                                                double freeFiyat = 0.0;
                                                if (result['birimTipi'] == 'Unit' && product.birimKey1 != 0) {
                                                  freeFiyat = double.tryParse(product.adetFiyati.toString()) ?? 0.0;
                                                } else if (result['birimTipi'] == 'Box' && product.birimKey2 != "0") {
                                                  freeFiyat = double.tryParse(product.kutuFiyati.toString()) ?? 0.0;
                                                }

                                                final freeKey = "${product.stokKodu} (FREE${result['birimTipi']})";
                                                if ((result['birimTipi'] == 'Unit' && product.birimKey1 != 0) ||
                                                    (result['birimTipi'] == 'Box' && product.birimKey2 != "0")) {
                                                  provider.addOrUpdateItem(
                                                    stokKodu: freeKey,
                                                    urunAdi: "${product.urunAdi}_(FREE${result['birimTipi']})",
                                                    birimFiyat: freeFiyat,
                                                    miktar: result['miktar'],
                                                    urunBarcode: product.barcode1 ?? '',
                                                    iskonto: 100,
                                                    birimTipi: result['birimTipi'],
                                                    imsrc: product.imsrc,
                                                    vat: product.vat,
                                                    adetFiyati: '0',
                                                    kutuFiyati: '0',
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('cart.unit_not_available'.tr()),
                                                      behavior: SnackBarBehavior.floating,
                                                      backgroundColor: Colors.orange.shade700,
                                                      duration: const Duration(seconds: 3),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                                // Box Badge (mavi)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    padding: EdgeInsets.all(1.w),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.secondary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints: BoxConstraints(
                                                      minWidth: 6.w,
                                                      minHeight: 6.w,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        () {
                                                          final matches = cartItems.where(
                                                            (item) =>
                                                                item.urunAdi ==
                                                                    '${product.urunAdi}_(FREEBox)' &&
                                                                item.birimTipi ==
                                                                    'Box',
                                                          );

                                                          if (matches
                                                              .isNotEmpty) {
                                                            return '${matches.first.miktar}';
                                                          } else {
                                                            return '0';
                                                          }
                                                        }(),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Unit Badge (kırmızı)
                                                Positioned(
                                                  right: 15,
                                                  top: 0,
                                                  child: Container(
                                                    padding: EdgeInsets.all(1.w),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.error,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints: BoxConstraints(
                                                      minWidth: 6.w,
                                                      minHeight: 6.w,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        () {
                                                          final matches = cartItems.where(
                                                            (item) =>
                                                                item.urunAdi ==
                                                                    '${product.urunAdi}_(FREEUnit)' &&
                                                                item.birimTipi ==
                                                                    'Unit',
                                                          );

                                                          if (matches
                                                              .isNotEmpty) {
                                                            return '${matches.first.miktar}';
                                                          } else {
                                                            return '0';
                                                          }
                                                        }(),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // SizedBox.shrink(),
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
      ),
    );
  }
  
  Widget _buildRefundInfo(ProductModel product) {
    // product.urunAdi ile eşleşen refundlar
    final filtered = widget.refunds.where(
      (r) =>
          r.urunAdi.toLowerCase() ==
          product.urunAdi.toLowerCase(),
    );

    if (filtered.isEmpty) {
      return SizedBox.shrink(); // eşleşme yoksa boş widget
    }

    // tarihe göre azalan sıralama (en yeni tarih ilk)
    final sorted =
        filtered.toList()..sort(
          (a, b) => b.fisTarihi.compareTo(
            a.fisTarihi,
          ),
        );

    final refund =
        sorted
            .first; // en son tarihli refund

    return Text(
      "[Qty:${refund.miktar}x${refund.birim}] "
          "[Price:${refund.birimFiyat.toStringAsFixed(2)}] "
          "[Dsc:${refund.iskonto}%] "
          "[Date:${refund.fisTarihi.day.toString().padLeft(2, '0')}/"
          "${refund.fisTarihi.month.toString().padLeft(2, '0')}/"
          "${refund.fisTarihi.year}]",
      style: TextStyle(
        color: Color.fromARGB(255, 1, 71, 4),
        fontSize: 15.sp,
      ),
    );
  }

  String? getBirimTipiFromProduct(ProductModel product) {
    final key = product.stokKodu ?? '';
    final isBox = _isBoxMap[key] ?? false;

    // Eğer Box seçili ve Box mevcut ise
    if (isBox && product.birimKey2 != "0") {
      return 'Box';
    }
    // Eğer Unit seçili (Box değil) ve Unit mevcut ise
    else if (!isBox && product.birimKey1 != 0) {
      return 'Unit';
    }

    // Varsayılan olarak önce Box'ı kontrol et
    if (product.birimKey2 != "0") {
      return 'Box';
    } else if (product.birimKey1 != 0) {
      return 'Unit';
    }

    return null;
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String barcode) onScanned;

  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String _lastScanned = '';
  MobileScannerController cameraController = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      // Aynı barkodu tekrar tekrar okutmayı engelle
      if (rawValue == _lastScanned) return;

      _lastScanned = rawValue;

      // Ses çal
      playBeep();

      // Barkodu geri bildir
      widget.onScanned(rawValue);

      // Kısa bir gecikmeyle aynı barkodun yeniden taranmasına izin ver
      Future.delayed(const Duration(seconds: 2), () {
        _lastScanned = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('cart.scan'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: MobileScanner(controller: cameraController, onDetect: _onDetect),
    );
  }
}
