import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';
import 'package:pos_app/features/refunds/presentation/providers/cart_provider_refund.dart';
import 'package:pos_app/features/refunds/presentation/screens/refundcart_view2.dart';
import 'package:pos_app/features/products/domain/repositories/product_repository.dart';
import 'package:pos_app/core/widgets/barcode_scanner_page.dart';
import 'package:pos_app/core/services/scanner_service.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';

class RefundCartView extends StatefulWidget {
  final List<String> refundProductNames;
  final List<Refund> refunds;
  final RefundFisModel fisModel;

  const RefundCartView({
    super.key,
    required this.fisModel,
    required this.refundProductNames,
    required this.refunds,
  });

  @override
  State<RefundCartView> createState() => _RefundCartViewState();
}

class _RefundCartViewState extends State<RefundCartView> {
  // --- State Variables ---
  final Map<String, TextEditingController> _quantityControllers = {};
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _barcodeFocusNode2 = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  bool _isLoading = true;

  final Map<String, int> _quantityMap = {};

  Timer? _imageDownloadTimer;

  final List<String> _returnReasons = [
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

  // --- Lifecycle Methods ---
  late bool Function(KeyEvent) _scannerHandler;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _setupAudioPlayer();
    // 🔑 Hardware keyboard listener ekle
    _scannerHandler = ScannerService.createHandler(_clearAndFocusBarcode);
    HardwareKeyboard.instance.addHandler(_scannerHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
      _syncWithProvider();
    });
  }

  void _setupAudioPlayer() {
    _audioPlayer.setVolume(0.8);
  }

  @override
  void dispose() {
    _imageDownloadTimer?.cancel();
    _barcodeFocusNode.dispose();
    _barcodeFocusNode2.dispose();
    _searchController.dispose();
    _searchController2.dispose();
    _quantityControllers.values.forEach((c) => c.dispose());
    _audioPlayer.dispose();
    // 🔑 Hardware keyboard listener kaldır
    HardwareKeyboard.instance.removeHandler(_scannerHandler);
    super.dispose();
  }

  // --- Product & Data Loading ---
  Future<void> _loadProducts() async {
    final productRepository = Provider.of<ProductRepository>(context, listen: false);
    final allProducts = await productRepository.getAllProducts();
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
        _quantityMap[key] = 0;
      }
      _generateImageFutures(_filteredProducts);
    });
  }

  void _syncWithProvider() {
    final provider = Provider.of<RCartProvider>(context, listen: false);
    setState(() {
      for (var product in _allProducts) {
        final key = product.stokKodu;
        final miktar = provider.getmiktar(key);
        _quantityMap[key] = miktar;
        _quantityControllers[key]?.text = miktar.toString();
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

  // --- Sound & Barcode ---
  Future<void> playWrong() async {
    await _audioPlayer.play(AssetSource('wrong.mp3'));
  }

  Future<void> playBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  void _onBarcodeScanned(String barcode) {
    if (!mounted) return;

    _searchController.text = barcode;
    _searchController2.text = barcode;
    _filterProducts(queryOverride: barcode);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      final query = barcode.trimRight().toLowerCase();
      final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
      final filtered = _allProducts.where((product) {
        final name = product.urunAdi.toLowerCase();
        final stokKodu = product.stokKodu.toLowerCase();
        final barcodes = [product.barcode1, product.barcode2, product.barcode3, product.barcode4]
            .map((b) => b.toLowerCase())
            .toList();
        return queryWords.every((word) =>
          name.contains(word) ||
          stokKodu.contains(word) ||
          barcodes.any((b) => b.contains(word))
        );
      }).toList();

      if (filtered.isNotEmpty) {
        playBeep();
      } else {
        playWrong();
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
    final provider = Provider.of<RCartProvider>(context, listen: false);
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
      final stokKodu = product.stokKodu.toLowerCase();
      final barcodes = [product.barcode1, product.barcode2, product.barcode3, product.barcode4]
          .map((b) => b.toLowerCase())
          .toList();
      return queryWords.every((word) =>
        name.contains(word) ||
        stokKodu.contains(word) ||
        barcodes.any((b) => b.contains(word))
      );
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

    if (!fromUI) {
      if (_filteredProducts.length == 1 && RegExp(r'^\d+$').hasMatch(query)) {
        final product = _filteredProducts.first;
        final key = product.stokKodu;
        final birimTipi = provider.getBirimTipi(key);

        if ((birimTipi == 'Unit' && product.birimKey1 != 0) || (birimTipi == 'Box' && product.birimKey2 != 0)) {
          final matchingRefunds = widget.refunds.where((r) => r.urunAdi == product.urunAdi).toList()
            ..sort((a, b) => b.fisTarihi.compareTo(a.fisTarihi));
          final latestRefund = matchingRefunds.isNotEmpty ? matchingRefunds.first : null;

          final birimFiyat = latestRefund?.birimFiyat ??
            (birimTipi == 'Box' ? double.tryParse(product.kutuFiyati.toString()) ?? 0 : double.tryParse(product.adetFiyati.toString()) ?? 0);
          final iskonto = latestRefund?.iskonto ?? 0;

          provider.addOrUpdateItem(
            urunAdi: product.urunAdi,
            adetFiyati: product.adetFiyati,
            kutuFiyati: product.kutuFiyati,
            stokKodu: key,
            vat: product.vat,
            birimFiyat: birimFiyat,
            imsrc: product.imsrc,
            urunBarcode: product.barcode1,
            miktar: 1,
            iskonto: iskonto,
            birimTipi: birimTipi,
          );
          playBeep();
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
    if (mounted) {
      _barcodeFocusNode.requestFocus();
    }
  }

  // --- UI Helper Methods ---
  void _clearSearch2() {
    _searchController2.clear();
    _filterProducts(queryOverride: "");
  }

  void _updateQuantityFromTextField(String key, String value, ProductModel product) {
    final provider = Provider.of<RCartProvider>(context, listen: false);
    final newQuantity = int.tryParse(value) ?? 0;
    final birimTipi = provider.getBirimTipi(key);

    final currentQuantity = provider.getmiktar(key);
    final difference = newQuantity - currentQuantity;

    if (difference == 0) return;

    if (newQuantity <= 0) {
      provider.removeItem(key);
    } else {
      final matchingRefunds = widget.refunds.where((r) => r.urunAdi == product.urunAdi).toList()
        ..sort((a, b) => b.fisTarihi.compareTo(a.fisTarihi));
      final latestRefund = matchingRefunds.isNotEmpty ? matchingRefunds.first : null;

      final birimFiyat = latestRefund?.birimFiyat ??
        (birimTipi == 'Box' ? double.tryParse(product.kutuFiyati.toString()) ?? 0 : double.tryParse(product.adetFiyati.toString()) ?? 0);
      final iskonto = latestRefund?.iskonto ?? 0;

      provider.addOrUpdateItem(
        urunAdi: product.urunAdi,
        stokKodu: key,
        birimFiyat: birimFiyat,
        adetFiyati: product.adetFiyati,
        kutuFiyati: product.kutuFiyati,
        vat: product.vat,
        urunBarcode: product.barcode1,
        miktar: difference,
        iskonto: iskonto,
        birimTipi: birimTipi,
        imsrc: product.imsrc,
      );
    }
    setState(() {
      _quantityMap[key] = newQuantity;
    });
  }

  String? getBirimTipiFromProduct(ProductModel product) {
    if (product.birimKey2 != 0) return 'Box';
    if (product.birimKey1 != 0) return 'Unit';
    return null;
  }

  void _showReturnReasonDialog(BuildContext context, String stokKodu, RCartProvider cartProvider) {
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
            padding: EdgeInsets.only(top: 1.h, bottom: 2.h),
            itemCount: _returnReasons.length,
            itemBuilder: (context, index) {
              final reason = _returnReasons[index];
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(reason, style: TextStyle(fontSize: 15.sp)),
                value: reason,
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

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RCartProvider>(context);
    final cartItems = provider.items.values.toList();
    final unitCount = cartItems.where((i) => i.birimTipi == 'Unit').fold<int>(0, (p, i) => p + i.miktar);
    final boxCount = cartItems.where((i) => i.birimTipi == 'Box').fold<int>(0, (p, i) => p + i.miktar);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: SizedBox(
          height: 40,
          child: TextField(
            focusNode: _barcodeFocusNode2,
            controller: _searchController2,
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'cart.search_placeholder'.tr(),
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController2.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7), size: 20),
                      onPressed: _clearSearch2,
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
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  focusNode: _barcodeFocusNode,
                  controller: _searchController,
                  onChanged: (value) {
                    _searchController2.text = value;
                    _filterProducts();
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _filterProducts();
                    }
                  },
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
    );
  }

  Widget _buildShoppingCartIcon(int itemCount, int totalQuantity) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RefundCartView2(fisModel: widget.fisModel)),
      ),
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

  Widget _buildProductList(RCartProvider provider) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final key = product.stokKodu;

        if (!_quantityControllers.containsKey(key)) {
          _quantityControllers[key] = TextEditingController(text: provider.getmiktar(key).toString());
        }

        return RefundProductListItem(
          key: ValueKey(product.stokKodu),
          product: product,
          provider: provider,
          imageFuture: _imageFutures[key],
          refundProductNames: widget.refundProductNames,
          refunds: widget.refunds,
          quantityController: _quantityControllers[key]!,
          quantity: context.watch<RCartProvider>().getmiktar(key),
          onQuantityChanged: (newQuantity) {
            setState(() {
              _quantityMap[key] = newQuantity;
            });
          },
          updateQuantityFromTextField: (value) => _updateQuantityFromTextField(key, value, product),
          getBirimTipi: () => getBirimTipiFromProduct(product),
          onReturnReasonPressed: () => _showReturnReasonDialog(context, key, provider),
        );
      },
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        height: 1,
      ),
    );
  }
}


// --- WIDGETS ---

class RefundProductListItem extends StatefulWidget {
  final ProductModel product;
  final RCartProvider provider;
  final Future<String?>? imageFuture;
  final List<String> refundProductNames;
  final List<Refund> refunds;
  final TextEditingController quantityController;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> updateQuantityFromTextField;
  final String? Function() getBirimTipi;
  final VoidCallback onReturnReasonPressed;

  const RefundProductListItem({
    super.key,
    required this.product,
    required this.provider,
    this.imageFuture,
    required this.refundProductNames,
    required this.refunds,
    required this.quantityController,
    required this.quantity,
    required this.onQuantityChanged,
    required this.updateQuantityFromTextField,
    required this.getBirimTipi,
    required this.onReturnReasonPressed,
  });

  @override
  State<RefundProductListItem> createState() => _RefundProductListItemState();
}

class _RefundProductListItemState extends State<RefundProductListItem> {
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
      widget.quantityController.clear();
    } else {
      if (widget.quantityController.text.isEmpty) {
        if (mounted) {
          setState(() {
            widget.quantityController.text = _oldQuantityValue;
          });
        }
      }
      widget.updateQuantityFromTextField(widget.quantityController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anlikMiktar = context.watch<RCartProvider>().getmiktar(widget.product.stokKodu);
    if (widget.quantityController.text != anlikMiktar.toString()) {
      widget.quantityController.text = anlikMiktar.toString();
    }

    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RefundProductImage(
            imageFuture: widget.imageFuture,
            product: widget.product,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: RefundProductDetails(
              product: widget.product,
              provider: widget.provider,
              refundProductNames: widget.refundProductNames,
              refunds: widget.refunds,
              quantityController: widget.quantityController,
              quantityFocusNode: _quantityFocusNode,
              quantity: anlikMiktar,
              onQuantityChanged: widget.onQuantityChanged,
              updateQuantityFromTextField: widget.updateQuantityFromTextField,
              getBirimTipi: widget.getBirimTipi,
              onReturnReasonPressed: widget.onReturnReasonPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class RefundProductImage extends StatelessWidget {
  final Future<String?>? imageFuture;
  final ProductModel product;

  const RefundProductImage({
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
            SelectableText("${'cart.barcodes'.tr()}: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b.trim().isNotEmpty).join(', ')}"),
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

class RefundProductDetails extends StatelessWidget {
  final ProductModel product;
  final RCartProvider provider;
  final List<String> refundProductNames;
  final List<Refund> refunds;
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> updateQuantityFromTextField;
  final String? Function() getBirimTipi;
  final VoidCallback onReturnReasonPressed;

  const RefundProductDetails({
    super.key,
    required this.product,
    required this.provider,
    required this.refundProductNames,
    required this.refunds,
    required this.quantityController,
    required this.quantityFocusNode,
    required this.quantity,
    required this.onQuantityChanged,
    required this.updateQuantityFromTextField,
    required this.getBirimTipi,
    required this.onReturnReasonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final selectedType = getBirimTipi() ?? 'Unit';

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
                      Expanded(child: _buildPriceDisplay(context)),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  _buildReturnReasonButton(context),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            _buildQuantityControl(context, selectedType),
          ],
        ),
        if (_getRefundInfo().isNotEmpty) ...[
          SizedBox(height: 0.5.h),
          Text(
            _getRefundInfo(),
            style: TextStyle(color: Color.fromARGB(255, 1, 71, 4), fontSize: 12.sp),
          ),
        ],
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
        height: 8.w,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          unitText,
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      height: 8.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
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
          if (val != null && quantity > 0) {
            final matchingRefunds = refunds.where((r) => r.urunAdi == product.urunAdi).toList()
              ..sort((a, b) => b.fisTarihi.compareTo(a.fisTarihi));
            final latestRefund = matchingRefunds.isNotEmpty ? matchingRefunds.first : null;

            final birimFiyat = latestRefund?.birimFiyat ??
              (val == 'Box' ? double.tryParse(product.kutuFiyati.toString()) ?? 0 : double.tryParse(product.adetFiyati.toString()) ?? 0);
            final iskonto = latestRefund?.iskonto ?? 0;

            provider.addOrUpdateItem(
              urunAdi: product.urunAdi,
              stokKodu: product.stokKodu,
              birimFiyat: birimFiyat,
              adetFiyati: product.adetFiyati,
              kutuFiyati: product.kutuFiyati,
              vat: product.vat,
              urunBarcode: product.barcode1,
              miktar: 0,
              iskonto: iskonto,
              birimTipi: val,
            );
          }
        },
      ),
    );
  }

  Widget _buildPriceDisplay(BuildContext context) {
    final matchingRefunds = refunds.where((r) => r.urunAdi == product.urunAdi).toList()
      ..sort((a, b) => b.fisTarihi.compareTo(a.fisTarihi));
    final latestRefund = matchingRefunds.isNotEmpty ? matchingRefunds.first : null;

    final selectedType = getBirimTipi() ?? 'Unit';
    final displayPrice = latestRefund?.birimFiyat ??
      (selectedType == 'Box' ? double.tryParse(product.kutuFiyati.toString()) ?? 0 : double.tryParse(product.adetFiyati.toString()) ?? 0);

    return Container(
      height: 8.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        displayPrice.toStringAsFixed(2),
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReturnReasonButton(BuildContext context) {
    final currentReason = provider.items[product.stokKodu]?.aciklama ?? '';

    return InkWell(
      onTap: quantity > 0 ? onReturnReasonPressed : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: quantity > 0 ? Theme.of(context).colorScheme.primary : Colors.grey),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment, size: 18.sp, color: quantity > 0 ? Theme.of(context).colorScheme.primary : Colors.grey),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                currentReason.isEmpty ? 'Select return reason' : currentReason,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: currentReason.isEmpty ? Colors.grey : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
            ? (isIncrement ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.error.withValues(alpha: 0.1))
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
            final matchingRefunds = refunds.where((r) => r.urunAdi == product.urunAdi).toList()
              ..sort((a, b) => b.fisTarihi.compareTo(a.fisTarihi));
            final latestRefund = matchingRefunds.isNotEmpty ? matchingRefunds.first : null;

            final birimFiyat = latestRefund?.birimFiyat ??
              (selectedType == 'Box' ? double.tryParse(product.kutuFiyati.toString()) ?? 0 : double.tryParse(product.adetFiyati.toString()) ?? 0);
            final iskonto = latestRefund?.iskonto ?? 0;

            provider.addOrUpdateItem(
              urunAdi: product.urunAdi,
              stokKodu: product.stokKodu,
              birimFiyat: birimFiyat,
              adetFiyati: product.adetFiyati,
              kutuFiyati: product.kutuFiyati,
              vat: product.vat,
              urunBarcode: product.barcode1,
              miktar: isIncrement ? 1 : -1,
              iskonto: iskonto,
              birimTipi: selectedType,
              imsrc: product.imsrc,
            );

            final newQuantity = quantity + (isIncrement ? 1 : -1);
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
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }

  String _getRefundInfo() {
    final filtered = refunds.where((r) => r.urunAdi == product.urunAdi);
    if (filtered.isEmpty) return "";

    final sorted = filtered.toList()..sort((a, b) => b.fisTarihi.compareTo(a.fisTarihi));
    final refund = sorted.first;

    return "[Qty:${refund.miktar}x${refund.birim}] "
        "[Price:${refund.birimFiyat.toStringAsFixed(2)}] "
        "[Dsc:${refund.iskonto}%] "
        "[Date:${refund.fisTarihi.day.toString().padLeft(2, '0')}/"
        "${refund.fisTarihi.month.toString().padLeft(2, '0')}/"
        "${refund.fisTarihi.year}]";
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