import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/models/refundlist_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/views/cart_view2.dart';
import 'package:pos_app/views/cartsuggestion_view.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:sizer/sizer.dart';
import '../models/product_model.dart';
import '../providers/cartcustomer_provider.dart';
import '../controllers/sync_controller.dart';
import 'dart:io';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
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
  // --- State Variables ---
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, FocusNode> _discountFocusNodes = {};
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _barcodeFocusNode2 = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  bool _isLoading = true;

  final Map<String, bool> _isBoxMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  Timer? _imageDownloadTimer;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _setupAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
      _syncWithProvider();
    });
  }

  void _setupAudioPlayer() {
    _audioPlayer.setVolume(0.8); // %80 sabit ses seviyesi
  }

  @override
  void dispose() {
    _imageDownloadTimer?.cancel();
    _barcodeFocusNode.dispose();
    _barcodeFocusNode2.dispose();
    _searchController.dispose();
    _searchController2.dispose();
    _priceControllers.values.forEach((c) => c.dispose());
    _discountControllers.values.forEach((c) => c.dispose());
    _quantityControllers.values.forEach((c) => c.dispose());
    _discountFocusNodes.values.forEach((f) => f.dispose());
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- Product & Data Loading ---
  Future<void> _loadProducts() async {
    final raw = await DatabaseHelper().getAll("Product");
    final allProducts = raw.map((e) => ProductModel.fromMap(e)).toList();
    final activeProducts = allProducts.where((p) => p.aktif == 1).toList();

    activeProducts.sort((a, b) {
      final nameA = a.urunAdi;
      final nameB = b.urunAdi;
      final startsWithLetterA = RegExp(r'^[a-zA-ZğüşöçİĞÜŞÖÇ]').hasMatch(nameA);
      final startsWithLetterB = RegExp(r'^[a-zA-ZğüşöçİĞÜŞÖÇ]').hasMatch(nameB);

      if (startsWithLetterA && !startsWithLetterB) return -1;
      if (!startsWithLetterA && startsWithLetterB) return 1;
      return nameA.compareTo(nameB);
    });

    setState(() {
      _allProducts = activeProducts;
      _filteredProducts = activeProducts.take(50).toList();
      _isLoading = false;

      for (var product in activeProducts) {
        final key = product.stokKodu;
        _isBoxMap[key] = product.birimKey2 != 0;
        _quantityMap[key] = 0;
      }
      _generateImageFutures(_filteredProducts);
    });
  }

  void _syncWithProvider() {
    final provider = Provider.of<CartProvider>(context, listen: false);
    setState(() {
      for (var product in _allProducts) {
        final key = product.stokKodu;
        final isBox = _isBoxMap[key] ?? false;
        final birimTipi = isBox ? 'Box' : 'Unit';

        final miktar = provider.getmiktar(key, birimTipi);
        final iskonto = provider.getIskonto(key);

        _quantityMap[key] = miktar;

        _quantityControllers[key]?.text = miktar.toString();
        _discountControllers[key]?.text = iskonto > 0 ? iskonto.toString() : '';
        if (_priceControllers.containsKey(key) && miktar == 0) {
          final selectedType = getBirimTipiFromProduct(product);
          _priceControllers[key]!.text = selectedType == 'Unit'
              ? (double.tryParse(product.adetFiyati.toString()) ?? 0).toStringAsFixed(2)
              : (double.tryParse(product.kutuFiyati.toString()) ?? 0).toStringAsFixed(2);
        }
      }
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

  void _scheduleImageDownload() {
    _imageDownloadTimer?.cancel();
    _imageDownloadTimer = Timer(const Duration(milliseconds: 500), () {
      if (_filteredProducts.isNotEmpty && mounted) {
        SyncController.downloadSearchResultImages(_filteredProducts, onImagesDownloaded: () {
          if (mounted) {
            setState(() {
              _generateImageFutures(_filteredProducts, forceUpdate: true);
            });
          }
        });
      }
    });
  }

  // --- Sound & Barcode ---
  Future<void> playWrong() async {
    await _audioPlayer.play(AssetSource('wrong.mp3'));
  }

  Future<void> playBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  void _onBarcodeScanned(String barcode) {
    if (!mounted) return; // Widget dispose edilmişse çık
    
    _searchController.text = barcode;
    _filterProducts(queryOverride: barcode);
    
    // Barkod sonucuna göre ses çal
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return; // Widget hala mevcut mu kontrol et
      
      final query = barcode.trimRight().toLowerCase();
      final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
      final filtered = _allProducts.where((product) {
        final name = product.urunAdi.toLowerCase();
        final barcodes = [product.barcode1, product.barcode2, product.barcode3, product.barcode4]
            .map((b) => b.toLowerCase())
            .toList();
        return queryWords.every((word) => name.contains(word) || barcodes.any((b) => b.contains(word)));
      }).toList();

      if (filtered.isNotEmpty) {
        playBeep(); // Ürün bulundu - beep sesi
      } else {
        playWrong(); // Ürün bulunamadı - wrong sesi
      }
    });
  }

  Future<void> _openBarcodeScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(onScanned: _onBarcodeScanned),
      ),
    );
  }

  // --- Filtering & Searching ---
  void _filterProducts({String? queryOverride}) {
    final provider = Provider.of<CartProvider>(context, listen: false);
    final query = (queryOverride ?? _searchController.text).trimRight().toLowerCase();
    final fromUI = queryOverride != null;

    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts.take(50).toList();
        _generateImageFutures(_filteredProducts);
      });
      return;
    }

    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
    final filtered = _allProducts.where((product) {
      final name = product.urunAdi.toLowerCase();
      final barcodes = [product.barcode1, product.barcode2, product.barcode3, product.barcode4]
          .map((b) => b.toLowerCase())
          .toList();
      return queryWords.every((word) => name.contains(word) || barcodes.any((b) => b.contains(word)));
    }).toList();

    filtered.sort((a, b) {
      final aName = a.urunAdi;
      final bName = b.urunAdi;
      final aStartsWithLetter = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(aName);
      final bStartsWithLetter = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(bName);
      if (aStartsWithLetter && !bStartsWithLetter) return -1;
      if (!aStartsWithLetter && bStartsWithLetter) return 1;
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    setState(() {
      _filteredProducts = filtered.take(50).toList();
      _generateImageFutures(_filteredProducts);
    });

    _scheduleImageDownload();

    if (!fromUI) {
      if (_filteredProducts.length == 1 && RegExp(r'^\d+$').hasMatch(query)) {
        final product = _filteredProducts.first;
        final key = product.stokKodu;
        final isBox = _isBoxMap[key] ?? (product.birimKey2 != 0);
        final birimTipi = isBox ? 'Box' : 'Unit';

        if ((birimTipi == 'Unit' && product.birimKey1 != 0) || (birimTipi == 'Box' && product.birimKey2 != 0)) {
          final cartItem = provider.items[key];
          final iskonto = cartItem?.iskonto ?? 0;
          provider.addOrUpdateItem(
            urunAdi: product.urunAdi,
            adetFiyati: product.adetFiyati,
            kutuFiyati: product.kutuFiyati,
            stokKodu: key,
            vat: product.vat,
            birimFiyat: isBox
                ? double.tryParse(product.kutuFiyati.toString()) ?? 0
                : double.tryParse(product.adetFiyati.toString()) ?? 0,
            imsrc: product.imsrc,
            urunBarcode: product.barcode1,
            miktar: 1,
            iskonto: iskonto,
            birimTipi: birimTipi,
            birimKey1: product.birimKey1,
            birimKey2: product.birimKey2,
          );
        }
        _clearAndFocusBarcode();
      } else if (_filteredProducts.isEmpty && query.length > 10 && RegExp(r'^\d+$').hasMatch(query)) {
        playWrong();
        _clearAndFocusBarcode();
      }
    }
  }

  void _clearAndFocusBarcode() {
    _searchController.clear();
    _searchController2.clear();
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _barcodeFocusNode.requestFocus();
    });
  }

  // --- UI Helper Methods ---
  void _clearSearch2() {
    _searchController2.clear();
    _filterProducts(queryOverride: "");
  }

  void _updateQuantityFromTextField(String key, String value, ProductModel product) {
    final provider = Provider.of<CartProvider>(context, listen: false);
    final newQuantity = int.tryParse(value) ?? 0;
    final isBox = _isBoxMap[key] ?? false;
    final birimTipi = isBox ? 'Box' : 'Unit';

    final currentQuantity = provider.getmiktar(key, birimTipi);
    final difference = newQuantity - currentQuantity;

    if (difference == 0) return;

    if (newQuantity <= 0) {
      provider.removeItem(key, birimTipi);
    } else {
      final fiyat = isBox
          ? double.tryParse(product.kutuFiyati.toString()) ?? 0
          : double.tryParse(product.adetFiyati.toString()) ?? 0;

      final cartItem = provider.items[key];
      final iskonto = cartItem?.iskonto ?? provider.getIskonto(key);

      provider.addOrUpdateItem(
        urunAdi: product.urunAdi,
        stokKodu: key,
        birimFiyat: fiyat,
        adetFiyati: product.adetFiyati,
        kutuFiyati: product.kutuFiyati,
        vat: product.vat,
        urunBarcode: product.barcode1,
        miktar: difference, // Send the difference
        iskonto: iskonto,
        birimTipi: birimTipi,
        imsrc: product.imsrc,
        birimKey1: product.birimKey1,
        birimKey2: product.birimKey2,
      );
    }
    setState(() {
      _quantityMap[key] = newQuantity;
    });
  }

  void _formatPriceField(TextEditingController controller) {
    final value = controller.text.replaceAll(',', '.');
    final parsed = double.tryParse(value);
    if (parsed != null) {
      controller.text = parsed.toStringAsFixed(2);
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  }

  String? getBirimTipiFromProduct(ProductModel product) {
    final key = product.stokKodu;
    final isBox = _isBoxMap[key] ?? (product.birimKey2 != 0); // Default to box if available
    if (isBox && product.birimKey2 != 0) return 'Box';
    if (!isBox && product.birimKey1 != 0) return 'Unit';
    if (product.birimKey2 != 0) return 'Box';
    if (product.birimKey1 != 0) return 'Unit';
    return null;
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CartProvider>(context);
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    String musteriId = customer?.kod ?? "";
    final cartItems = provider.items.values.toList();
    final unitCount = cartItems.where((i) => i.birimTipi == 'Unit').fold<int>(0, (p, i) => p + i.miktar);
    final boxCount = cartItems.where((i) => i.birimTipi == 'Box').fold<int>(0, (p, i) => p + i.miktar);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, size: 25.sp),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartsuggestionView(musteriId: musteriId)),
          ),
        ),
        title: SizedBox(
          height: 40,
          child: TextField(
            focusNode: _barcodeFocusNode2,
            controller: _searchController2,
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'cart.search_placeholder'.tr(),
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController2.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7), size: 20),
                      onPressed: _clearSearch2,
                    ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: Colors.white.withOpacity(0.9), size: 22),
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
      body: Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            final sunmiScanKeyIds = {
              0x01100000209, 0x01100000208, 4294967556, 73014445159, 4294967309
            };
            if (sunmiScanKeyIds.contains(event.logicalKey.keyId)) {
              _clearAndFocusBarcode();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  focusNode: _barcodeFocusNode,
                  controller: _searchController,
                  onChanged: (value) => _filterProducts(),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _filteredProducts.isEmpty
                  ? _buildNoProductsFound()
                  : _buildProductList(provider),
            ),
          ],
        ),
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
    return Center(child: Text('cart.no_products'.tr()));
  }

  Widget _buildProductList(CartProvider provider) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final key = product.stokKodu;

        if (!_priceControllers.containsKey(key)) {
          final cartItem = provider.items[key];
          final selectedType = getBirimTipiFromProduct(product);
          final initialPrice = cartItem != null
              ? cartItem.birimFiyat.toStringAsFixed(2)
              : selectedType == 'Unit'
              ? (double.tryParse(product.adetFiyati.toString()) ?? 0).toStringAsFixed(2)
              : (double.tryParse(product.kutuFiyati.toString()) ?? 0).toStringAsFixed(2);
          _priceControllers[key] = TextEditingController(text: initialPrice);
        }
        if (!_discountControllers.containsKey(key)) {
          _discountControllers[key] = TextEditingController(text: provider.getIskonto(key).toString());
        }
        if (!_discountFocusNodes.containsKey(key)) {
          _discountFocusNodes[key] = FocusNode();
        }
        if (!_quantityControllers.containsKey(key)) {
          final isBox = _isBoxMap[key] ?? false;
          final birimTipi = isBox ? 'Box' : 'Unit';
          _quantityControllers[key] = TextEditingController(text: provider.getmiktar(key, birimTipi).toString());
        }

        return ProductListItem(
          key: ValueKey(product.stokKodu),
          product: product,
          provider: provider,
          imageFuture: _imageFutures[key],
          refundProductNames: widget.refundProductNames,
          priceController: _priceControllers[key]!,
          discountController: _discountControllers[key]!,
          quantityController: _quantityControllers[key]!,
          discountFocusNode: _discountFocusNodes[key]!,
          isBox: _isBoxMap[key] ?? false,
          quantity: context.watch<CartProvider>().getmiktar(key, (_isBoxMap[key] ?? false) ? 'Box' : 'Unit'),
          onBirimTipiChanged: (isNowBox) {
            setState(() {
              _isBoxMap[key] = isNowBox;
              final newBirimTipi = isNowBox ? 'Box' : 'Unit';
              final newMiktar = provider.getmiktar(key, newBirimTipi);
              _quantityMap[key] = newMiktar;
              _quantityControllers[key]?.text = newMiktar.toString();

              final productFiyat = isNowBox
                  ? (double.tryParse(product.kutuFiyati.toString()) ?? 0)
                  : (double.tryParse(product.adetFiyati.toString()) ?? 0);
              _priceControllers[key]?.text = productFiyat.toStringAsFixed(2);
              _discountControllers[key]?.text = provider.getIskonto(key).toString();
            });
          },
          onQuantityChanged: (newQuantity) {
            setState(() {
              _quantityMap[key] = newQuantity;
            });
          },
          updateQuantityFromTextField: (value) => _updateQuantityFromTextField(key, value, product),
          formatPriceField: () => _formatPriceField(_priceControllers[key]!),
          getBirimTipi: () => getBirimTipiFromProduct(product),
        );
      },
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        thickness: 1,
        height: 1,
      ),
    );
  }
}


// --- WIDGETS ---

class ProductListItem extends StatefulWidget {
  final ProductModel product;
  final CartProvider provider;
  final Future<String?>? imageFuture;
  final List<String> refundProductNames;
  final TextEditingController priceController;
  final TextEditingController discountController;
  final TextEditingController quantityController;
  final FocusNode discountFocusNode;
  final bool isBox;
  final int quantity;
  final ValueChanged<bool> onBirimTipiChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> updateQuantityFromTextField;
  final VoidCallback formatPriceField;
  final String? Function() getBirimTipi;

  const ProductListItem({
    super.key,
    required this.product,
    required this.provider,
    this.imageFuture,
    required this.refundProductNames,
    required this.priceController,
    required this.discountController,
    required this.quantityController,
    required this.discountFocusNode,
    required this.isBox,
    required this.quantity,
    required this.onBirimTipiChanged,
    required this.onQuantityChanged,
    required this.updateQuantityFromTextField,
    required this.formatPriceField,
    required this.getBirimTipi,
  });

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  final FocusNode _quantityFocusNode = FocusNode();
  String _oldQuantityValue = '';

  @override
  void initState() {
    super.initState();
    _quantityFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _quantityFocusNode.removeListener(_onFocusChange);
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_quantityFocusNode.hasFocus) {
      _oldQuantityValue = widget.quantityController.text;
      // Clear the field on tap for easier input.
      widget.quantityController.clear();
    } else {
      if (widget.quantityController.text.isEmpty) {
        if (mounted) {
          setState(() {
            widget.quantityController.text = _oldQuantityValue;
          });
        }
      }
      // Trigger update when focus is lost to finalize any changes.
      widget.updateQuantityFromTextField(widget.quantityController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birimTipi = widget.getBirimTipi() ?? 'Unit';
    final anlikMiktar = context.watch<CartProvider>().getmiktar(widget.product.stokKodu, birimTipi);
    if (widget.quantityController.text != anlikMiktar.toString()) {
      widget.quantityController.text = anlikMiktar.toString();
    }

    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(
            imageFuture: widget.imageFuture,
            product: widget.product,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: ProductDetails(
              product: widget.product,
              provider: widget.provider,
              refundProductNames: widget.refundProductNames,
              priceController: widget.priceController,
              discountController: widget.discountController,
              quantityController: widget.quantityController,
              discountFocusNode: widget.discountFocusNode,
              quantityFocusNode: _quantityFocusNode, // Pass focus node down
              isBox: widget.isBox,
              quantity: anlikMiktar,
              onBirimTipiChanged: widget.onBirimTipiChanged,
              onQuantityChanged: widget.onQuantityChanged,
              updateQuantityFromTextField: widget.updateQuantityFromTextField,
              formatPriceField: widget.formatPriceField,
              getBirimTipi: widget.getBirimTipi,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final Future<String?>? imageFuture;
  final ProductModel product;

  const ProductImage({
    super.key,
    this.imageFuture,
    required this.product,
  });

  void _showProductInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.urunAdi),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imsrc != null)
              FutureBuilder<String?>(
                future: _getLocalImagePath(product.imsrc!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(width: 40.w, height: 40.w, child: const Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(snapshot.data!), width: 40.w, height: 40.w, fit: BoxFit.contain),
                    );
                  }
                  return Icon(Icons.shopping_bag, size: 40.w);
                },
              )
            else
              Icon(Icons.shopping_bag, size: 40.w),
            SizedBox(height: 2.h),
            SelectableText("${'cart.barcodes'.tr()}: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}"),
            Text("${'cart.code'.tr()}= ${product.stokKodu}"),
            Text("${'cart.unit_price'.tr()}= ${product.adetFiyati}"),
            Text("${'cart.box_price'.tr()}= ${product.kutuFiyati}"),
            Text("${'cart.vat'.tr()}= ${product.vat}"),
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
  }

  Future<String?> _getLocalImagePath(String imsrc) async {
    try {
      final uri = Uri.parse(imsrc);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      if (fileName == null) return null;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      return await file.exists() ? filePath : null;
    } catch (_) {
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _showProductInfoDialog(context),
      child: Column(
        children: [
          SizedBox(
            width: 30.w,
            height: 30.w,
            child: product.imsrc == null
                ? Icon(Icons.shopping_bag_sharp, size: 25.w, color: Colors.grey)
                : FutureBuilder<String?>(
              future: imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: Icon(Icons.image_outlined, size: 20, color: Colors.grey));
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(Icons.broken_image, size: 20.w, color: Colors.grey),
                    ),
                  );
                }
                return Icon(Icons.shopping_bag, size: 25.w, color: Colors.grey);
              },
            ),
          ),
          Text("${'cart.stock'.tr()}: 0/0"),
        ],
      ),
    );
  }
}


class ProductDetails extends StatelessWidget {
  final ProductModel product;
  final CartProvider provider;
  final List<String> refundProductNames;
  final TextEditingController priceController;
  final TextEditingController discountController;
  final TextEditingController quantityController;
  final FocusNode discountFocusNode;
  final FocusNode quantityFocusNode; // Add this
  final bool isBox;
  final int quantity;
  final ValueChanged<bool> onBirimTipiChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> updateQuantityFromTextField;
  final VoidCallback formatPriceField;
  final String? Function() getBirimTipi;

  const ProductDetails({
    super.key,
    required this.product,
    required this.provider,
    required this.refundProductNames,
    required this.priceController,
    required this.discountController,
    required this.quantityController,
    required this.discountFocusNode,
    required this.quantityFocusNode, // Add this
    required this.isBox,
    required this.quantity,
    required this.onBirimTipiChanged,
    required this.onQuantityChanged,
    required this.updateQuantityFromTextField,
    required this.formatPriceField,
    required this.getBirimTipi,
  });

  @override
  Widget build(BuildContext context) {
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final selectedType = getBirimTipi() ?? 'Unit';

    // Senkronizasyon
    final anlikIskonto = context.watch<CartProvider>().getIskonto(product.stokKodu);
    if (!discountFocusNode.hasFocus && discountController.text != anlikIskonto.toString()) {
      discountController.text = anlikIskonto > 0 ? anlikIskonto.toString() : '';
    }
    final anlikFiyat = context.watch<CartProvider>().getBirimFiyat(product.stokKodu, selectedType);
    if(anlikFiyat > 0 && priceController.text != anlikFiyat.toStringAsFixed(2)) {
      priceController.text = anlikFiyat.toStringAsFixed(2);
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.urunAdi,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _getProductNameColor(context),
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildUnitSelector(context),
                      SizedBox(width: 2.w),
                      Expanded(child: _buildPriceTextField(context, selectedType)),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(child: _buildDiscountTextField(context, selectedType)),
                      SizedBox(width: 2.w),
                      Flexible(child: _buildFreeItemControl(context, customer)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            _buildQuantityControl(context, selectedType),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitSelector(BuildContext context) {
    final hasUnit = product.birimKey1 != 0;
    final hasBox = product.birimKey2 != 0;
    final availableUnits = (hasUnit ? 1 : 0) + (hasBox ? 1 : 0);

    if (availableUnits <= 1) {
      final unitText = hasUnit ? 'cart.unit'.tr() : (hasBox ? 'cart.box'.tr() : '-');
      return Container(
        height: 8.w, // Match button height
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          unitText,
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      height: 8.w, // Match button height
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: getBirimTipi(),
        isDense: true,
        underline: Container(),
        style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        items: [
          if (hasUnit) DropdownMenuItem(value: 'Unit', child: Text('cart.unit'.tr())),
          if (hasBox) DropdownMenuItem(value: 'Box', child: Text('cart.box'.tr())),
        ],
        onChanged: (val) {
          if (val != null) {
            onBirimTipiChanged(val == 'Box');
          }
        },
      ),
    );
  }

  Widget _buildPriceTextField(BuildContext context, String selectedType) {
    return Container(
      height: 8.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        enabled: quantity > 0,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          final yeniFiyat = double.tryParse(value.replaceAll(',', '.')) ?? 0;
          var orjinalFiyat = selectedType == 'Unit'
              ? (double.tryParse(product.adetFiyati.toString()) ?? 0)
              : (double.tryParse(product.kutuFiyati.toString()) ?? 0);
          if (orjinalFiyat <= 0) orjinalFiyat = yeniFiyat;

          final indirimOrani = (orjinalFiyat > 0 && yeniFiyat < orjinalFiyat)
              ? ((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100).round()
              : 0;

          discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';

          provider.addOrUpdateItem(
            stokKodu: product.stokKodu,
            urunAdi: product.urunAdi,
            birimFiyat: yeniFiyat,
            urunBarcode: product.barcode1,
            miktar: 0,
            iskonto: indirimOrani,
            birimTipi: selectedType,
            vat: product.vat,
            imsrc: product.imsrc,
            adetFiyati: product.adetFiyati,
            kutuFiyati: product.kutuFiyati,
            birimKey1: product.birimKey1,
            birimKey2: product.birimKey2,
          );
        },
        onEditingComplete: formatPriceField,
        onSubmitted: (value) => formatPriceField(),
      ),
    );
  }

  Widget _buildDiscountTextField(BuildContext context, String selectedType) {
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
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            onChanged: (val) {
              if (val.isEmpty) {
                final originalPrice = selectedType == 'Unit' ? product.adetFiyati : product.kutuFiyati;
                priceController.text = (double.tryParse(originalPrice.toString()) ?? 0).toStringAsFixed(2);
                provider.addOrUpdateItem(stokKodu: product.stokKodu, miktar: 0, iskonto: 0, birimTipi: selectedType, urunAdi: product.urunAdi, birimFiyat: double.tryParse(originalPrice) ?? 0, vat: product.vat, imsrc: product.imsrc, adetFiyati: product.adetFiyati, kutuFiyati: product.kutuFiyati, urunBarcode: product.barcode1, birimKey1: product.birimKey1, birimKey2: product.birimKey2);
                return;
              }

              int discountPercent = int.tryParse(val) ?? 0;
              if (discountPercent > 100) discountPercent = 100;

              final originalPrice = selectedType == 'Unit'
                  ? (double.tryParse(product.adetFiyati.toString()) ?? 0)
                  : (double.tryParse(product.kutuFiyati.toString()) ?? 0);

              final discountedPrice = originalPrice * (1 - (discountPercent / 100));
              priceController.text = discountedPrice.toStringAsFixed(2);

              provider.addOrUpdateItem(
                  stokKodu: product.stokKodu,
                  miktar: 0,
                  iskonto: discountPercent,
                  birimTipi: selectedType,
                  urunAdi: product.urunAdi,
                  birimFiyat: discountedPrice,
                  vat: product.vat,
                  imsrc: product.imsrc,
                  adetFiyati: product.adetFiyati,
                  kutuFiyati: product.kutuFiyati,
                  urunBarcode: product.barcode1,
                  birimKey1: product.birimKey1,
                  birimKey2: product.birimKey2
              );

              if (val != discountPercent.toString()) {
                discountController.text = discountPercent.toString();
                discountController.selection = TextSelection.fromPosition(TextPosition(offset: discountController.text.length));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFreeItemControl(BuildContext context, dynamic customer) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () async => _showFreeItemDialog(context, customer),
          child: Container(
            padding: EdgeInsets.all(1.w),
            width: 15.w,
            height: 12.w,
            child: Image.asset('assets/hand.png', width: 10.w, height: 10.w),
          ),
        ),
        _buildFreeItemBadge(context, isBox: true),
        _buildFreeItemBadge(context, isBox: false),
      ],
    );
  }

  Widget _buildFreeItemBadge(BuildContext context, {required bool isBox}) {
    final type = isBox ? 'Box' : 'Unit';
    final count = provider.items.values
        .where((item) => item.urunAdi == '${product.urunAdi}_(FREE$type)' && item.birimTipi == type)
        .fold(0, (sum, item) => sum + item.miktar);

    return Positioned(
      right: -2.w,
      top: isBox ? -1.w : null,
      bottom: isBox ? null : -1.w,
      child: Container(
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: isBox ? Theme.of(context).colorScheme.secondary : Colors.orange,
          shape: BoxShape.circle,
        ),
        constraints: BoxConstraints(minWidth: 6.w, minHeight: 6.w),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _showFreeItemDialog(BuildContext context, dynamic customer) async {
    String selectedBirimTipi = product.birimKey2 != 0 ? 'Box' : 'Unit';
    final miktarController = TextEditingController(text: '1');
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
                items: [
                  if(product.birimKey1 != 0) DropdownMenuItem(value: 'Unit', child: Text('cart.unit'.tr())),
                  if(product.birimKey2 != 0) DropdownMenuItem(value: 'Box', child: Text('cart.box'.tr())),
                ],
                onChanged: (value) {
                  if (value != null) selectedBirimTipi = value;
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text('cart.cancel'.tr())),
            ElevatedButton(
              onPressed: () {
                final miktar = int.tryParse(miktarController.text);
                if (miktar != null && miktar > 0) {
                  Navigator.pop(context, {'birimTipi': selectedBirimTipi, 'miktar': miktar});
                }
              },
              child: Text('cart.add'.tr()),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    provider.customerName = customer!.kod!;
    final freeKey = "${product.stokKodu}_(FREE${result['birimTipi']})";

    provider.addOrUpdateItem(
      stokKodu: freeKey,
      urunAdi: "${product.urunAdi}_(FREE${result['birimTipi']})",
      birimFiyat: 0,
      miktar: result['miktar'],
      urunBarcode: product.barcode1,
      iskonto: 100,
      birimTipi: result['birimTipi'],
      imsrc: product.imsrc,
      vat: product.vat,
      adetFiyati: '0',
      kutuFiyati: '0',
      birimKey1: product.birimKey1,
      birimKey2: product.birimKey2,
    );
  }

  Widget _buildQuantityControl(BuildContext context, String selectedType) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.12,
        minHeight: 60,
      ),
      width: 22.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 4,
            child: _buildQuantityButton(context, isIncrement: true, selectedType: selectedType),
          ),
          SizedBox(height: 2),
          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  height: double.infinity,
                  child: Center(
                    child: TextField(
                      key: ValueKey('quantity_${product.stokKodu}'),
                      controller: quantityController,
                      focusNode: quantityFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      maxLines: 1,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        isDense: true,
                      ),
                      onSubmitted: (value) => updateQuantityFromTextField(value),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2),
          Flexible(
            flex: 4,
            child: _buildQuantityButton(context, isIncrement: false, selectedType: selectedType),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(BuildContext context, {required bool isIncrement, required String selectedType}) {
    final bool isEnabled = isIncrement || quantity > 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isEnabled
            ? (isIncrement ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.error.withOpacity(0.1))
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
            final newQuantity = quantity + (isIncrement ? 1 : -1);

            final fiyat = selectedType == 'Box'
                ? (double.tryParse(product.kutuFiyati.toString()) ?? 0)
                : (double.tryParse(product.adetFiyati.toString()) ?? 0);

            final cartItem = provider.items[product.stokKodu];
            final iskonto = cartItem?.iskonto ?? provider.getIskonto(product.stokKodu);

            provider.addOrUpdateItem(
              urunAdi: product.urunAdi, stokKodu: product.stokKodu, birimFiyat: fiyat, adetFiyati: product.adetFiyati, kutuFiyati: product.kutuFiyati, vat: product.vat, urunBarcode: product.barcode1, miktar: isIncrement ? 1 : -1, // Decrement by 1
              iskonto: iskonto, birimTipi: selectedType, imsrc: product.imsrc, birimKey1: product.birimKey1, birimKey2: product.birimKey2,
            );

            onQuantityChanged(newQuantity);
            quantityController.text = '$newQuantity';
          }
              : null,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Icon(
              isIncrement ? Icons.add : Icons.remove,
              size: 5.w,
              color: isEnabled
                  ? (isIncrement ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error)
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.38),
            ),
          ),
        ),
      ),
    );
  }

  Color _getProductNameColor(BuildContext context) {
    final isInRefundList = refundProductNames.any((e) => e.toLowerCase() == product.urunAdi.toLowerCase());
    final isPassive = product.aktif == 0;
    if (isPassive && isInRefundList) return Colors.blue;
    if (isInRefundList) return Colors.green;
    if (isPassive) return Colors.red;
    return Theme.of(context).colorScheme.onSurface;
  }
}


class BarcodeScannerPage extends StatefulWidget {
  final void Function(String barcode) onScanned;
  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cart.scan'.tr())),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isProcessing) return; // Zaten işlem yapılıyorsa çık
          
          final barcode = capture.barcodes.firstOrNull?.rawValue;
          if (barcode != null && barcode.isNotEmpty) {
            _isProcessing = true; // İşlem başladı
            
            widget.onScanned(barcode);
            
            // Güvenli navigation
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    );
  }
}

