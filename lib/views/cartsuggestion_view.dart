import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/views/cart_view2.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:sizer/sizer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product_model.dart';
import '../providers/cartcustomer_provider.dart';
import 'dart:io';

class CartsuggestionView extends StatefulWidget {
  final String musteriId;

  const CartsuggestionView({super.key, required this.musteriId});

  @override
  State<CartsuggestionView> createState() => _CartsuggestionViewState();
}

class _CartsuggestionViewState extends State<CartsuggestionView> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  // List<String> _refundProductNames = []; // sadece urunAdi'lar

  final Map<String, bool> _isBoxMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, int> _iskontoMap = {};

  @override
  void initState() {
    super.initState();

    _loadProducts(widget.musteriId);
    _searchController.addListener(_filterProducts);
  }

  void _generateImageFutures(List<ProductModel> products) {
    for (final product in products) {
      final stokKodu = product.stokKodu;
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


  // void _loadRefunds(String cariKod) async {
  //   RefundListController refundListController = RefundListController();
  //   final refunds = await refundListController.fetchRefunds(cariKod);

  //   // refund urunAdi'larını sayfa içinde al
  //   setState(() {
  //     _refundProductNames =
  //         refunds
  //             .map((r) => r.urunAdi.toLowerCase())
  //             .toSet()
  //             .toList(); // Tekilleştir
  //   });
  // }

  Future<void> _loadProducts(String musteriId) async {
    print('⏳ Loading products for musteriId = $musteriId');

    DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final refundRows = await db.query('Refunds');
    print('📦 Refunds found: ${refundRows.length}');

    final refundStokKodlari =
        refundRows
            .map((row) => row['stokKodu'] as String?)
            .where((e) => e != null && e.isNotEmpty)
            .toSet()
            .toList();
    print('🧾 Refund stokKodlari: $refundStokKodlari');

    final raw = await db.query('Product');
    final allProducts = raw.map((e) => ProductModel.fromMap(e)).toList();
    print('🛒 Total products: ${allProducts.length}');
    print(
      '🎯 Matching products: ${allProducts.where((p) => refundStokKodlari.contains(p.stokKodu)).length}',
    );

    final filteredProducts =
        allProducts.where((product) {
          final stokKodu = product.stokKodu;
          return refundStokKodlari.contains(stokKodu);
        }).toList();

    setState(() {
      _allProducts = filteredProducts;
      _filteredProducts = filteredProducts.take(1000).toList();

      for (var product in filteredProducts) {
        final key = product.stokKodu;
        _isBoxMap[key] = false;
        _quantityMap[key] = 0;
        _iskontoMap[key] = 0;
      }

      _generateImageFutures(filteredProducts);
    });

    print('✅ Listed products: ${_filteredProducts.length}');
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();

    final filtered =
        _allProducts.where((product) {
          final name = product.urunAdi.toLowerCase();
          final barcodes =
              [
                product.barcode1,
                product.barcode2,
                product.barcode3,
                product.barcode4,
              ].map((b) => b.toLowerCase()).toList();

          // Her kelimenin, ürün adı veya barkodlardan en az birinde geçip geçmediğini kontrol et
          final matchesAllWords = queryWords.every((word) {
            final inName = name.contains(word);
            final inBarcodes = barcodes.any((b) => b.contains(word));
            return inName || inBarcodes;
          });

          return matchesAllWords;
        }).toList();

    setState(() {
      _filteredProducts = filtered.take(50).toList();
      _generateImageFutures(_filteredProducts);
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _onBarcodeScanned(String barcode) {
    _searchController.text = barcode;
    _filterProducts();
    Navigator.of(context).pop(); // Kamera sayfasını kapat
  }

  Future<void> _openBarcodeScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(onScanned: _onBarcodeScanned),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CartProvider>(context, listen: true);
    final customer =
        Provider.of<SalesCustomerProvider>(context).selectedCustomer;

    final cartItems = provider.items.values.toList();

    final unitCount = cartItems
        .where((item) => item.birimTipi == 'Unit')
        .fold<int>(0, (prev, item) => prev + item.miktar);

    final boxCount = cartItems
        .where((item) => item.birimTipi == 'Box')
        .fold<int>(0, (prev, item) => prev + item.miktar);

    return PopScope(
      canPop: true, // sayfanın geri gitmesine izin ver
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Suggestion", style: TextStyle(fontSize: 24.sp)),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.qr_code_scanner, size: 6.w),
            //   tooltip: 'Scan Barcode',
            //   onPressed: _openBarcodeScanner,
            // ),
            // IconButton(
            //   icon: Icon(Icons.shopping_cart, size: 6.w),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const CartsuggestionView2()),
            //     );
            //   },
            // ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customer == null)
                  const Text("No customer selected.")
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30.w,
                        child: Text(
                          customer.unvan ?? "default",
                          style: TextStyle(fontSize: 16.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner, size: 10.w),
                            tooltip: 'Scan Barcode',
                            onPressed: _openBarcodeScanner,
                          ),
                          SizedBox(width: 3.w),

                          //SHOPPİNG CART
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: Icon(Icons.shopping_cart, size: 10.w),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CartView2(),
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

                          // Icon(Icons.album, size: 18.sp, color: Colors.black), // UNIT iconu
                          // SizedBox(width: 4),
                          // Text("UNIT: $unitCount", style: TextStyle(fontSize: 16.sp)),
                          // SizedBox(width: 12),
                          // Icon(Icons.all_inbox, size: 18.sp, color: Colors.black), // BOX iconu
                          // SizedBox(width: 4),
                          // Text("BOX: $boxCount", style: TextStyle(fontSize: 16.sp)),
                        ],
                      ),
                    ],
                  ),
                Divider(),
                TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 18.sp),
                  decoration: InputDecoration(
                    labelText: 'Search by NAME or BARCODE',
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
                  onChanged: (_) => _filterProducts(),
                ),
                _filteredProducts.isEmpty
                    ? const Text("Press clear data + fully sync to get data.")
                    : Container(
                      height: 80.h,
                      child: ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final key = product.stokKodu;
                          final isBox = _isBoxMap[key] ?? false;
                          // final quantity = _quantityMap[key] ?? 0;
                          // final iskonto = _iskontoMap[key] ?? 0;
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
                                            (context) => AlertDialog(
                                              title: Text(
                                                product.urunAdi,
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
  return await file.exists() ? filePath : null;
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
                                                  Text(
                                                    "Unit Price: ${product.adetFiyati}",
                                                  ),
                                                  Text(
                                                    "Box Price: ${product.kutuFiyati}",
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
                                                product.urunAdi,
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              SizedBox(height: 0.5.h),
                                              // Text(
                                              //   "Barcodes: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}",
                                              //   style: TextStyle(fontSize: 11.sp),
                                              // ),
                                              Text(
                                                "Unit Price: ${product.adetFiyati}",
                                                style: TextStyle(
                                                  fontSize: 17.sp,
                                                ),
                                              ),
                                              Text(
                                                "Box Price: ${product.kutuFiyati}",
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
                                            value: provider.getBirimTipi(
                                              product.stokKodu,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Unit',
                                                child: Text('Unit'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Box',
                                                child: Text('Box'),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              final bool newValue =
                                                  (val == 'Unit');
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
                                                            product.adetFiyati
                                                                .toString(),
                                                          )
                                                      : double.parse(
                                                            product.kutuFiyati
                                                                .toString(),
                                                          );
                                              print("zzzzzzzzz $productFiyat");
                                              final miktar =
                                                  _quantityMap[key] ?? 0;
                                              print(
                                                "objectttttttttttt $miktar",
                                              );

                                              if (miktar > 0) {

                                                  final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                                                        provider.customerName = customerProvider.selectedCustomer!.kod!;
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
                                                      product.barcode1,
                                                  miktar: 0,
                                                  iskonto:
                                                      _iskontoMap[key] ?? 0,
                                                  birimTipi: val!,
                                                );
                                              } else if (miktar == 0) {
                                                setState(() {
                                                  _quantityMap[key] =
                                                      _quantityMap[key]! + 1;
                                                });                                                  final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                                                        provider.customerName = customerProvider.selectedCustomer!.kod!;
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
                                                      product.barcode1,
                                                  miktar: 1,
                                                  iskonto:
                                                      _iskontoMap[key] ?? 0,
                                                  birimTipi: val!,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_offer,
                                            size: 20.sp,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 1.w),
                                          SizedBox(
                                            width: 17.w,
                                            child: TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: TextEditingController(
                                                text:
                                                    provider
                                                        .getIskonto(key)
                                                        .toString(),
                                              ),
                                              decoration: InputDecoration(
                                                suffixText: '%',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              style: TextStyle(fontSize: 18.sp),
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
                                                              product.kutuFiyati
                                                                  .toString(),
                                                            ) ??
                                                            0
                                                        : double.tryParse(
                                                              product.adetFiyati
                                                                  .toString(),
                                                            ) ??
                                                            0;

                                                final barcode =
                                                    product.barcode1;

                                                final miktar =
                                                    _quantityMap[key] ?? 0;
                                                print(
                                                  "objectttttttttttt $miktar",
                                                );
                                                int artir = 0;
                                                if (miktar == 0 &&
                                                    clamped != 0) {
                                                  artir = 1;
                                                }                                                  final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                                                        provider.customerName = customerProvider.selectedCustomer!.kod!;
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
                                              if (_quantityMap[key]! > 0) {
                                                setState(() {
                                                  _quantityMap[key] =
                                                      _quantityMap[key]! - 1;
                                                });

                                                final isBox =
                                                    _isBoxMap[key] ?? false;
                                                final iskonto =
                                                    _iskontoMap[key] ?? 0;

                                                // final birimTipi =
                                                //     isBox ? 'Unit' : 'Box';

                                                final fiyat =
                                                    isBox
                                                        ? double.parse(
                                                              product.adetFiyati
                                                                  .toString(),
                                                            )
                                                        : double.parse(
                                                              product.kutuFiyati
                                                                  .toString(),
                                                            );

                                                final barcode =
                                                    product.barcode1;
                                                final provider =
                                                    Provider.of<CartProvider>(
                                                      context,
                                                      listen: false,
                                                    );
                                                  final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                                                        provider.customerName = customerProvider.selectedCustomer!.kod!;
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
                                                    "${Provider.of<CartProvider>(context, listen: true).items[key]?.miktar ?? 0}",
                                              ),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 18.sp),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.zero,
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
                                                  final provider =
                                                      Provider.of<CartProvider>(
                                                        context,
                                                        listen: false,
                                                      );                                                  final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                                                        provider.customerName = customerProvider.selectedCustomer!.kod!;
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
                                                        product.barcode1,
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
                                                  Provider.of<CartProvider>(
                                                    context,
                                                    listen: false,
                                                  );    
                                                                                                final customerProvider =
                              Provider.of<SalesCustomerProvider>(
                                context,
                                listen: false,
                              );
                                                        provider.customerName = customerProvider.selectedCustomer!.kod!;
                                              provider.addOrUpdateItem(
                                                urunAdi: product.urunAdi,
                                                adetFiyati: product.adetFiyati,
                                                kutuFiyati: product.kutuFiyati,
                                                stokKodu: key,
                                                vat: product.vat,

                                                birimFiyat:
                                                    isBox
                                                        ? double.tryParse(
                                                              product.adetFiyati
                                                                  .toString(),
                                                            ) ??
                                                            0
                                                        : double.tryParse(
                                                              product.kutuFiyati
                                                                  .toString(),
                                                            ) ??
                                                            0,
                                                imsrc: product.imsrc,
                                                urunBarcode:
                                                    product.barcode1,
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
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String barcode) onScanned;

  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isScanning = true;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _isScanning = false;
      widget.onScanned(rawValue);
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
