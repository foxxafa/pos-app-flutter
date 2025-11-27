import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/cart/presentation/cart_view2.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/widgets/barcode_scanner_page.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/products/domain/entities/birim_model.dart';
import 'package:pos_app/features/products/domain/repositories/unit_repository.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/core/sync/sync_service.dart';
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
  final Map<String, FocusNode> _priceFocusNodes = {};
  final Map<String, FocusNode> _discountFocusNodes = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  bool _isLoading = true;

  // ✅ Birim sistemi için state
  final Map<String, List<BirimModel>> _productBirimlerMap = {};
  final Map<String, BirimModel?> _selectedBirimMap = {};

  // ✅ Suggestions verilerini Map'te sakla (StokKodu -> formatted string)
  final Map<String, String> _suggestionsInfoMap = {};

  // ✅ Stok bilgilerini Map'te sakla (StokKodu -> miktar)
  final Map<String, double> _stockInfoMap = {};

  // Scanner'dan controller güncellenirken TextField onChanged'in tetiklenmemesi için
  bool _isUpdatingFromScanner = false;

  // cart_view2.dart'tan eklenen image download timer
  Timer? _imageDownloadTimer;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncWithProvider();
    });
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

    // ✅ Suggestions tablosunu Product tablosu ile JOIN et
    // Suggestions'da sadece minimal veri var (StokKodu, Miktar, vb.)
    // Product'tan tüm detayları (barkod, fiyat, resim vb.) çekiyoruz
    final rawProducts = await db.rawQuery('''
      SELECT
        s.MusteriId,
        s.StokKodu,
        s.Miktar as SuggestedMiktar,
        s.BirimTipi as SuggestedBirimTipi,
        s.ToplamTutar,
        s.Iskonto,
        s.SonSatisTarihi,
        p.urunAdi,
        p.barcode1,
        p.barcode2,
        p.barcode3,
        p.barcode4,
        p.adetFiyati,
        p.kutuFiyati,
        p.vat,
        p.imsrc,
        p.aktif,
        p.pm1,
        p.pm2,
        p.pm3,
        p.birim1,
        p.birimKey1,
        p.birim2,
        p.birimKey2,
        p.miktar
      FROM Suggestions s
      INNER JOIN Product p ON s.StokKodu = p.stokKodu
      WHERE s.MusteriId = ? AND p.aktif = 1
      ORDER BY s.UrunAdi ASC
    ''', [widget.musteriId]);

    // JOIN sonucunu ProductModel'e map et ve suggestions bilgilerini Map'e doldur
    final suggestedProducts = rawProducts.map((row) {
      final stokKodu = row['StokKodu'].toString();

      // ✅ Suggestions bilgisini formatla ve Map'e kaydet
      final miktar = (row['SuggestedMiktar'] as num?)?.toDouble() ?? 0.0;
      final birimTipi = row['SuggestedBirimTipi'] as String? ?? 'Unit';
      final toplamTutar = (row['ToplamTutar'] as num?)?.toDouble() ?? 0.0;
      final iskonto = (row['Iskonto'] as num?)?.toInt() ?? 0;
      final sonSatisTarihi = row['SonSatisTarihi'] as String?;

      if (sonSatisTarihi != null) {
        final tarih = DateTime.tryParse(sonSatisTarihi);
        if (tarih != null) {
          final formattedDate = "${tarih.day.toString().padLeft(2, '0')}/${tarih.month.toString().padLeft(2, '0')}/${tarih.year}";
          _suggestionsInfoMap[stokKodu] = "[Qty:${miktar}x$birimTipi] [Total:${toplamTutar.toStringAsFixed(2)}] [Dsc:$iskonto%] [Date:$formattedDate]";
        }
      }

      return ProductModel.fromMap({
        'stokKodu': stokKodu,
        'urunAdi': row['urunAdi'],
        'barcode1': row['barcode1'] ?? '',
        'barcode2': row['barcode2'] ?? '',
        'barcode3': row['barcode3'] ?? '',
        'barcode4': row['barcode4'] ?? '',
        'adetFiyati': row['adetFiyati'],
        'kutuFiyati': row['kutuFiyati'],
        'vat': row['vat'],
        'imsrc': row['imsrc'],
        'aktif': row['aktif'],
        'miktar': row['miktar'] ?? 0.0,
        'pm1': row['pm1'] ?? '',
        'pm2': row['pm2'] ?? '',
        'pm3': row['pm3'] ?? '',
        'birim1': row['birim1'] ?? '',
        'birimKey1': row['birimKey1'] ?? 0,
        'birim2': row['birim2'] ?? '',
        'birimKey2': row['birimKey2'] ?? 0,
      });
    }).toList();

    // ✅ Stok bilgilerini tek seferde yükle
    await _loadAllStockInfo(suggestedProducts);

    setState(() {
      _allProducts = suggestedProducts;
      _filteredProducts = suggestedProducts;
      _isLoading = false;
      _generateImageFutures(suggestedProducts);
      _downloadMissingImages(suggestedProducts);
    });

    // ✅ Birimleri background'da yükle (UI'ı bloklamadan)
    Future.microtask(() => _loadAllBirimler(suggestedProducts));
  }

  /// Tüm ürünler için birimleri background'da yükle
  Future<void> _loadAllBirimler(List<ProductModel> products) async {
    final unitRepository = Provider.of<UnitRepository>(context, listen: false);

    for (final product in products) {
      if (!mounted) break;

      final key = product.stokKodu;
      if (_productBirimlerMap.containsKey(key)) continue; // Zaten yüklü

      try {
        final birimler = await unitRepository.getBirimlerByStokKodu(product.stokKodu);

        if (mounted) {
          setState(() {
            _productBirimlerMap[key] = birimler;
            if (birimler.isNotEmpty) {
              BirimModel? defaultBirim = birimler.cast<BirimModel?>().firstWhere(
                (b) {
                  final birimAdi = b?.birimadi?.toLowerCase() ?? '';
                  return birimAdi.contains('box');
                },
                orElse: () => null,
              );
              final selectedBirim = defaultBirim ?? birimler.first;
              _selectedBirimMap[key] = selectedBirim;
            }
          });
        }
      } catch (e) {
        debugPrint('⚠️ Birim yüklenemedi ($key): $e');
      }
    }
  }

  /// Tüm ürünler için stok bilgilerini tek sorguda yükle
  Future<void> _loadAllStockInfo(List<ProductModel> products) async {
    try {
      final db = await DatabaseHelper().database;

      // Depostok'ta veri var mı kontrol et
      final anyResult = await db.rawQuery('SELECT 1 FROM Depostok LIMIT 1');
      if (anyResult.isEmpty) {
        // Depostok boş - tüm stoklar 0
        for (final product in products) {
          _stockInfoMap[product.stokKodu] = 0.0;
        }
        return;
      }

      // TÜM stokları TEK SORGUDA çek
      final allStocks = await db.query(
        'Depostok',
        columns: ['StokKodu', 'miktar'],
        where: 'UPPER(birim) = ?',
        whereArgs: ['UNIT'],
      );

      // Map'e dönüştür
      final stockMap = Map<String, double>.fromEntries(
        allStocks.map((row) => MapEntry(
          row['StokKodu'].toString(),
          (row['miktar'] as num?)?.toDouble() ?? 0.0,
        ))
      );

      // Her ürün için stok bilgisini Map'e kaydet
      for (final product in products) {
        _stockInfoMap[product.stokKodu] = stockMap[product.stokKodu] ?? 0.0;
      }
    } catch (e) {
      debugPrint('⚠️ Stok bilgileri yüklenemedi: $e');
      // Hata durumunda tüm stoklar 0
      for (final product in products) {
        _stockInfoMap[product.stokKodu] = 0.0;
      }
    }
  }

  // --- Provider Synchronization ---
  Future<void> _syncWithProvider() async {
    final provider = Provider.of<CartProvider>(context, listen: false);

    // Sadece sepette olan ürünleri sync et
    if (provider.items.isEmpty) return;

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    for (var cartItem in provider.items.values) {
      // ⚠️ CRITICAL: cartItem.stokKodu free item içinse suffix'i temizle
      // Örnek: "PROD123_(FREEBOX)" -> "PROD123"
      String rawStokKodu = cartItem.stokKodu;
      if (rawStokKodu.contains('_(FREE')) {
        rawStokKodu = rawStokKodu.split('_(FREE')[0];
      }
      final key = rawStokKodu;

      // Bu ürün _allProducts'ta var mı?
      ProductModel? product = _allProducts.cast<ProductModel?>().firstWhere(
        (p) => p?.stokKodu == key,
        orElse: () => null,
      );

      // Eğer yoksa veritabanından yükle
      if (product == null) {
        final result = await db.query(
          'Product',
          where: 'stokKodu = ?',
          whereArgs: [key],
          limit: 1,
        );

        if (result.isNotEmpty) {
          product = ProductModel.fromMap(result.first);
          // _allProducts listesine ekle
          if (mounted) {
            setState(() {
              _allProducts.add(product!);
              _filteredProducts.add(product);
            });
          }
        } else {
          continue;
        }
      }

      // ✅ selectedBirimKey'i restore et
      if (cartItem.selectedBirimKey != null) {
        // selectedBirimKey ile eşleşen BirimModel'i bul (birimler background'da yükleniyor)
        final birimler = _productBirimlerMap[key] ?? [];
        final selectedBirim = birimler.cast<BirimModel?>().firstWhere(
          (b) => b?.key == cartItem.selectedBirimKey,
          orElse: () => null,
        );

        if (selectedBirim != null && mounted) {
          setState(() {
            _selectedBirimMap[key] = selectedBirim;
          });
        }
      }

      // ✅ CRITICAL: Controller'ları güncelle (cart_view.dart'taki mantık)
      final cartBirimTipi = cartItem.birimTipi;
      final controllerKey = '${key}_$cartBirimTipi';
      final quantityControllerKey = '${key}_${cartBirimTipi}_quantity';

      if (mounted) {
        setState(() {
          // Quantity controller'ı güncelle
          if (_quantityControllers.containsKey(quantityControllerKey)) {
            _quantityControllers[quantityControllerKey]!.text = cartItem.miktar.toString();
          }

          // Discount controller'ı güncelle
          if (_discountControllers.containsKey(controllerKey)) {
            _discountControllers[controllerKey]!.text =
                cartItem.iskonto > 0 ? cartItem.iskonto.toString() : '';
          }

          // Price controller'ı güncelle
          if (_priceControllers.containsKey(controllerKey)) {
            if (cartItem.miktar > 0) {
              // Sepette ürün varsa indirimli fiyatı göster
              final discountAmount = (cartItem.birimFiyat * cartItem.iskonto) / 100;
              final discountedPrice = cartItem.birimFiyat - discountAmount;
              _priceControllers[controllerKey]!.text = discountedPrice.toStringAsFixed(2);
            }
          }
        });
      }
    }
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
        SyncService.downloadSearchResultImages(products, onImagesDownloaded: () {
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

    // Flag set et ki TextField'ın onChanged'i tetiklenmesin
    _isUpdatingFromScanner = true;
    _searchController.text = barcode;
    _isUpdatingFromScanner = false;

    _filterProducts();

    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openBarcodeScanner() async {
    // Scanner page'den dönen barkodu al
    final scannedBarcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );

    // Page kapandıktan SONRA barkodu işle (state'i korunmuş olacak)
    if (scannedBarcode != null && scannedBarcode.isNotEmpty && mounted) {
      _onBarcodeScanned(scannedBarcode);
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CartProvider>(context);
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    final cartItems = provider.items.values.toList();

    // ✅ DİNAMİK BİRİM SAYIMI: Tüm birim tiplerini say (UPPERCASE kontrol)
    final totalQuantity = cartItems.fold<int>(0, (sum, item) => sum + item.miktar);

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
            onChanged: (value) {
              // Scanner'dan güncelleme yapılıyorsa ignore et (çift çağrıyı önle)
              if (_isUpdatingFromScanner) return;
              _filterProducts(queryOverride: value);
            },
          ),
        ),
        actions: [
          _buildShoppingCartIcon(cartItems.length, totalQuantity),
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
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const CartView2()));

        // ✅ Geri döndüğünde provider'dan sepet state'ini sync et (birim değişiklikleri dahil)
        await _syncWithProvider();
      },
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

        // ✅ BirimTipi'ni önce selectedBirimMap'ten al, sonra fallback
        final selectedBirim = _selectedBirimMap[stokKodu];
        String birimTipi;
        if (selectedBirim != null) {
          birimTipi = (selectedBirim.birimkod ?? selectedBirim.birimadi ?? 'UNIT').toUpperCase();
        } else {
          // Fallback: Kutu fiyatı varsa BOX, yoksa UNIT
          birimTipi = ((double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0) ? 'BOX' : 'UNIT';
        }

        // ✅ DOĞRU cartKey kullan: stokKodu_birimTipi
        final cartKey = '${stokKodu}_$birimTipi';
        CartItem? cartItem = cartProvider.items[cartKey];

        final controllerKey = '${stokKodu}_$birimTipi';

        // Initialize controllers
        _priceControllers[controllerKey] ??= TextEditingController();
        _discountControllers[controllerKey] ??= TextEditingController();

        // ✅ FocusNode ve listener'ı sadece bir kez oluştur - PRICE
        if (!_priceFocusNodes.containsKey(controllerKey)) {
          final newPriceFocusNode = FocusNode();
          final capturedStokKodu = stokKodu; // Capture for closure
          final capturedBirimTipi = birimTipi; // Capture for closure
          String _oldPriceValue = '';

          newPriceFocusNode.addListener(() {
            if (newPriceFocusNode.hasFocus) {
              // Focus kazanıldı - içeriği temizle
              _oldPriceValue = _priceControllers[controllerKey]!.text;
              _priceControllers[controllerKey]!.clear();
            } else {
              // Focus kaybedildi - geri yükle ve kaydet
              if (_priceControllers[controllerKey]!.text.isEmpty && _oldPriceValue.isNotEmpty) {
                _priceControllers[controllerKey]!.text = _oldPriceValue;
              }

              // ⚠️ GÜNCEL provider ve product bilgilerini al
              final currentCartProvider = Provider.of<CartProvider>(context, listen: false);
              final currentCustomerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

              // Güncel product'ı bul
              final currentProduct = _allProducts.cast<ProductModel?>().firstWhere(
                (p) => p?.stokKodu == capturedStokKodu,
                orElse: () => null,
              );

              if (currentProduct == null) return;

              // ✅ Provider'a kaydet (ürün sepette varsa)
              final cartKey = '${capturedStokKodu}_$capturedBirimTipi';
              final cartItem = currentCartProvider.items[cartKey];

              if (cartItem == null || cartItem.miktar <= 0) {
                return;
              }

              final yeniFiyat = double.tryParse(_priceControllers[controllerKey]!.text.replaceAll(',', '.')) ?? 0;
              final selectedBirim = _selectedBirimMap[capturedStokKodu];

              // ⚠️ FIX: selectedBirim'den original price al
              final originalPrice = selectedBirim?.fiyat7 ??
                  (capturedBirimTipi == 'UNIT'
                      ? double.tryParse(currentProduct.adetFiyati.toString()) ?? 0.0
                      : double.tryParse(currentProduct.kutuFiyati.toString()) ?? 0.0);

              var orjinalFiyat = originalPrice;
              if (orjinalFiyat <= 0) orjinalFiyat = yeniFiyat;

              // ✅ FİYAT OVERRIDE MANTĞI
              double gonderilecekBirimFiyat;
              double hesaplananIskonto;

              if (yeniFiyat >= orjinalFiyat && orjinalFiyat > 0) {
                // Price increase = Price Override
                gonderilecekBirimFiyat = yeniFiyat;
                hesaplananIskonto = 0.0;
              } else {
                // Price decrease = Discount
                gonderilecekBirimFiyat = orjinalFiyat;
                hesaplananIskonto = (orjinalFiyat > 0)
                    ? double.parse((((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100)).toStringAsFixed(2))
                    : 0.0;
              }

              currentCartProvider.customerKod = currentCustomerProvider.selectedCustomer!.kod!;
              currentCartProvider.customerName = currentCustomerProvider.selectedCustomer!.unvan ?? currentCustomerProvider.selectedCustomer!.kod!;

              currentCartProvider.addOrUpdateItem(
                stokKodu: currentProduct.stokKodu,
                urunAdi: currentProduct.urunAdi,
                birimFiyat: gonderilecekBirimFiyat,
                urunBarcode: currentProduct.barcode1,
                miktar: 0,
                iskonto: hesaplananIskonto,
                birimTipi: capturedBirimTipi,
                vat: currentProduct.vat,
                imsrc: currentProduct.imsrc,
                adetFiyati: currentProduct.adetFiyati,
                kutuFiyati: currentProduct.kutuFiyati,
                selectedBirimKey: selectedBirim?.key,
              );

              // Fiyatı formatla
              final formattedValue = yeniFiyat.toStringAsFixed(2);
              if (_priceControllers[controllerKey]!.text != formattedValue) {
                _priceControllers[controllerKey]!.text = formattedValue;
              }
            }
          });
          _priceFocusNodes[controllerKey] = newPriceFocusNode;
        }

        // ✅ FocusNode ve listener'ı sadece bir kez oluştur - DISCOUNT
        if (!_discountFocusNodes.containsKey(controllerKey)) {
          final newDiscountFocusNode = FocusNode();
          final capturedStokKodu = stokKodu; // Capture for closure
          final capturedBirimTipi = birimTipi; // Capture for closure
          String _oldDiscountValue = '';

          newDiscountFocusNode.addListener(() {
            if (newDiscountFocusNode.hasFocus) {
              // Focus kazanıldı - içeriği temizle
              _oldDiscountValue = _discountControllers[controllerKey]!.text;
              _discountControllers[controllerKey]!.clear();
            } else {
              // Focus kaybedildi - geri yükle ve kaydet
              if (_discountControllers[controllerKey]!.text.isEmpty && _oldDiscountValue.isNotEmpty) {
                _discountControllers[controllerKey]!.text = _oldDiscountValue;
              }

              // ⚠️ GÜNCEL provider ve product bilgilerini al
              final currentCartProvider = Provider.of<CartProvider>(context, listen: false);
              final currentCustomerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

              // Güncel product'ı bul
              final currentProduct = _allProducts.cast<ProductModel?>().firstWhere(
                (p) => p?.stokKodu == capturedStokKodu,
                orElse: () => null,
              );

              if (currentProduct == null) return;

              // ✅ Provider'a kaydet (ürün sepette varsa)
              final cartKey = '${capturedStokKodu}_$capturedBirimTipi';
              final cartItem = currentCartProvider.items[cartKey];

              if (cartItem == null || cartItem.miktar <= 0) {
                return;
              }

              final value = _discountControllers[controllerKey]!.text;

              // ⚠️ KRITIK: CartProvider'dan mevcut birimFiyat'ı al (price override'ı koru)
              final currentBirimFiyat = cartItem.birimFiyat;

              if (value.isEmpty) {
                // İndirim kaldırıldı - fiyat alanını güncelle
                _priceControllers[controllerKey]!.text = currentBirimFiyat.toStringAsFixed(2);

                currentCartProvider.customerKod = currentCustomerProvider.selectedCustomer!.kod!;
                currentCartProvider.customerName = currentCustomerProvider.selectedCustomer!.unvan ?? currentCustomerProvider.selectedCustomer!.kod!;
                currentCartProvider.addOrUpdateItem(
                  stokKodu: currentProduct.stokKodu,
                  miktar: 0,
                  iskonto: 0,
                  birimTipi: capturedBirimTipi,
                  urunAdi: currentProduct.urunAdi,
                  birimFiyat: currentBirimFiyat, // Mevcut birimFiyat'ı koru
                  vat: currentProduct.vat,
                  imsrc: currentProduct.imsrc,
                  adetFiyati: currentProduct.adetFiyati,
                  kutuFiyati: currentProduct.kutuFiyati,
                  urunBarcode: currentProduct.barcode1,
                );
                return;
              }

              double discountPercent = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
              discountPercent = discountPercent.clamp(0.0, 100.0);

              // İndirimli fiyatı hesapla (mevcut birimFiyat'tan)
              final discountAmount = (currentBirimFiyat * discountPercent) / 100;
              final discountedPrice = currentBirimFiyat - discountAmount;
              _priceControllers[controllerKey]!.text = discountedPrice.toStringAsFixed(2);

              currentCartProvider.customerKod = currentCustomerProvider.selectedCustomer!.kod!;
              currentCartProvider.customerName = currentCustomerProvider.selectedCustomer!.unvan ?? currentCustomerProvider.selectedCustomer!.kod!;
              currentCartProvider.addOrUpdateItem(
                stokKodu: currentProduct.stokKodu,
                miktar: 0,
                iskonto: discountPercent,
                birimTipi: capturedBirimTipi,
                urunAdi: currentProduct.urunAdi,
                birimFiyat: currentBirimFiyat, // Mevcut birimFiyat'ı koru
                vat: currentProduct.vat,
                imsrc: currentProduct.imsrc,
                adetFiyati: currentProduct.adetFiyati,
                kutuFiyati: currentProduct.kutuFiyati,
                urunBarcode: currentProduct.barcode1,
              );
            }
          });
          _discountFocusNodes[controllerKey] = newDiscountFocusNode;
        }

        // Miktar controller'ı için de ekle
        final quantityControllerKey = '${stokKodu}_${birimTipi}_quantity';
        _quantityControllers[quantityControllerKey] ??= TextEditingController();

        // ✅ FocusNode ve listener'ı sadece bir kez oluştur - QUANTITY
        if (!_quantityFocusNodes.containsKey(quantityControllerKey)) {
          final newFocusNode = FocusNode();
          String _oldQuantityValue = '';
          newFocusNode.addListener(() {
            if (newFocusNode.hasFocus) {
              _oldQuantityValue = _quantityControllers[quantityControllerKey]!.text;
              _quantityControllers[quantityControllerKey]!.clear();
            } else {
              if (_quantityControllers[quantityControllerKey]!.text.isEmpty) {
                _quantityControllers[quantityControllerKey]!.text = _oldQuantityValue;
              }
            }
          });
          _quantityFocusNodes[quantityControllerKey] = newFocusNode;
        }

        final priceController = _priceControllers[controllerKey]!;
        final priceFocusNode = _priceFocusNodes[controllerKey]!;
        final discountController = _discountControllers[controllerKey]!;
        final discountFocusNode = _discountFocusNodes[controllerKey]!;
        final quantityController = _quantityControllers[quantityControllerKey]!;
        final quantityFocusNode = _quantityFocusNodes[quantityControllerKey]!;

        // ✅ BirimModel sistemi: Controller'ları CartProvider'dan güncel değerlerle senkronize et
        // ⚠️ KRITIK: Focus varsa (kullanıcı yazmaya başlamış) otomatik doldurma yapma!
        if (!priceFocusNode.hasFocus) {
          final selectedBirim = _selectedBirimMap[stokKodu];

          // CartProvider'dan güncel fiyatı al
          String expectedPrice = '';
          if (cartItem != null) {
            final discountAmount = (cartItem.birimFiyat * cartItem.iskonto) / 100;
            final discountedPrice = cartItem.birimFiyat - discountAmount;
            expectedPrice = discountedPrice.toStringAsFixed(2);
          } else if (selectedBirim != null) {
            // BirimModel'den fiyat al (fiyat7)
            final orjinalFiyat = selectedBirim.fiyat7 ?? 0.0;
            expectedPrice = orjinalFiyat.toStringAsFixed(2);
          } else {
            // Fallback: Eski sistem
            final orjinalFiyat = birimTipi == 'UNIT'
                ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
                : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;
            expectedPrice = orjinalFiyat.toStringAsFixed(2);
          }

          // Sadece değer farklıysa güncelle (gereksiz rebuild'i önle)
          if (priceController.text != expectedPrice) {
            priceController.text = expectedPrice;
          }
        }

        // İndirim controller'ını CartProvider'dan güncel değerlerle senkronize et
        if (!discountFocusNode.hasFocus) {
          final expectedDiscount = cartItem?.iskonto != null && cartItem!.iskonto > 0
              ? cartItem.iskonto.toString()
              : '';

          // Sadece değer farklıysa güncelle (gereksiz rebuild'i önle)
          if (discountController.text != expectedDiscount) {
            discountController.text = expectedDiscount;
          }
        }

        // ✅ Quantity controller'ı otomatik güncelle (cart_view.dart mantığı)
        // ⚠️ KRITIK: Focus varsa (kullanıcı yazmaya başlamış) otomatik doldurma yapma!
        final currentQuantity = cartItem?.miktar ?? 0;
        if (!quantityFocusNode.hasFocus && quantityController.text != currentQuantity.toString()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Callback içinde tekrar kontrol et: Focus hala yoksa güncelle
            if (mounted && !quantityFocusNode.hasFocus && quantityController.text != currentQuantity.toString()) {
              quantityController.text = currentQuantity.toString();
            }
          });
        }

        // Birimler background'da yükleniyor, burada lazy check yok

        return ProductListItemSuggestion(
          key: ValueKey(product.stokKodu),
          product: product,
          imageFuture: _imageFutures[stokKodu],
          priceController: priceController,
          priceFocusNode: priceFocusNode,
          discountController: discountController,
          discountFocusNode: discountFocusNode,
          quantityController: quantityController,
          quantityFocusNode: quantityFocusNode,
          selectedBirim: selectedBirim,
          birimTipi: birimTipi,
          onHandleQuantityUpdate: (value) => _handleQuantityUpdate(product, cartItem, cartProvider, customerProvider, value),
          buildUnitSelector: () => _buildUnitSelector(product, cartItem, cartProvider, customerProvider),
          buildPriceField: () => _buildPriceField(product, cartItem, priceController, priceFocusNode, discountController, discountFocusNode, cartProvider, customerProvider),
          buildDiscountField: () => _buildDiscountField(product, cartItem, priceController, discountController, discountFocusNode, cartProvider, customerProvider),
          buildFreeItemControl: () => _buildFreeItemControl(context, product, cartProvider, customerProvider),
          getSuggestionInfo: _getSuggestionInfo,
          availableStock: _stockInfoMap[stokKodu],
        );
      },
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        height: 1,
      ),
    );
  }

  /// Handle quantity update (called from FocusNode listener and onSubmitted)
  void _handleQuantityUpdate(
    ProductModel product,
    CartItem? cartItem,
    CartProvider cartProvider,
    SalesCustomerProvider customerProvider,
    String value,
  ) {
    final key = product.stokKodu;
    final selectedBirim = _selectedBirimMap[key];
    final birimTipi = selectedBirim != null
        ? (selectedBirim.birimkod ?? selectedBirim.birimadi ?? 'UNIT').toUpperCase()
        : (cartItem?.birimTipi ?? 'UNIT').toUpperCase();

    final newQty = int.tryParse(value) ?? 0;
    final currentQty = cartItem?.miktar ?? 0;
    final difference = newQty - currentQty;

    if (difference == 0) return;

    if (newQty <= 0) {
      cartProvider.removeItem(product.stokKodu, birimTipi);
      return;
    }

    final fiyat = selectedBirim?.fiyat7 ??
        (birimTipi == 'UNIT'
            ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
            : double.tryParse(product.kutuFiyati.toString()) ?? 0.0);

    cartProvider.customerKod = customerProvider.selectedCustomer!.kod!;
    cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;

    final iskonto = cartItem?.iskonto ?? 0.0;

    cartProvider.addOrUpdateItem(
      stokKodu: product.stokKodu,
      urunAdi: product.urunAdi,
      birimFiyat: fiyat,
      miktar: difference,
      iskonto: iskonto,
      birimTipi: birimTipi,
      vat: product.vat,
      adetFiyati: product.adetFiyati,
      kutuFiyati: product.kutuFiyati,
      urunBarcode: product.barcode1,
      imsrc: product.imsrc,
      selectedBirimKey: selectedBirim?.key,
    );
  }

  Widget _buildUnitSelector(ProductModel product, CartItem? cartItem, CartProvider cartProvider, SalesCustomerProvider customerProvider) {
    final key = product.stokKodu;
    final birimler = _productBirimlerMap[key] ?? [];
    final selectedBirim = _selectedBirimMap[key];

    // ✅ Birimler yüklenmediyse fallback (matches cart_view.dart)
    if (birimler.isEmpty) {
      return Container(
        height: 8.w,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '-',
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        ),
      );
    }

    // ✅ Tek birim varsa sadece text göster
    if (birimler.length == 1) {
      final birim = birimler.first;
      return Container(
        height: 8.w,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          birim.displayName,
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        ),
      );
    }

    // ✅ Çoklu birim varsa dropdown göster
    return Container(
      height: 8.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<BirimModel>(
        value: selectedBirim,
        isDense: true,
        underline: Container(),
        style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        items: birimler.map((birim) {
          return DropdownMenuItem<BirimModel>(
            value: birim,
            child: Text(birim.displayName),
          );
        }).toList(),
        onChanged: (newBirim) {
          if (newBirim != null) {
            setState(() {
              _selectedBirimMap[key] = newBirim;
            });

            final fiyat = newBirim.fiyat7 ?? 0.0;
            final birimTipi = (newBirim.birimkod ?? newBirim.birimadi ?? 'UNIT').toUpperCase();

            // Eski item varsa sil, yeni ekle
            if (cartItem != null) {
              cartProvider.removeItem(product.stokKodu, cartItem.birimTipi);
            }

            cartProvider.customerKod = customerProvider.selectedCustomer!.kod!;
            cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;
            cartProvider.addOrUpdateItem(
              urunAdi: product.urunAdi,
              stokKodu: product.stokKodu,
              birimFiyat: fiyat,
              urunBarcode: product.barcode1,
              adetFiyati: product.adetFiyati,
              kutuFiyati: product.kutuFiyati,
              miktar: cartItem?.miktar ?? 0,
              iskonto: cartItem?.iskonto ?? 0,
              birimTipi: birimTipi,
              vat: product.vat,
              imsrc: product.imsrc,
              selectedBirimKey: newBirim.key,
            );
          }
        },
      ),
    );
  }

  Widget _buildPriceField(ProductModel product, CartItem? cartItem, TextEditingController priceController, FocusNode priceFocusNode, TextEditingController discountController, FocusNode discountFocusNode, CartProvider cartProvider, SalesCustomerProvider customerProvider) {
    final birimTipi = cartItem?.birimTipi ?? ((double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0 ? 'BOX' : 'UNIT');

    return Container(
      height: 8.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: priceController,
        focusNode: priceFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
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
          if (value.isEmpty) return;

          final yeniFiyat = double.tryParse(value.replaceAll(',', '.'));
          if (yeniFiyat == null || yeniFiyat < 0) return;

          var orjinalFiyatHesap = birimTipi == 'UNIT'
              ? double.tryParse(product.adetFiyati.toString()) ?? 0.0
              : double.tryParse(product.kutuFiyati.toString()) ?? 0.0;

          if (orjinalFiyatHesap <= 0) orjinalFiyatHesap = yeniFiyat;

          final indirimOrani = (orjinalFiyatHesap > 0 && yeniFiyat < orjinalFiyatHesap)
              ? double.parse((((orjinalFiyatHesap - yeniFiyat) / orjinalFiyatHesap * 100)).toStringAsFixed(2))
              : 0.0;

          if (!discountFocusNode.hasFocus) {
            discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';
          }
        },
        onEditingComplete: () {
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
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null) {
            priceController.text = parsed.toStringAsFixed(2);
          }
          priceFocusNode.unfocus();
        },
      ),
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
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixText: '%',
              prefixStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.error),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onSubmitted: (value) {
              // On submit, just unfocus. The focus listener will handle the update.
              discountFocusNode.unfocus();
            },
          ),
        ),
      ],
    );
  }

  /// Free item control (hand icon with badges) - matches cart_view.dart
  Widget _buildFreeItemControl(
    BuildContext context,
    ProductModel product,
    CartProvider cartProvider,
    SalesCustomerProvider customerProvider,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () => _showFreeItemDialog(context, product, cartProvider, customerProvider),
          child: Container(
            padding: EdgeInsets.all(1.w),
            width: 15.w,
            height: 12.w,
            child: Image.asset('assets/hand.png', width: 10.w, height: 10.w),
          ),
        ),
        _buildFreeItemBadge(context, product, cartProvider, isBox: true),
        _buildFreeItemBadge(context, product, cartProvider, isBox: false),
      ],
    );
  }

  Widget _buildFreeItemBadge(BuildContext context, ProductModel product, CartProvider cartProvider, {required bool isBox}) {
    final type = isBox ? 'Box' : 'Unit';
    final count = cartProvider.items.values
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

  Future<void> _showFreeItemDialog(
    BuildContext context,
    ProductModel product,
    CartProvider cartProvider,
    SalesCustomerProvider customerProvider,
  ) async {
    String selectedBirimTipi = (double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0 ? 'Box' : 'Unit';
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
                  if ((double.tryParse(product.adetFiyati.toString()) ?? 0) > 0)
                    DropdownMenuItem(value: 'Unit', child: Text('cart.unit'.tr())),
                  if ((double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0)
                    DropdownMenuItem(value: 'Box', child: Text('cart.box'.tr())),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cart.cancel'.tr()),
            ),
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

    cartProvider.customerKod = customerProvider.selectedCustomer!.kod!;
    cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;

    final freeKey = "${product.stokKodu}_(FREE${result['birimTipi']})";

    cartProvider.addOrUpdateItem(
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
      selectedBirimKey: null,
    );
  }

  /// Suggestions bilgisini Map'ten getir (sayfa açılırken tek sorguda yüklendi)
  Future<String> _getSuggestionInfo(String stokKodu) async {
    return _suggestionsInfoMap[stokKodu] ?? "";
  }
}

/// ProductImage widget - Matches cart_view.dart design
class ProductImageSuggestion extends StatefulWidget {
  final Future<String?>? imageFuture;
  final ProductModel product;
  final BirimModel? selectedBirim;
  final double? availableStock; // ✅ Parent'tan geçilecek

  const ProductImageSuggestion({
    super.key,
    this.imageFuture,
    required this.product,
    this.selectedBirim,
    this.availableStock,
  });

  @override
  State<ProductImageSuggestion> createState() => _ProductImageSuggestionState();
}

class _ProductImageSuggestionState extends State<ProductImageSuggestion> {
  @override
  void initState() {
    super.initState();
  }

  void _showProductInfoDialog(BuildContext context) {
    final qty = (widget.availableStock ?? 0).toInt();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.product.urunAdi,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 80.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.product.imsrc != null)
                  FutureBuilder<String?>(
                    future: _getLocalImagePath(widget.product.imsrc!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return SizedBox(
                          height: 50.w,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                      return Center(
                        child: Icon(Icons.shopping_bag, size: 50.w, color: Colors.grey),
                      );
                    },
                  )
                else
                  Center(
                    child: Icon(Icons.shopping_bag, size: 50.w, color: Colors.grey),
                  ),
                SizedBox(height: 2.h),
                Text("${'cart.code'.tr()}: ${widget.product.stokKodu}", style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 1.h),
                Text("${'cart.unit_price'.tr()}: ${widget.product.adetFiyati}", style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 1.h),
                Text("${'cart.box_price'.tr()}: ${widget.product.kutuFiyati}", style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 1.h),
                Text("${'cart.vat'.tr()}: ${widget.product.vat}", style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 1.h),
                Text("Qty: $qty", style: TextStyle(fontSize: 16.sp)),
              ],
            ),
          ),
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
    // Banner'ı stok bilgisine göre göster (parent'tan geçildi)
    final showBanner = (widget.availableStock ?? 0) <= 0;

    return GestureDetector(
      onDoubleTap: () => _showProductInfoDialog(context),
      child: Column(
        children: [
          SizedBox(
            width: 30.w,
            height: 30.w,
            child: Stack(
              children: [
                // Main image/icon
                SizedBox(
                  width: 30.w,
                  height: 30.w,
                  child: widget.product.imsrc == null
                      ? Icon(Icons.shopping_bag_sharp, size: 25.w, color: Colors.grey)
                      : FutureBuilder<String?>(
                    future: widget.imageFuture,
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
                // Suspended banner for products with zero stock
                if (showBanner)
                  Positioned.fill(
                    child: _SuspendedBannerWidget(),
                  ),
              ],
            ),
          ),
          Text(
            _getQuantityText(),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getQuantityText() {
    // Stok bilgisi parent'tan geçildi (UNIT cinsinden)
    final unitStock = widget.availableStock ?? 0.0;

    // Seçili birime göre stoğu hesapla (carpan ile böl)
    double displayStock = unitStock;
    if (widget.selectedBirim != null && widget.selectedBirim!.carpan > 0) {
      // Seçili birim varsa ve carpan > 0 ise, UNIT stoğunu carpan'a böl
      // Örnek: 24 UNIT / 8 (carpan) = 3 BOX
      displayStock = unitStock / widget.selectedBirim!.carpan;
    }

    final qty = displayStock.toInt();

    if (qty > 99) return "Qty: 99+";
    if (qty < -99) return "Qty: 99-";
    return "Qty: $qty";
  }
}

/// Widget that displays a diagonal "SUSPENDED" banner overlay
/// with text centered within the banner's parallel edges
class _SuspendedBannerWidget extends StatelessWidget {
  static const double _bannerWidth = 40.0;
  static const double _rotationAngle = -0.785398; // -45° in radians
  static const double _sin45 = 0.707; // sin(45°) = cos(45°) ≈ 0.707

  const _SuspendedBannerWidget();

  @override
  Widget build(BuildContext context) {
    // Calculate offset to center text between banner's parallel edges
    // Banner has two parallel edges 40px apart at 45° angle
    // Text needs to be offset by 1/4 of banner width perpendicular to the diagonal
    final quarterWidth = _bannerWidth / 4;
    final perpOffsetX = quarterWidth * _sin45;
    final perpOffsetY = quarterWidth * _sin45;

    return CustomPaint(
      painter: _SuspendedBannerPainter(),
      child: Transform.translate(
        offset: Offset(-perpOffsetX, -perpOffsetY),
        child: Align(
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: _rotationAngle,
            child: Text(
              'SUSPENDED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.9),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for drawing the red diagonal "SUSPENDED" banner
/// Touches only the top edge at top-right and only the left edge at bottom-left
class _SuspendedBannerPainter extends CustomPainter {
  static const double _bannerWidth = 40.0;
  static const double _sqrt2 = 1.414; // √2 ≈ 1.414 for 45° calculations
  static const Color _bannerColor = Color(0xFFCC0000);
  static const double _bannerOpacity = 0.9;

  const _SuspendedBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _bannerColor.withValues(alpha: _bannerOpacity)
      ..style = PaintingStyle.fill;

    // Calculate offset for 45° angle: bannerWidth / √2
    final offset = _bannerWidth / _sqrt2;

    // Draw parallelogram banner path:
    // - Top edge: starts at (width - offset, 0) ends at (width, 0)
    // - Left edge: starts at (0, height - offset) ends at (0, height)
    // - Diagonal connects these two edges at 45°
    final path = Path()
      ..moveTo(size.width - offset, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - offset, offset)
      ..lineTo(offset, size.height - offset)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - offset)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ProductListItemSuggestion - Matches cart_view.dart's ProductListItem
class ProductListItemSuggestion extends StatefulWidget {
  final ProductModel product;
  final Future<String?>? imageFuture;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final TextEditingController discountController;
  final FocusNode discountFocusNode;
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;
  final BirimModel? selectedBirim;
  final String birimTipi;
  final ValueChanged<String> onHandleQuantityUpdate;
  final Widget Function() buildUnitSelector;
  final Widget Function() buildPriceField;
  final Widget Function() buildDiscountField;
  final Widget Function() buildFreeItemControl;
  final Future<String> Function(String) getSuggestionInfo;
  final double? availableStock; // ✅ Stok bilgisi

  const ProductListItemSuggestion({
    super.key,
    required this.product,
    this.imageFuture,
    required this.priceController,
    required this.priceFocusNode,
    required this.discountController,
    required this.discountFocusNode,
    required this.quantityController,
    required this.quantityFocusNode,
    required this.selectedBirim,
    required this.birimTipi,
    required this.onHandleQuantityUpdate,
    required this.buildUnitSelector,
    required this.buildPriceField,
    required this.buildDiscountField,
    required this.buildFreeItemControl,
    required this.getSuggestionInfo,
    this.availableStock,
  });

  @override
  State<ProductListItemSuggestion> createState() => _ProductListItemSuggestionState();
}

class _ProductListItemSuggestionState extends State<ProductListItemSuggestion> {
  // ⚠️ Quantity için internal FocusNode KALDIRILDI - parent'tan gelen widget.quantityFocusNode kullanılıyor
  // ⚠️ Quantity listener'ı da parent'ta (inline) ekleniyor
  // ⚠️ Price ve discount listener'lar da parent'ta (inline) ekleniyor

  @override
  Widget build(BuildContext context) {
    // ✅ CRITICAL: Use context.watch to get live quantity updates
    final cartKey = '${widget.product.stokKodu}_${widget.birimTipi}';
    final cartProvider = context.watch<CartProvider>();
    final cartItem = cartProvider.items[cartKey];
    final anlikMiktar = cartItem?.miktar ?? 0;

    // ✅ Build içinde controller değiştirme - build bittikten SONRA yap
    // ⚠️ KRITIK: Focus varsa (kullanıcı yazmaya başlamış) otomatik doldurma yapma!
    if (!widget.quantityFocusNode.hasFocus && widget.quantityController.text != anlikMiktar.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Callback içinde tekrar kontrol et: Focus hala yoksa güncelle
        if (mounted && !widget.quantityFocusNode.hasFocus && widget.quantityController.text != anlikMiktar.toString()) {
          widget.quantityController.text = anlikMiktar.toString();
        }
      });
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Product Image
              ProductImageSuggestion(
                imageFuture: widget.imageFuture,
                product: widget.product,
                selectedBirim: widget.selectedBirim,
                availableStock: widget.availableStock,
              ),
              SizedBox(width: 5.w),
              // Right: Details and Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.product.urunAdi,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    // Main Row: Left Column (Price/Discount) + Right Quantity Control
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Expanded Column for Price and Discount
                        Expanded(
                          child: Column(
                            children: [
                              // Row 1: Unit Selector + Price Field
                              Row(
                                children: [
                                  widget.buildUnitSelector(),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: widget.buildPriceField(),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              // Row 2: Discount Field + Free Item Control
                              Row(
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: widget.buildDiscountField(),
                                  ),
                                  SizedBox(width: 2.w),
                                  Flexible(
                                    flex: 10,
                                    child: widget.buildFreeItemControl(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        // Right: Vertical Quantity Control
                        _buildVerticalQuantityControl(cartItem, anlikMiktar),
                      ],
                    ),
                    // ✅ Yeşil bilgi satırı (Suggestions'tan)
                    FutureBuilder<String>(
                      future: widget.getSuggestionInfo(widget.product.stokKodu),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Column(
                            children: [
                              SizedBox(height: 0.5.h),
                              Text(
                                snapshot.data!,
                                style: TextStyle(color: Color.fromARGB(255, 1, 71, 4), fontSize: 12.sp),
                              ),
                            ],
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ✅ Final Price - Yorum satırı (öneri sayfasında görünmesin)
          // if (cartItem != null) ...[
          //   Divider(),
          //   Center(
          //     child: Text(
          //       'Final Price: ${(cartItem.indirimliTutar * cartItem.miktar).toStringAsFixed(2)} - VAT:${(cartItem.vatTutari * cartItem.miktar).toStringAsFixed(2)}',
          //       style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, fontStyle: FontStyle.italic),
          //     ),
          //   ),
          // ]
        ],
      ),
    );
  }

  Widget _buildVerticalQuantityControl(CartItem? cartItem, int anlikMiktar) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.12,
        minHeight: 60,
      ),
      width: 22.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // + Button
          Flexible(
            flex: 4,
            child: _buildQuantityButton(
              isIncrement: true,
              cartItem: cartItem,
              anlikMiktar: anlikMiktar,
            ),
          ),
          SizedBox(height: 2),
          // TextField
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
                  key: ValueKey('quantity_${widget.product.stokKodu}'),
                  controller: widget.quantityController,
                  focusNode: widget.quantityFocusNode, // ✅ Parent'tan gelen FocusNode kullan
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
                  onSubmitted: (value) => widget.onHandleQuantityUpdate(value),
                ),
              ),
            ),
          ),
          SizedBox(height: 2),
          // - Button
          Flexible(
            flex: 4,
            child: _buildQuantityButton(
              isIncrement: false,
              cartItem: cartItem,
              anlikMiktar: anlikMiktar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required bool isIncrement,
    required CartItem? cartItem,
    required int anlikMiktar,
  }) {
    final bool isEnabled = isIncrement || anlikMiktar > 0;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isEnabled
            ? (isIncrement
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.error.withValues(alpha: 0.1))
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  final fiyat = widget.selectedBirim?.fiyat7 ??
                      (widget.birimTipi == 'UNIT'
                          ? double.tryParse(widget.product.adetFiyati.toString()) ?? 0.0
                          : double.tryParse(widget.product.kutuFiyati.toString()) ?? 0.0);

                  final iskonto = cartItem?.iskonto ?? 0.0;

                  cartProvider.customerKod = customerProvider.selectedCustomer!.kod!;
                  cartProvider.customerName = customerProvider.selectedCustomer!.unvan ?? customerProvider.selectedCustomer!.kod!;

                  cartProvider.addOrUpdateItem(
                    urunAdi: widget.product.urunAdi,
                    stokKodu: widget.product.stokKodu,
                    birimFiyat: fiyat,
                    adetFiyati: widget.product.adetFiyati,
                    kutuFiyati: widget.product.kutuFiyati,
                    vat: widget.product.vat,
                    urunBarcode: widget.product.barcode1,
                    miktar: isIncrement ? 1 : -1,
                    iskonto: iskonto,
                    birimTipi: widget.birimTipi,
                    imsrc: widget.product.imsrc,
                    selectedBirimKey: widget.selectedBirim?.key,
                  );
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
                  ? (isIncrement
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error)
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

