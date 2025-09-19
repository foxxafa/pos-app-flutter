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

    // Tüm ürünleri al, sonra sıralayıp ilk 1000 tanesini filtrele
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
      _filteredProducts = sortedFiltered.toList();

      for (var product in products) {
        final key = product.stokKodu ?? '';
        _isBoxMap[key] = false;
        _quantityMap[key] = 0;
        _iskontoMap[key] = 0;
      }
      _generateImageFutures(products);
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
                hintText: 'Search by NAME or BARCODE',
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
                setState(() {}); // Trigger rebuild for clear button visibility
                final onlyDigits = RegExp(r'^\d+$');

                if (value.isEmpty) {
                  _filterProducts2();
                } else if (onlyDigits.hasMatch(value)) {
                  if (value.length >= 11) {
                    _filterProducts2();
                  }
                } else {
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  _filteredProducts.isEmpty
                      ? Center(
                        child: Text(
                          "There is no product..",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ), // yükleme animasyonu
                      )
                      : Container(
                        height: 75.h,
                        child: ListView.builder(
                          shrinkWrap: true, // 🔁 dış scroll'a göre boyutlanır
                          addAutomaticKeepAlives: false, // Performance optimization
                          addRepaintBoundaries: false, // Performance optimization
                          cacheExtent: 0, // Performance optimization - sadece görünür öğeleri cache'le
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
                                horizontal: 2.w,
                                vertical: 1.h,
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
                                    padding: EdgeInsets.all(3.w),
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
      product.urunAdi ?? 'No name',
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
                    print("✓ Yükleme kontrolü: $filePath");

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
                      width: 20.w,
                      height: 20.w,
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
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
        GestureDetector(
          onTap: () {
            final firstBarcode = product.barcode1?.trim();
            if (firstBarcode != null && firstBarcode.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: firstBarcode));
            }
          },
          child: Text(
            "Barcodes: ${[
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
          "Code= ${product.stokKodu ?? '-'}",
        ),
        Text(
          "Unit Price= ${product.adetFiyati ?? '-'}",
        ),
        Text(
          "Box Price= ${product.kutuFiyati ?? '-'}",
        ),
        Text(
          "VAT= ${product.vat ?? '-'}",
        ),
        Text(
          "Code= ${product.imsrc ?? '-'}",
        ),
      ],
    ),
    actions: [
      TextButton(
        child: const Text('Close'),
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
                                                  Text("Stk: 0/0 ${product.imsrc}"),
                                                ],
                                              )
                                              : FutureBuilder<String?>(
                                                future: future,
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState !=
                                                      ConnectionState.done) {
                                                    return SizedBox(
                                                      width: 6.w,
                                                      height: 6.w,
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
                                                    return Column(
                                                      children: [
                                                        Icon(
                                                          Icons.shopping_bag,
                                                          size: 20.w,
                                                        ),
                                                        Text("Stk: 0/0"),
                                                      ],
                                                    );
                                                  }
                                                  return Column(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        child: Image.file(
                                                          File(snapshot.data!),
                                                          width: 20.w,
                                                          height: 20.w,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      Text("Stk: 0/0"),
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
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                                                    iskonto,
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
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(width: 3.w),
                                                    Text(
                                                      () {
                                                        final rawText =
                                                            _priceController
                                                                .text;
                                                        final price =
                                                            double.tryParse(
                                                              rawText,
                                                            ) ??
                                                            0;
                                                        final discounted =
                                                            price *
                                                            (1 -
                                                                (iskonto /
                                                                    100));
                                                        return "Result: ${discounted.toStringAsFixed(2)}"; // örnek: 150.00
                                                      }(),
                                                      style: TextStyle(
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                          Stack(
                                            children: [
                                              Positioned(
                                                left: 15,
                                                top: 15,
                                                child: Image.asset(
                                                  'assets/hand.png',
                                                  width: 10.w,
                                                  height: 10.w,
                                                ),
                                              ),
                                              GestureDetector(
                                                behavior:
                                                    HitTestBehavior
                                                        .translucent, // boş alanlara da tıklanabilsin
                                                child: Container(
                                                  width: 15.w,
                                                  height: 20.w,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                                    ), // tema rengi ile uyumlu
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: null,
                                                ),
                                                onTap: () async {
                                                  String selectedBirimTipi =
                                                      'Box';
                                                  final TextEditingController
                                                  miktarController =
                                                      TextEditingController(
                                                        text: '1',
                                                      );

                                                  final result = await showDialog<
                                                    Map<String, dynamic>
                                                  >(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          'Add Free Product',
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            DropdownButtonFormField<
                                                              String
                                                            >(
                                                              value:
                                                                  selectedBirimTipi,
                                                              items:
                                                                  [
                                                                    'Unit',
                                                                    'Box',
                                                                  ].map((
                                                                    String
                                                                    value,
                                                                  ) {
                                                                    return DropdownMenuItem<
                                                                      String
                                                                    >(
                                                                      value:
                                                                          value,
                                                                      child: Text(
                                                                        value,
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                              onChanged: (
                                                                value,
                                                              ) {
                                                                if (value !=
                                                                    null) {
                                                                  selectedBirimTipi =
                                                                      value;
                                                                }
                                                              },
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        'Birim Tipi',
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            TextField(
                                                              controller:
                                                                  miktarController,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        'Miktar',
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ), // iptal
                                                            child: const Text(
                                                              'İptal',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              final miktar =
                                                                  int.tryParse(
                                                                    miktarController
                                                                        .text,
                                                                  );
                                                              if (miktar !=
                                                                      null &&
                                                                  miktar > 0) {
                                                                Navigator.pop(
                                                                  context,
                                                                  {
                                                                    'birimTipi':
                                                                        selectedBirimTipi,
                                                                    'miktar':
                                                                        miktar,
                                                                  },
                                                                );
                                                              }
                                                            },
                                                            child: const Text(
                                                              'Ekle',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (result == null) return;

                                                  final provider =
                                                      Provider.of<CartProvider>(
                                                        context,
                                                        listen: false,
                                                      );

                                                  provider.customerName =
                                                      customer!.kod!;

double freeFiyat = 0.0;

if (result['birimTipi'] == 'Unit' && product.birimKey1 != 0) {
  freeFiyat = double.tryParse(product.adetFiyati.toString()) ?? 0.0;
} else if (result['birimTipi'] == 'Box' && product.birimKey2 != "0") {
  freeFiyat = double.tryParse(product.kutuFiyati.toString()) ?? 0.0;
}


                                                  final freeKey =
                                                      "${product.stokKodu} (FREE${result['birimTipi']})";
                                                  if ((result['birimTipi'] ==
                                                              'Unit' &&
                                                          product.birimKey1 !=
                                                              0) ||
                                                      (result['birimTipi'] ==
                                                              'Box' &&
                                                          product.birimKey2 !=
                                                              "0")) {
                                                    provider.addOrUpdateItem(
                                                      stokKodu: freeKey,
                                                      urunAdi:
                                                          "${product.urunAdi}_(FREE${result['birimTipi']})",
                                                      birimFiyat: freeFiyat,
                                                      miktar: result['miktar'],
                                                      urunBarcode:
                                                          product.barcode1 ??
                                                          '',
                                                      iskonto: 100,
                                                      birimTipi:
                                                          result['birimTipi'],
                                                      imsrc: product.imsrc,
                                                      vat: product.vat,
                                                      adetFiyati: '0',
                                                      kutuFiyati: '0',
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
                                    ),
                                    Divider(),
                                    // Tek satırda kompakt düzen
                                    Row(
                                      children: [
                                        // Type Dropdown - Compacted
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Type:",
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                              SizedBox(width: 1.w),
                                              DropdownButton<String>(
                                                value: getBirimTipiFromProduct(product),
                                                isDense: true,
                                                underline: Container(),
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                items: [
                                                  if (product.birimKey1 != 0)
                                                    const DropdownMenuItem(
                                                      value: 'Unit',
                                                      child: Text('Unit'),
                                                    ),
                                                  if (product.birimKey2 != 0)
                                                    const DropdownMenuItem(
                                                      value: 'Box',
                                                      child: Text('Box'),
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
                                                                      .adetFiyati
                                                                      .toString(),
                                                                ) ??
                                                                0
                                                            : double.parse(
                                                                  product
                                                                      .kutuFiyati
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
                                            ],
                                          ),
                                        ),

                                        // Discount Field - Compacted
                                        Expanded(
                                          flex: 1,
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
                                                controller:
                                                    TextEditingController(
                                                      text:
                                                          provider.getIskonto(
                                                                    key,
                                                                  ) ==
                                                                  0
                                                              ? ''
                                                              : provider
                                                                  .getIskonto(
                                                                    key,
                                                                  )
                                                                  .toString(),
                                                    ),
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
                                                onSubmitted: (val) {
                                                  final parsed =
                                                      int.tryParse(val) ?? 0;
                                                  final clamped = parsed.clamp(
                                                    0,
                                                    100,
                                                  );
                                                  setState(() {
                                                    _iskontoMap[key] = clamped;
                                                  });

                                                  final isBox =
                                                      _isBoxMap[key] ?? false;
                                                  final birimTipi = provider
                                                      .getBirimTipi(
                                                        product.stokKodu,
                                                      );
                                                  final fiyat =
                                                      isBox
                                                          ? double.tryParse(
                                                                product
                                                                    .adetFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0
                                                          : double.tryParse(
                                                                product
                                                                    .kutuFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0;

                                                  final barcode =
                                                      product.barcode1 ??
                                                      '0000000000000';

                                                  final miktar =
                                                      _quantityMap[key] ?? 0;
                                                  print(
                                                    "objectttttttttttt $miktar",
                                                  );
                                                  int artir = 0;
                                                  if (miktar == 0 &&
                                                      clamped != 0) {
                                                    artir = 1;
                                                  }
                                                  provider.customerName =
                                                      customer!.kod!;
                                                  if ((birimTipi == 'Unit' &&
                                                          product.birimKey1 !=
                                                              0) ||
                                                      (birimTipi == 'Box' &&
                                                          product.birimKey2 !=
                                                              "0")) {
                                                    provider.addOrUpdateItem(
                                                      urunAdi: product.urunAdi,
                                                      stokKodu: key,
                                                      vat: product.vat,

                                                      birimFiyat: fiyat,
                                                      adetFiyati:
                                                          product.adetFiyati,
                                                      kutuFiyati:
                                                          product.kutuFiyati,
                                                      urunBarcode: barcode,
                                                      miktar: artir,
                                                      iskonto: clamped,
                                                      birimTipi: birimTipi,
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
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Quantity Controls - Compacted
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
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
                                                      isBox ? 'Unit' : 'Box';

                                                  final fiyat =
                                                      isBox
                                                          ? double.parse(
                                                                product
                                                                    .adetFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0
                                                          : double.parse(
                                                                product
                                                                    .kutuFiyati
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
                                                                      .adetFiyati
                                                                      .toString(),
                                                                ) ??
                                                                0
                                                            : double.tryParse(
                                                                  product
                                                                      .kutuFiyati
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                    Text(
                                      () {
                                        // product.urunAdi ile eşleşen refundlar
                                        final filtered = widget.refunds.where(
                                          (r) =>
                                              r.urunAdi.toLowerCase() ==
                                              product.urunAdi.toLowerCase(),
                                        );

                                        if (filtered.isEmpty)
                                          return ""; // eşleşme yoksa boş string

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

                                        return "[Qty:${refund.miktar}x${refund.birim}] "
                                            "[Price:${refund.birimFiyat.toStringAsFixed(2)}] "
                                            "[Dsc:${refund.iskonto}%] "
                                            "[Date:${refund.fisTarihi.day.toString().padLeft(2, '0')}/"
                                            "${refund.fisTarihi.month.toString().padLeft(2, '0')}/"
                                            "${refund.fisTarihi.year}]";
                                      }(),
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 1, 71, 4),
                                        fontSize: 15.sp,
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
                ],
              ),
            ),
          ),
        ),
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

    // Varsayılan olarak mevcut olan ilk seçeneği döndür
    if (product.birimKey1 != 0) {
      return 'Unit';
    } else if (product.birimKey2 != "0") {
      return 'Box';
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
        title: const Text("SCAN"),
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
