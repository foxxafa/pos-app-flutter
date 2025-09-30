import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/cart/presentation/cart_view2.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/widgets/barcode_scanner_page.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/sync/presentation/sync_controller.dart';
import 'dart:io';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

/// Müşterinin daha önce aldığı ürünlere göre ürün önerileri sunan sayfa.
class CartsuggestionView extends StatefulWidget {
  final String musteriId;

  const CartsuggestionView({super.key, required this.musteriId});

  @override
  State<CartsuggestionView> createState() => _CartsuggestionViewState();
}

class _CartsuggestionViewState extends State<CartsuggestionView> {
  // --- State Variables ---
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _discountFocusNodes = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  bool _isLoading = true;

  // cart_view2.dart'tan eklenen image download timer
  Timer? _imageDownloadTimer;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceControllers.values.forEach((c) => c.dispose());
    _discountControllers.values.forEach((c) => c.dispose());
    _quantityControllers.values.forEach((c) => c.dispose());
    _discountFocusNodes.values.forEach((f) => f.dispose());
    _quantityFocusNodes.values.forEach((f) => f.dispose());
    _imageDownloadTimer?.cancel(); // Timer'ı iptal et
    super.dispose();
  }

  // --- Data Loading ---
  Future<void> _loadProducts() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final refundRows = await db.query('Refunds');
    final refundStokKodlari = refundRows
        .map((row) => row['stokKodu'] as String?)
        .where((e) => e != null && e.isNotEmpty)
        .toSet()
        .toList();

    final rawProducts = await db.query('Product');
    final allProducts = rawProducts.map((e) => ProductModel.fromMap(e)).toList();
    final suggestedProducts = allProducts.where((p) => refundStokKodlari.contains(p.stokKodu) && p.aktif == 1).toList();

    suggestedProducts.sort((a, b) => a.urunAdi.compareTo(b.urunAdi));

    setState(() {
      _allProducts = suggestedProducts;
      _filteredProducts = suggestedProducts;
      _isLoading = false;
      _generateImageFutures(suggestedProducts);
      _downloadMissingImages(suggestedProducts); // Resimleri indir
    });
  }

  // --- Image Handling ---
  void _generateImageFutures(List<ProductModel> products, {bool forceUpdate = false}) {
    for (final product in products) {
      final stokKodu = product.stokKodu;
      if (!_imageFutures.containsKey(stokKodu) || forceUpdate) {
        _imageFutures[stokKodu] = _loadImage(product.imsrc);
      }
    }
  }

  // cart_view2.dart'tan eklenen resim indirme metodu
  void _downloadMissingImages(List<ProductModel> products) {
    _imageDownloadTimer?.cancel();
    _imageDownloadTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        SyncController.downloadSearchResultImages(products, onImagesDownloaded: () {
          if (mounted) {
            setState(() {
              _generateImageFutures(products, forceUpdate: true);
            });
          }
        });
      }
    });
  }

  Future<String?> _loadImage(String? imsrc) async {
    try {
      if (imsrc == null || imsrc.isEmpty) return null;
      final uri = Uri.parse(imsrc);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (fileName.isEmpty) return null;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      return await file.exists() ? filePath : null;
    } catch (_) {
      return null;
    }
  }

  // --- Filtering & Searching ---
  void _filterProducts({String? queryOverride}) {
    final query = (queryOverride ?? _searchController.text).trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredProducts = _allProducts);
      return;
    }

    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
    final filtered = _allProducts.where((product) {
      final name = product.urunAdi.toLowerCase();
      final stokKodu = product.stokKodu.toLowerCase(); // Stok kodu araması ekle
      final barcodes = [product.barcode1, product.barcode2, product.barcode3, product.barcode4]
          .map((b) => b.toLowerCase())
          .toList();
      return queryWords.every((word) =>
        name.contains(word) ||
        stokKodu.contains(word) || // Stok kodunda ara
        barcodes.any((b) => b.contains(word))
      );
    }).toList();

    setState(() {
      _filteredProducts = filtered;
      _generateImageFutures(filtered);
      _downloadMissingImages(filtered); // Filtrelenmiş ürünler için resimleri indir
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterProducts(queryOverride: "");
  }

  // --- Barcode Scanning ---
  void _onBarcodeScanned(String barcode) {
    if (!mounted) return;
    _searchController.text = barcode;
    _filterProducts();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openBarcodeScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(onScanned: _onBarcodeScanned),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CartProvider>(context);
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    final cartItems = provider.items.values.toList();
    final unitCount = cartItems.where((i) => i.birimTipi == 'Unit').fold<int>(0, (p, i) => p + i.miktar);
    final boxCount = cartItems.where((i) => i.birimTipi == 'Box').fold<int>(0, (p, i) => p + i.miktar);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'cart.search_placeholder'.tr(),
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7), size: 20),
                      onPressed: _clearSearch,
                    ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: Colors.white.withValues(alpha: 0.9), size: 22),
                    onPressed: _openBarcodeScanner,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            onChanged: (value) => _filterProducts(queryOverride: value),
          ),
        ),
        actions: [
          _buildShoppingCartIcon(cartItems.length, unitCount + boxCount),
        ],
      ),
      body: Column(
        children: [
          if (customer != null) _buildCustomerHeader(customer),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredProducts.isEmpty
                ? _buildNoProductsFound()
                : _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(dynamic customer) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        customer.unvan ?? 'N/A',
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildShoppingCartIcon(int itemCount, int totalQuantity) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartView2())),
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 18.w,
        height: 10.h,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 8.w),
            _buildBadge(itemCount.toString(), Colors.blue, isTop: true),
            _buildBadge(totalQuantity.toString(), Colors.orange, isTop: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {required bool isTop}) {
    return Positioned(
      right: 1.w,
      top: isTop ? 0.2.h : null,
      bottom: isTop ? null : 0.2.h,
      child: Container(
        padding: EdgeInsets.all(0.4.w),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        constraints: BoxConstraints(minWidth: 6.w, minHeight: 6.w),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
          SizedBox(height: 2.h),
          Text('cart.loading_products'.tr()),
        ],
      ),
    );
  }

  Widget _buildNoProductsFound() {
    return Center(child: Text('cart.no_products_found'.tr()));
  }

  Widget _buildProductList() {
    final cartProvider = Provider.of<CartProvider>(context);
    final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final stokKodu = product.stokKodu;

        // Find the correct cart item by checking both unit types
        CartItem? cartItem = cartProvider.items[stokKodu];
        final birimTipi = cartItem?.birimTipi ?? (product.birimKey2 != 0 ? 'Box' : 'Unit');

        final controllerKey = '${stokKodu}_$birimTipi';

        // Initialize controllers
        _priceControllers[controllerKey] ??= TextEditingController();
        _discountControllers[controllerKey] ??= TextEditingController();
        _discountFocusNodes[controllerKey] ??= FocusNode();

        // Miktar controller'ı için de ekle
        final quantityControllerKey = '${stokKodu}_${birimTipi}_quantity';
        _quantityControllers[quantityControllerKey] ??= TextEditingController();
        _quantityFocusNodes[quantityControllerKey] ??= FocusNode();

        final priceController = _priceControllers[controllerKey]!;
        final discountController = _discountControllers[controllerKey]!;
        final discountFocusNode = _discountFocusNodes[controllerKey]!;
        final quantityController = _quantityControllers[quantityControllerKey]!;
        final quantityFocusNode = _quantityFocusNodes[quantityControllerKey]!;

        // cart_view2.dart mantığı: Controller'ları sadece ilk kez doldur
        // İlk kez oluşturuluyorsa controller'a değer ata
        if (priceController.text.isEmpty) {
          if (cartItem != null) {
            final discountAmount = (cartItem.birimFiyat * cartItem.iskonto) / 100;
            final discountedPrice = cartItem.birimFiyat - discountAmount;
            priceController.text = discountedPrice.toStringAsFixed(2);
          } else {
            final orjinalFiyat = birimTipi == 'Unit'
                ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
                : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;
            priceController.text = orjinalFiyat.toStringAsFixed(2);
          }
        }

        // İndirim controller'ını sadece ilk kez doldur, sonra kullanıcıya bırak
        if (discountController.text.isEmpty && !discountFocusNode.hasFocus) {
          discountController.text = cartItem?.iskonto != null && cartItem!.iskonto > 0
              ? cartItem.iskonto.toString()
              : '';
        }

        return Container(
          padding: EdgeInsets.all(2.w),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Product Image
                  SizedBox(
                    width: 30.w,
                    height: 30.w,
                    child: FutureBuilder<String?>(
                      future: _imageFutures[stokKodu],
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: Icon(Icons.image_outlined, size: 20, color: Colors.grey));
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(File(snapshot.data!), fit: BoxFit.cover),
                          );
                        }
                        return Icon(Icons.shopping_bag, size: 25.w, color: Colors.grey);
                      },
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Right: Details and Controls
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name and Delete Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product.urunAdi,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (cartItem != null)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => cartProvider.removeItem(stokKodu, birimTipi),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                iconSize: 2.2.h,
                              ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        // Price and Discount Row
                        Row(
                          children: [
                            // Unit Selector
                            _buildUnitSelector(product, cartItem, cartProvider, customerProvider),
                            SizedBox(width: 2.w),
                            // Price Field
                            Expanded(
                              flex: 2,
                              child: _buildPriceField(product, cartItem, priceController, discountController, discountFocusNode, cartProvider, customerProvider),
                            ),
                            SizedBox(width: 2.w),
                            // Discount Field
                            Expanded(
                              flex: 2,
                              child: _buildDiscountField(product, cartItem, priceController, discountController, discountFocusNode, cartProvider, customerProvider),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        // Quantity Controls - controller'ları da gönder
                        _buildQuantityControls(product, cartItem, cartProvider, customerProvider, quantityController, quantityFocusNode),
                      ],
                    ),
                  ),
                ],
              ),
              if(cartItem != null) ...[
                Divider(),
                Center(
                  child: Text(
                    'Final Price: ${(cartItem.indirimliTutar * cartItem.miktar).toStringAsFixed(2)} - VAT:${(cartItem.vatTutari * cartItem.miktar).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, fontStyle: FontStyle.italic),
                  ),
                ),
              ]
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        height: 1,
      ),
    );
  }

  Widget _buildUnitSelector(ProductModel product, CartItem? cartItem, CartProvider cartProvider, SalesCustomerProvider customerProvider) {
    final hasUnit = product.birimKey1 != 0;
    final hasBox = product.birimKey2 != 0;
    final availableUnits = (hasUnit ? 1 : 0) + (hasBox ? 1 : 0);
    final birimTipi = cartItem?.birimTipi ?? (hasBox ? 'Box' : 'Unit');

    if (availableUnits <= 1) {
      return Container(
        height: 40, // Fiyat alanının gerçek yüksekliği (isDense + contentPadding)
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            birimTipi,
            style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Container(
      height: 40, // Fiyat alanının gerçek yüksekliği (isDense + contentPadding)
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: DropdownButton<String>(
          value: birimTipi,
          isDense: true,
          underline: Container(),
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
          items: [
            if (hasUnit) DropdownMenuItem(value: 'Unit', child: Text('Unit')),
            if (hasBox) DropdownMenuItem(value: 'Box', child: Text('Box')),
          ],
          onChanged: (newValue) {
            if (newValue != null && cartItem != null) {
              final fiyat = (newValue == 'Unit')
                  ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
                  : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;

              cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
              cartProvider.addOrUpdateItem(
                urunAdi: product.urunAdi, stokKodu: product.stokKodu, birimFiyat: fiyat, urunBarcode: product.barcode1,
                adetFiyati: product.adetFiyati, kutuFiyati: product.kutuFiyati, miktar: 0, iskonto: cartItem.iskonto,
                birimTipi: newValue, vat: product.vat, imsrc: product.imsrc, birimKey1: product.birimKey1, birimKey2: product.birimKey2,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPriceField(ProductModel product, CartItem? cartItem, TextEditingController priceController, TextEditingController discountController, FocusNode discountFocusNode, CartProvider cartProvider, SalesCustomerProvider customerProvider) {
    final birimTipi = cartItem?.birimTipi ?? (product.birimKey2 != 0 ? 'Box' : 'Unit');

    // cart_view2.dart mantığı: Controller zaten üstte dolduruldu, burada tekrar güncelleme
    // Build method'da oluyor, burada sadece TextField widget'ını döndürüyoruz

    return TextField(
      controller: priceController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
      onChanged: (value) {
        // Eğer alan boşsa, kullanıcının yazmaya devam etmesine izin ver
        if (value.isEmpty) {
          return; // Hiçbir şey yapma, kullanıcı yazmaya devam edecek
        }

        final yeniFiyat = double.tryParse(value.replaceAll(',', '.'));
        if (yeniFiyat == null || yeniFiyat < 0) {
          return; // Geçersiz değer, işlem yapma
        }

        // cart_view2.dart mantığı: orjinal fiyat her zaman ürünün kendi fiyatı
        var orjinalFiyatHesap = birimTipi == 'Unit'
            ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
            : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;

        if (orjinalFiyatHesap <= 0) orjinalFiyatHesap = yeniFiyat;

        final indirimOrani = (orjinalFiyatHesap > 0 && yeniFiyat < orjinalFiyatHesap)
            ? ((orjinalFiyatHesap - yeniFiyat) / orjinalFiyatHesap * 100).round()
            : 0;

        if (!discountFocusNode.hasFocus) {
          discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';
        }

        cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
        cartProvider.addOrUpdateItem(
          stokKodu: product.stokKodu,
          urunAdi: product.urunAdi,
          birimFiyat: orjinalFiyatHesap, // Orijinal fiyatı gönder
          urunBarcode: product.barcode1,
          miktar: 0,
          iskonto: indirimOrani,
          birimTipi: birimTipi,
          vat: product.vat,
          imsrc: product.imsrc,
          adetFiyati: product.adetFiyati,
          kutuFiyati: product.kutuFiyati,
          birimKey1: product.birimKey1,
          birimKey2: product.birimKey2,
        );
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
      },
      onSubmitted: (value) {
        // Submit edildiğinde formatlama
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          priceController.text = parsed.toStringAsFixed(2);
        }
      },
    );
  }

  Widget _buildDiscountField(ProductModel product, CartItem? cartItem, TextEditingController priceController, TextEditingController discountController, FocusNode discountFocusNode, CartProvider cartProvider, SalesCustomerProvider customerProvider) {
    return Row(
      children: [
        Icon(Icons.local_offer, size: 18.sp, color: Theme.of(context).colorScheme.error),
        SizedBox(width: 1.w),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            controller: discountController,
            focusNode: discountFocusNode,
            decoration: InputDecoration(
              prefixText: '%',
              prefixStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onChanged: (value) {
              final birimTipi = cartItem?.birimTipi ?? (product.birimKey2 != 0 ? 'Box' : 'Unit');

              // cart_view2.dart mantığı: orjinal fiyat her zaman ürünün birim fiyatı
              final originalPrice = birimTipi == 'Unit'
                  ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
                  : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;

              if (value.isEmpty) {
                priceController.text = originalPrice.toStringAsFixed(2);
                cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
                cartProvider.addOrUpdateItem(
                  stokKodu: product.stokKodu,
                  miktar: 0,
                  iskonto: 0,
                  birimTipi: birimTipi,
                  urunAdi: product.urunAdi,
                  birimFiyat: originalPrice,
                  vat: product.vat,
                  imsrc: product.imsrc,
                  adetFiyati: product.adetFiyati,
                  kutuFiyati: product.kutuFiyati,
                  urunBarcode: product.barcode1,
                  birimKey1: product.birimKey1,
                  birimKey2: product.birimKey2
                );
                return;
              }

              int discountPercent = int.tryParse(value) ?? 0;
              discountPercent = discountPercent.clamp(0, 100);

              // İndirimli fiyatı hesapla
              final discountAmount = (originalPrice * discountPercent) / 100;
              final discountedPrice = originalPrice - discountAmount;
              priceController.text = discountedPrice.toStringAsFixed(2);

              cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
              cartProvider.addOrUpdateItem(
                stokKodu: product.stokKodu,
                miktar: 0,
                iskonto: discountPercent,
                birimTipi: birimTipi,
                urunAdi: product.urunAdi,
                birimFiyat: originalPrice, // Her zaman orijinal fiyatı gönder
                vat: product.vat,
                imsrc: product.imsrc,
                adetFiyati: product.adetFiyati,
                kutuFiyati: product.kutuFiyati,
                urunBarcode: product.barcode1,
                birimKey1: product.birimKey1,
                birimKey2: product.birimKey2,
              );

              // İmleç pozisyonunu koru
              final cursorPos = discountController.selection.baseOffset;
              if (cursorPos >= 0 && cursorPos <= discountController.text.length) {
                discountController.selection = TextSelection.fromPosition(
                  TextPosition(offset: cursorPos),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(ProductModel product, CartItem? cartItem, CartProvider cartProvider, SalesCustomerProvider customerProvider, TextEditingController quantityController, FocusNode quantityFocusNode) {
    // Her zaman provider'dan güncel miktarı al
    final birimTipi = cartItem?.birimTipi ?? (product.birimKey2 != 0 ? 'Box' : 'Unit');

    // Provider'dan güncel miktarı al (context.watch kullanarak dinamik güncelleme)
    final currentMiktar = context.watch<CartProvider>().getmiktar(product.stokKodu, birimTipi);

    // Controller'ın değerini güncelle (focus yoksa)
    if (!quantityFocusNode.hasFocus && quantityController.text != currentMiktar.toString()) {
      quantityController.text = currentMiktar.toString();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease Button
        _quantityButton(
          icon: Icons.remove,
          color: Theme.of(context).colorScheme.error,
          onPressed: currentMiktar > 0 ? () {
            cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
            cartProvider.addOrUpdateItem(
                urunAdi: product.urunAdi, stokKodu: product.stokKodu, birimFiyat: 0, miktar: -1,
                iskonto: cartItem?.iskonto ?? 0, birimTipi: birimTipi, urunBarcode: product.barcode1,
                adetFiyati: product.adetFiyati, kutuFiyati: product.kutuFiyati, vat: product.vat,
                imsrc: product.imsrc, birimKey1: product.birimKey1, birimKey2: product.birimKey2
            );
          } : null,
        ),
        SizedBox(width: 1.w),
        // Quantity TextField - artık manuel giriş yapılabilir
        Container(
          width: 12.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: quantityController,
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
                cartProvider.removeItem(product.stokKodu, birimTipi);
              } else {
                final difference = newMiktar - currentMiktar;
                if (difference != 0) {
                  final fiyat = birimTipi == 'Unit'
                      ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
                      : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;

                  cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
                  cartProvider.addOrUpdateItem(
                    urunAdi: product.urunAdi,
                    stokKodu: product.stokKodu,
                    birimFiyat: fiyat,
                    miktar: difference, // Farkı gönder
                    iskonto: cartItem?.iskonto ?? 0,
                    birimTipi: birimTipi,
                    urunBarcode: product.barcode1,
                    adetFiyati: product.adetFiyati,
                    kutuFiyati: product.kutuFiyati,
                    vat: product.vat,
                    imsrc: product.imsrc,
                    birimKey1: product.birimKey1,
                    birimKey2: product.birimKey2,
                  );
                }
              }
            },
          ),
        ),
        SizedBox(width: 1.w),
        // Increase Button
        _quantityButton(
          icon: Icons.add,
          color: Theme.of(context).colorScheme.primary,
          onPressed: () {
            final fiyat = birimTipi == 'Unit'
                ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
                : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;

            cartProvider.customerName = customerProvider.selectedCustomer!.kod!;
            cartProvider.addOrUpdateItem(
                urunAdi: product.urunAdi, stokKodu: product.stokKodu, birimFiyat: fiyat, miktar: 1,
                iskonto: cartItem?.iskonto ?? 0, birimTipi: birimTipi, urunBarcode: product.barcode1,
                adetFiyati: product.adetFiyati, kutuFiyati: product.kutuFiyati, vat: product.vat,
                imsrc: product.imsrc, birimKey1: product.birimKey1, birimKey2: product.birimKey2
            );
          },
        ),
      ],
    );
  }

  Widget _quantityButton({required IconData icon, required Color color, required VoidCallback? onPressed}) {
    return Container(
      width: 12.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onPressed,
          icon: Icon(icon, size: 6.w, color: onPressed != null ? color : Colors.grey),
        ),
      ),
    );
  }
}

