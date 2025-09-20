import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/models/refundlist_model.dart';
import 'package:pos_app/models/refundsend_model.dart';
import 'package:pos_app/providers/cart_provider_refund.dart';
import 'package:pos_app/views/refundcart_view2.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/controllers/database_helper.dart';
import 'package:sizer/sizer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product_model.dart';
import '../providers/cartcustomer_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class RefundCartView extends StatefulWidget {
  final List<String> refundProductNames;
  final List<Refund> refunds;
  final RefundFisModel fisModel;
  const RefundCartView({
    super.key,
    required this.fisModel,    required this.refundProductNames,

    required this.refunds,
  });

  @override
  State<RefundCartView> createState() => _RefundCartViewState();
}

class _RefundCartViewState extends State<RefundCartView> {
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _barcodeFocusNode2 = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};

  final Map<String, bool> _isBoxMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, int> _iskontoMap = {};


  @override
  void initState() {
    super.initState();

    _loadProducts();

        WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
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
    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
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
    setState(() {
      _allProducts = products;
      _filteredProducts = products.take(1000).toList();

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
    final provider = Provider.of<RCartProvider>(context, listen: false);

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
    final provider = Provider.of<RCartProvider>(context, listen: false);

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

  void _clearSearch() {
    _searchController.clear();    _filterProducts();

  }
    void _clearSearch2() {
    _searchController2.clear();
    _filterProducts2();
  }
  void _onBarcodeScanned(String barcode) {
    _searchController.text = barcode;
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

  @override
  void dispose() {    _barcodeFocusNode.dispose();

    _searchController.dispose();
    super.dispose();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playWrong() async {
    await _audioPlayer.play(AssetSource('wrong.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RCartProvider>(context, listen: true);
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
        return true; // sayfanın geri gitmesine izin ver
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              customer == null
                  ? const Text("No customer selected.")
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20.w,
                        child: Text(
                          customer.unvan ?? "default",
                          style: TextStyle(fontSize: 16.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, size: 10.w),
                        tooltip: 'Scan Barcode',
                        onPressed: _openBarcodeScanner,
                      ),
                      SizedBox(width: 3.w),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shopping_cart, size: 10.w),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => RefundCartView2(
                                        fisModel: widget.fisModel,
                                      ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 0,
                            top: 4,
                            child: Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
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
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 4,
                            child: Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
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
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
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

        body: Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              final keyId = event.logicalKey.keyId;

              if (keyId == 0x01100000209 || keyId == 0x01100000208) {
                print('Özel tuş yakalandı: ${event.logicalKey.debugName}');
                _searchController2.clear();
                _barcodeFocusNode.requestFocus();
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
                  Divider(),
                  Stack(children: [
                    Opacity(
                      opacity: 0.0,
                      child: TextField(
                      focusNode: _barcodeFocusNode,
                      controller: _searchController,
                      style: TextStyle(fontSize: 18.sp),
                      decoration: InputDecoration(
                        labelText: 'Search by by',
                        labelStyle: TextStyle(fontSize: 16.sp),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search, size: 6.w),
                        suffixIcon:
                            _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                ),
                      ),
                      onChanged: (value) {
                        final onlyDigits = RegExp(r'^\d+$');
                      
                        if (value.isEmpty) {
                          // Input tamamen temizlendiğinde de filtrele
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
                  TextField(
                    focusNode: _barcodeFocusNode2,
                    controller: _searchController2,
                    style: TextStyle(fontSize: 18.sp),
                    decoration: InputDecoration(
                      labelText: 'Search by NAME or BARCODE',
                      labelStyle: TextStyle(fontSize: 16.sp),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search, size: 6.w),
                      suffixIcon:
                          _searchController2.text.isEmpty
                              ? null
                              : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch2,
                              ),
                    ),
                    onChanged: (value) {
                      final onlyDigits = RegExp(r'^\d+$');

                      if (value.isEmpty) {
                        // Input tamamen temizlendiğinde de filtrele
                        _filterProducts2();
                      } else if (onlyDigits.hasMatch(value)) {
                        if (value.length >= 11) {
                          _filterProducts2();
                        }
                      } else {
                        _filterProducts2();
                      }
                    },
                  ),],),
                  _filteredProducts.isEmpty
                      ? const Text("Press clear data + fully sync to get data.")
                      : Container(
                        height: 80.h,
                        child: ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final key = product.stokKodu ?? 'unknown_$index';
                            final providersafdas = Provider.of<RCartProvider>(
                              context,
                              listen: true,
                            );
          
                            _quantityMap[key] = providersafdas.getmiktar(key);
                            final isBox = _isBoxMap[key] ?? false;
                            final quantity = _quantityMap[key] ?? 0;
                            final iskonto = _iskontoMap[key] ?? 0;
                            final future = _imageFutures[product.stokKodu];
          
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.w),
                              ),
                              margin: EdgeInsets.symmetric(vertical: 0.5.h),
                              child: Padding(
                                padding: EdgeInsets.all(2.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onDoubleTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              ///ALERT DIALOG DİALOG
                                              (context) => AlertDialog(
                                                title: Text(
                                                  product.urunAdi ?? 'No name',
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
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
                                                          builder: (
                                                            context,
                                                            snapshot,
                                                          ) {
                                                            if (snapshot
                                                                    .connectionState !=
                                                                ConnectionState
                                                                    .done) {
                                                              return SizedBox(
                                                                width: 20.w,
                                                                height: 20.w,
                                                                child: Center(
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                      ),
                                                                ),
                                                              );
                                                            }
                                                            if (!snapshot
                                                                    .hasData ||
                                                                snapshot.data ==
                                                                    null) {
                                                              return Icon(
                                                                Icons
                                                                    .shopping_bag,
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
                                                                    File(
                                                                      snapshot
                                                                          .data!,
                                                                    ),
                                                                    width: 40.w,
                                                                    height: 40.w,
                                                                    fit:
                                                                        BoxFit
                                                                            .contain,
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
                                                            cartProvider
                                                                .items[product
                                                                .stokKodu];
                                                        final currentAciklama =
                                                            item?.aciklama ?? '';
          
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item?.urunAdi ?? '',
                                                            ),
                                                            SizedBox(height: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                _showIadeNedeniSecimi(
                                                                  context,
                                                                  product
                                                                      .stokKodu,
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
                                                                            ? Colors
                                                                                .black
                                                                            : Colors
                                                                                .grey,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
          
                                                    Text(
                                                      "Unit Price: ${product.adetFiyati ?? '-'}",
                                                    ),
                                                    Text(
                                                      "Box Price: ${product.kutuFiyati ?? '-'}",
                                                    ),
          
                                                    // Text("Active: ${product.aktif == 1 ? 'YES' : 'NO'}"),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('Close'),
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          product.imsrc == null
                                              ? Column(
                                                children: [
                                                  Icon(
                                                    Icons.shopping_bag,
                                                    size: 20.w,
                                                  ),
                                                  Text("Stk: 0/0"),
                                                ],
                                              )
                                              : FutureBuilder<String?>(
                                                future: future,
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState !=
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
                                                  product.urunAdi ?? '-',
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: () {
                                                      final urunAdi =
                                                          product.urunAdi ?? '';
                                                      final isInRefundList = widget
                                                          .refundProductNames
                                                          .any(
                                                            (e) =>
                                                                e.toLowerCase() ==
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
                                                        return Colors.black;
                                                      }
                                                    }(),
                                                  ),
                                                ),
          
                                                SizedBox(height: 0.5.h),
                                                // Text(
                                                //   "Barcodes: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}",
                                                //   style: TextStyle(fontSize: 11.sp),
                                                // ),
                                                Text(
                                                  "Unit Price: ${product.adetFiyati ?? '-'}",
                                                  style: TextStyle(
                                                    fontSize: 17.sp,
                                                  ),
                                                ),
                                                Text(
                                                  "Box Price: ${product.kutuFiyati ?? '-'}",
                                                  style: TextStyle(
                                                    fontSize: 17.sp,
                                                  ),
                                                ),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
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
  value: getBirimTipiFromProduct(product),
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
  final bool newValue =
      (val == 'Unit');
  
  setState(() {
    _isBoxMap[key] = newValue;
  });
            
  final provider =
      Provider.of<RCartProvider>(
        context,
        listen: false,
      );
  final productFiyat =
      newValue
          ? double.parse(
                product.adetFiyati
                    .toString(),
              ) ??
              0
          : double.parse(
                product.kutuFiyati
                    .toString(),
              ) ??
              0;
  print("zzzzzzzzz $productFiyat");
  final miktar =
      _quantityMap[key] ?? 0;
  print(
    "objectttttttttttt $miktar",
  );
            
  if (miktar > 0) {
    final customerProvider =
        Provider.of<
          SalesCustomerProvider
        >(context, listen: false);
    provider.customerName =
        customerProvider
            .selectedCustomer!
            .kod!;
    provider.addOrUpdateItem(
      urunAdi: product.urunAdi,
      stokKodu: key,
      birimFiyat: productFiyat,
      adetFiyati:
          product.adetFiyati,
      kutuFiyati:
          product.kutuFiyati,
      vat: product.vat,
      urunBarcode:
          product.barcode1 ?? '',
      miktar: 0,
      iskonto:
          _iskontoMap[key] ?? 0,
      birimTipi: val!,
    );
  } else if (miktar == 0) {
    setState(() {
      _quantityMap[key] =
          _quantityMap[key]! + 1;
    });
    final customerProvider =
        Provider.of<
          SalesCustomerProvider
        >(context, listen: false);
    provider.customerName =
        customerProvider
            .selectedCustomer!
            .kod!;
    provider.addOrUpdateItem(
      urunAdi: product.urunAdi,
      stokKodu: key,
      birimFiyat: productFiyat,
      adetFiyati:
          product.adetFiyati,
      vat: product.vat,
            
      kutuFiyati:
          product.kutuFiyati,
      urunBarcode:
          product.barcode1 ?? '',
      miktar: 1,
      iskonto:
          _iskontoMap[key] ?? 0,
      birimTipi: val!,
    );
  }
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
                                        // Row(
                                        //   children: [
                                        //     Icon(
                                        //       Icons.local_offer,
                                        //       size: 20.sp,
                                        //       color: Colors.red,
                                        //     ),
                                        //     SizedBox(width: 1.w),
                                        //     SizedBox(
                                        //       width: 17.w,
                                        //       child: TextField(
                                        //         keyboardType:
                                        //             TextInputType.number,
                                        //         controller: TextEditingController(
                                        //           text:
                                        //               provider
                                        //                   .getIskonto(key)
                                        //                   .toString(),
                                        //         ),
                                        //         decoration: InputDecoration(
                                        //           isDense: true,
                                        //           border: OutlineInputBorder(),
                                        //         ),
                                        //         style: TextStyle(fontSize: 18.sp),
                                        //         onSubmitted: (val) {
                                        //           final parsed =
                                        //               int.tryParse(val) ?? 0;
                                        //           final clamped = parsed.clamp(
                                        //             0,
                                        //             100,
                                        //           );
                                        //           setState(() {
                                        //             _iskontoMap[key] = clamped;
                                        //           });
          
                                        //           final isBox =
                                        //               _isBoxMap[key] ?? false;
                                        //           final birimTipi = provider
                                        //               .getBirimTipi(
                                        //                 product.stokKodu,
                                        //               );
                                        //           final fiyat =
                                        //               isBox
                                        //                   ? double.tryParse(
                                        //                         product.kutuFiyati
                                        //                             .toString(),
                                        //                       ) ??
                                        //                       0
                                        //                   : double.tryParse(
                                        //                         product.adetFiyati
                                        //                             .toString(),
                                        //                       ) ??
                                        //                       0;
          
                                        //           final barcode =
                                        //               product.barcode1 ??
                                        //               '0000000000000';
          
                                        //           final miktar =
                                        //               _quantityMap[key] ?? 0;
                                        //           print(
                                        //             "objectttttttttttt $miktar",
                                        //           );
                                        //           int artir = 0;
                                        //           if (miktar == 0 &&
                                        //               clamped != 0) {
                                        //             artir = 1;
                                        //           }
                                        //           final customerProvider =
                                        //               Provider.of<
                                        //                 SalesCustomerProvider
                                        //               >(context, listen: false);
                                        //           provider.customerName =
                                        //               customerProvider
                                        //                   .selectedCustomer!
                                        //                   .kod!;
                                        //           provider.addOrUpdateItem(
                                        //             urunAdi: product.urunAdi,
                                        //             stokKodu: key,
                                        //             vat: product.vat,
          
                                        //             birimFiyat: fiyat,
                                        //             adetFiyati:
                                        //                 product.adetFiyati,
                                        //             kutuFiyati:
                                        //                 product.kutuFiyati,
                                        //             urunBarcode: barcode,
                                        //             miktar: artir,
                                        //             iskonto: clamped,
                                        //             birimTipi: birimTipi,
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
                                                                product.adetFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0
                                                          : double.parse(
                                                                product.kutuFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0;
          
                                                  final barcode =
                                                      product.barcode1 ??
                                                      '0000000000000';
                                                  final provider =
                                                      Provider.of<RCartProvider>(
                                                        context,
                                                        listen: false,
                                                      );
                                                  final customerProvider =
                                                      Provider.of<
                                                        SalesCustomerProvider
                                                      >(context, listen: false);
                                                  provider.customerName =
                                                      customerProvider
                                                          .selectedCustomer!
                                                          .kod!;
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
                                                }
                                              },
                                            ),
          
                                            SizedBox(
                                              width:
                                                  10.w, // genişlik %30 ekran genişliği
                                              height:
                                                  5.h, // yükseklik %5 ekran yüksekliği
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text:
                                                      "${Provider.of<RCartProvider>(context, listen: true).items[key]?.miktar ?? 0}",
                                                ),
                                                style: TextStyle(fontSize: 18.sp),
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
          
                                                onSubmitted: (value) {
                                                  final int? newMiktar =
                                                      int.tryParse(value);
          
                                                  if (newMiktar != null) {
                                                    final provider = Provider.of<
                                                      RCartProvider
                                                    >(context, listen: false);
                                                    final customerProvider =
                                                        Provider.of<
                                                          SalesCustomerProvider
                                                        >(context, listen: false);
                                                    provider.customerName =
                                                        customerProvider
                                                            .selectedCustomer!
                                                            .kod!;
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
                                                      miktar: newMiktar,
                                                      iskonto:
                                                          _iskontoMap[key] ?? 0,
                                                      birimTipi: provider
                                                          .getBirimTipi(
                                                            product.stokKodu,
                                                          ),
                                                    );
                                                    _quantityMap[key] = newMiktar;
                                                  }
          
                                                  setState(() {});
                                                },
                                              ),
                                            ),
          
                                            IconButton(
                                              icon: Icon(Icons.add, size: 10.w),
                                              onPressed: () {
                                                setState(() {
                                                  _quantityMap[key] =
                                                      _quantityMap[key]! + 1;
                                                });
          
                                                final provider =
                                                    Provider.of<RCartProvider>(
                                                      context,
                                                      listen: false,
                                                    );
                                                final customerProvider =
                                                    Provider.of<
                                                      SalesCustomerProvider
                                                    >(context, listen: false);
                                                provider.customerName =
                                                    customerProvider
                                                        .selectedCustomer!
                                                        .kod!;
                                                provider.addOrUpdateItem(
                                                  urunAdi: product.urunAdi,
                                                  adetFiyati: product.adetFiyati,
                                                  kutuFiyati: product.kutuFiyati,
                                                  stokKodu: key,
                                                  vat: product.vat,
          
                                                  birimFiyat:
                                                      isBox
                                                          ? double.tryParse(
                                                                product.kutuFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0
                                                          : double.tryParse(
                                                                product.adetFiyati
                                                                    .toString(),
                                                              ) ??
                                                              0,
                                                  imsrc: product.imsrc,
                                                  urunBarcode:
                                                      product.barcode1 ?? '',
                                                  miktar: 1,
                                                  iskonto: _iskontoMap[key] ?? 0,
                                                  birimTipi: provider
                                                      .getBirimTipi(
                                                        product.stokKodu,
                                                      ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      () {
                                        // product.urunAdi ile eşleşen refundlar
                                        final filtered = widget.refunds.where(
                                          (r) => r.urunAdi == product.urunAdi,
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
                                            sorted.first; // en son tarihli refund
          
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
  if (product.birimKey1 != 0) {
    return 'Unit';
  } else if (product.birimKey2 != 0) {
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
    await _audioPlayer.play(AssetSource('assets/beep.mp3'));
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
        title: const Text("Scan Barcode"),
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
