import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/cart/presentation/cart_view2.dart';
import 'package:pos_app/features/cart/presentation/cartsuggestion_view.dart';
import 'package:pos_app/core/widgets/barcode_scanner_page.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/products/domain/entities/birim_model.dart';
import 'package:pos_app/features/products/domain/repositories/unit_repository.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/core/sync/sync_service.dart';
import 'package:pos_app/core/services/scanner_service.dart';
import 'package:pos_app/core/services/audio_service.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class CartView extends StatefulWidget {
  const CartView({
    super.key,
  });

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  // --- State Variables ---
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, FocusNode> _priceFocusNodes = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, FocusNode> _discountFocusNodes = {};
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _barcodeFocusNode2 = FocusNode();
  final TextEditingController _searchController2 = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, Future<String?>> _imageFutures = {};
  bool _isLoading = true;
  bool _audioLoaded = false;
  bool _productsLoaded = false;

  final Map<String, bool> _isBoxMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, int> _productScanCount = {}; // Her ürünün kaç kez okutulduğunu takip eder

  final Map<String, List<BirimModel>> _productBirimlerMap = {}; // Her ürün için birimler
  final Map<String, BirimModel?> _selectedBirimMap = {}; // Her ürün için seçili birim

  // ✅ Stok bilgilerini Map'te sakla (StokKodu -> miktar)
  final Map<String, double> _stockInfoMap = {};

  // ✅ Suggestions bilgilerini Map'te sakla (StokKodu -> formatted string)
  final Map<String, String> _suggestionsInfoMap = {};

  // Scanner'dan controller güncellenirken TextField onChanged'in tetiklenmemesi için
  bool _isUpdatingFromScanner = false;

  // El terminali için debounce timer (çift eklemeyi önler)
  Timer? _scanDebounceTimer;

  // Arama için debounce timer (yazarken her tuşa basmada tetiklenmemesi için)
  Timer? _searchDebounceTimer;

  Timer? _imageDownloadTimer;

  // --- Lifecycle Methods ---
  late bool Function(KeyEvent) _scannerHandler;

  @override
  void initState() {
    super.initState();

    // ⚡ SES DOSYALARINI İLK ÖNCE yükle (singleton - sadece ilk açılışta yükler!)
    _initializeAudioAndScanner();

    _loadProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncWithProvider();
    });
  }

  Future<void> _initializeAudioAndScanner() async {
    // ✅ AudioService - Lazy loading kullanıyor, pre-load gerekli değil
    print('✅ AudioService hazır (lazy loading ile ilk çalışta yüklenecek)');

    _audioLoaded = true;
    _checkLoadingComplete();

    // ✅ Scanner'ı ekle
    _scannerHandler = ScannerService.createHandler(_clearAndFocusBarcode);
    HardwareKeyboard.instance.addHandler(_scannerHandler);
  }

  void _checkLoadingComplete() {
    // İkisi de bitince loading'i kapat
    if (_audioLoaded && _productsLoaded && mounted) {
      setState(() {
        _isLoading = false;
      });
      print('✅ Loading tamamlandı: Ses ve ürünler hazır!');
    }
  }

  // ❌ didChangeDependencies KALDIRILDI - çok sık çağrılıyordu ve sayacı bozuyordu
  // Cleanup şimdi sadece gerekli yerlerde manuel olarak çağrılacak

  void _cleanupScanCounters() {
    // Sepetteki ürünlerin stokKodu'larını al
    final provider = Provider.of<CartProvider>(context, listen: false);
    final cartItemKeys = provider.items.keys.toSet();

    // Scan sayacında olup sepette olmayan ürünleri bul ve temizle
    final keysToRemove = _productScanCount.keys.where((key) => !cartItemKeys.contains(key)).toList();

    if (keysToRemove.isNotEmpty) {
      print('🧹 _cleanupScanCounters: Removing scan counters for: $keysToRemove');
      print('🧹 Current cart items: $cartItemKeys');
      for (final key in keysToRemove) {
        _productScanCount.remove(key);
      }
    }
  }


  @override
  void dispose() {
    _imageDownloadTimer?.cancel();
    _scanDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _barcodeFocusNode.dispose();
    _barcodeFocusNode2.dispose();
    _searchController2.dispose();
    _scrollController.dispose();
    _priceControllers.values.forEach((c) => c.dispose());
    _priceFocusNodes.values.forEach((f) => f.dispose());
    _discountControllers.values.forEach((c) => c.dispose());
    _quantityControllers.values.forEach((c) => c.dispose());
    _discountFocusNodes.values.forEach((f) => f.dispose());
    // AudioService singleton - dispose edilmez, uygulama boyunca yaşar
    // 🔑 Hardware keyboard listener kaldır
    HardwareKeyboard.instance.removeHandler(_scannerHandler);
    super.dispose();
  }

  // --- Product & Data Loading ---
  Future<void> _loadBirimlerForProduct(ProductModel product) async {
    final key = product.stokKodu;
    if (_productBirimlerMap.containsKey(key)) return; // Already loaded

    final unitRepository = Provider.of<UnitRepository>(context, listen: false);
    final birimler = await unitRepository.getBirimlerByStokKodu(product.stokKodu);

    if (mounted) {
      setState(() {
        _productBirimlerMap[key] = birimler;
        // ✅ Default birimi seç (ÖNCE BOX ara, yoksa ilk birimi seç)
        if (birimler.isNotEmpty) {
          // VARSAYILAN olarak BOX içeren birimi ara
          BirimModel? defaultBirim = birimler.cast<BirimModel?>().firstWhere(
            (b) {
              final birimAdi = b?.birimadi?.toLowerCase() ?? '';
              return birimAdi.contains('box');
            },
            orElse: () => null,
          );

          // BOX bulunamadıysa ilk birimi seç
          final selectedBirim = defaultBirim ?? birimler.first;
          _selectedBirimMap[key] = selectedBirim;
        }
      });
    }
  }

  /// Tüm ürünler için birimleri background'da yükle
  Future<void> _loadAllBirimler(List<ProductModel> products) async {
    if (products.isEmpty) return;

    // Sadece henüz yüklenmemiş ürünleri filtrele
    final newProducts = products.where((p) => !_productBirimlerMap.containsKey(p.stokKodu)).toList();

    if (newProducts.isEmpty) {
      print('🔄 Background birim yüklemesi: Tüm birimler zaten yüklü');
      return;
    }

    print('🔄 Background: ${newProducts.length} ürün için birimler yükleniyor...');

    final unitRepository = Provider.of<UnitRepository>(context, listen: false);
    int loadedCount = 0;

    for (final product in newProducts) {
      if (!mounted) break;

      final key = product.stokKodu;

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

              // ✅ _isBoxMap'i güncelle
              final birimAdi = selectedBirim.birimadi?.toLowerCase() ?? '';
              _isBoxMap[key] = birimAdi.contains('box');
            }
          });

          // ✅ Her 10 üründe bir ilerleme göster
          loadedCount++;
          if (loadedCount % 10 == 0 || loadedCount == newProducts.length) {
            print('🔄 Background: $loadedCount/${newProducts.length} ürün için birim yüklendi');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Birim yüklenemedi ($key): $e');
      }
    }

    print('✅ Background birim yüklemesi tamamlandı (${newProducts.length} ürün)');
  }

  /// ✅ OPTIMIZE: Sadece yeni ürünler için birimleri yükle (zaten yüklü olanları atla)
  Future<void> _loadBirimlerForNewProducts(List<ProductModel> products) async {
    if (products.isEmpty) return;

    // Sadece henüz yüklenmemiş ürünleri filtrele
    final newProducts = products.where((p) => !_productBirimlerMap.containsKey(p.stokKodu)).toList();

    if (newProducts.isEmpty) {
      print('✅ Tüm ürünler için birimler zaten yüklü');
      return;
    }

    print('📋 ${newProducts.length} yeni ürün için birimler yükleniyor...');

    final unitRepository = Provider.of<UnitRepository>(context, listen: false);
    int loadedCount = 0;

    for (final product in newProducts) {
      if (!mounted) break;

      final key = product.stokKodu;

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

              // ✅ _isBoxMap'i güncelle
              final birimAdi = selectedBirim.birimadi?.toLowerCase() ?? '';
              _isBoxMap[key] = birimAdi.contains('box');
            }
          });

          // ✅ Her 10 üründe bir ilerleme göster
          loadedCount++;
          if (loadedCount % 10 == 0 || loadedCount == newProducts.length) {
            print('📥 $loadedCount/${newProducts.length} ürün için birim yüklendi');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Birim yüklenemedi ($key): $e');
      }
    }

    print('✅ ${newProducts.length} ürün için birimler yüklendi');
  }

  /// ✅ OPTIMIZE: Sadece görünen ürünler için stok bilgilerini yükle
  Future<void> _loadStockInfoForProducts(List<ProductModel> products) async {
    if (products.isEmpty) return;

    try {
      final db = await DatabaseHelper().database;

      // ✅ Sadece bu ürünlerin stokKodu'larını al
      final stokKodlari = products.map((p) => p.stokKodu).toList();

      // ✅ SQL IN clause ile sadece bu ürünler için sorgu at
      final placeholders = stokKodlari.map((_) => '?').join(',');
      final stocks = await db.rawQuery(
        'SELECT StokKodu, miktar FROM Depostok WHERE StokKodu IN ($placeholders) AND UPPER(birim) = ?',
        [...stokKodlari, 'UNIT'],
      );

      // Map'e ekle
      for (final row in stocks) {
        final stokKodu = row['StokKodu'].toString();
        final miktar = (row['miktar'] as num?)?.toDouble() ?? 0.0;
        _stockInfoMap[stokKodu] = miktar;
      }

      // Bulunamayanlar için 0 ata
      for (final product in products) {
        if (!_stockInfoMap.containsKey(product.stokKodu)) {
          _stockInfoMap[product.stokKodu] = 0.0;
        }
      }

      print('✅ ${products.length} ürün için stok bilgisi yüklendi (${stocks.length} kayıt bulundu)');
    } catch (e) {
      debugPrint('⚠️ Stok bilgileri yüklenemedi: $e');
      for (final product in products) {
        _stockInfoMap[product.stokKodu] = 0.0;
      }
    }
  }


  Future<void> _loadProducts() async {
    // ⚡ İlk yüklemede sadece ID ve stokKodu'nu al (hafif veri)
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Sadece ilk 50 ürünü tam yükle, geri kalanı lazy loading
    final initialProducts = await db.query(
      'Product',
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'sortOrder ASC',
      limit: 50,
    );

    if (!mounted) return;

    print('⚡ Cart açıldı: İlk 50 ürün yüklendi (lazy loading aktif)');

    final products = initialProducts.map((json) => ProductModel.fromMap(json)).toList();

    // ✅ Ürünleri alfabetik + stok bazlı sırala
    await _sortProductsWithStock(products);

    setState(() {
      _allProducts = products; // İlk başta sadece 50 ürün
      _filteredProducts = products;
      _generateImageFutures(_filteredProducts);
    });

    // ✅ Sadece görünen ürünler için stok bilgilerini yükle
    await _loadStockInfoForProducts(products);

    // ✅ Birimleri background'da yükle (UI'ı bloklamadan)
    Future.microtask(() => _loadAllBirimler(products));

    // ✅ Default değerleri ata (birimler yüklenirken bile UI gösterebilmek için)
    for (var product in products) {
      final key = product.stokKodu;
      if (!_isBoxMap.containsKey(key)) {
        _isBoxMap[key] = false; // Default Unit
      }
      _quantityMap[key] = 0;
    }

    _productsLoaded = true;
    _checkLoadingComplete();
  }

  /// Ürünleri sırala: durum (suspended sona) > stok (fazladan aza) > alfabetik (A-Z)
  /// Primary: Durum (aktif=1 önce, suspended=0 sona)
  /// Secondary: Stok miktarı (fazladan aza)
  /// Tertiary: Alfabetik (A-Z)
  Future<void> _sortProductsWithStock(List<ProductModel> products) async {
    try {
      final db = await DatabaseHelper().database;

      // Tüm stokları tek sorguda çek (UNIT bazlı)
      final allStocks = await db.query(
        'Depostok',
        columns: ['StokKodu', 'miktar'],
        where: 'UPPER(birim) = ?',
        whereArgs: ['UNIT'],
      );

      // Map'e dönüştür: StokKodu -> miktar
      final stockMap = Map<String, double>.fromEntries(
        allStocks.map((row) => MapEntry(
          row['StokKodu'].toString(),
          (row['miktar'] as num?)?.toDouble() ?? 0.0,
        ))
      );

      // Üçlü kriterli sıralama
      products.sort((a, b) {
        // 1. Primary: Durum (suspended=0 sona, aktif=1 önce)
        if (a.aktif != b.aktif) {
          return b.aktif.compareTo(a.aktif); // 1 önce, 0 sona
        }

        // 2. Secondary: Stok miktarına göre (fazla olan önce)
        final stockA = stockMap[a.stokKodu] ?? a.miktar ?? 0.0;
        final stockB = stockMap[b.stokKodu] ?? b.miktar ?? 0.0;

        if (stockA != stockB) {
          return stockB.compareTo(stockA); // Büyükten küçüğe
        }

        // 3. Tertiary: Alfabetik sıralama (A-Z)
        final nameA = a.urunAdi.trim().toLowerCase();
        final nameB = b.urunAdi.trim().toLowerCase();
        return nameA.compareTo(nameB);
      });

      print('✅ Ürünler sıralandı: ${products.length} ürün (Durum > Stok > A-Z)');
    } catch (e) {
      print('⚠️ Sıralama hatası: $e');
      // Hata olursa sadece alfabetik sırala
      products.sort((a, b) =>
        a.urunAdi.trim().toLowerCase().compareTo(b.urunAdi.trim().toLowerCase())
      );
    }
  }

  Future<void> _syncWithProvider() async {
    final provider = Provider.of<CartProvider>(context, listen: false);

    // ⚡ Sadece sepette olan ürünleri sync et (18985 yerine ~10-20 ürün)
    if (provider.items.isEmpty) return;

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    for (var cartItem in provider.items.values) {
      final key = cartItem.stokKodu;

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
          // _allProducts listesine ekle (bir dahaki sefere tekrar sorgulamayalım)
          if (mounted) {
            setState(() {
              _allProducts.add(product!);
            });
          }
        } else {
          // Ürün veritabanında yok - skip
          continue;
        }
      }

      // ✅ CartProvider'dan birimTipi'yi al ve _isBoxMap'i güncelle
      // Bu sayede kullanıcının dropdown seçimi korunur
      final cartBirimTipi = cartItem.birimTipi;
      _isBoxMap[key] = cartBirimTipi == 'Box';

      // ✅ selectedBirimKey'i restore et
      if (cartItem.selectedBirimKey != null) {
        // Birimler listesini yükle (eğer yoksa)
        await _loadBirimlerForProduct(product);

        // selectedBirimKey ile eşleşen BirimModel'i bul
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

      final miktar = provider.getmiktar(key, cartBirimTipi);
      final iskonto = provider.getIskonto(key);

      if (mounted) {
        setState(() {
          _quantityMap[key] = miktar;

          // ⚠️ KRITIK: Focus yoksa güncelle (kullanıcı yazmaya başlamamışsa)
          // Note: cart_view.dart'ta quantity için FocusNode map'i yok, sadece controller var
          // Bu yüzden quantity her zaman güncellenir (ProductListItem'da zaten focus kontrolü var)
          _quantityControllers[key]?.text = miktar.toString();

          if (!(_discountFocusNodes[key]?.hasFocus ?? false)) {
            _discountControllers[key]?.text = iskonto > 0 ? iskonto.toString() : '';
          }
          if (_priceControllers.containsKey(key) && miktar == 0 && !(_priceFocusNodes[key]?.hasFocus ?? false)) {
            // ✅ Price override'ı koru: CartItem'dan birimFiyat al
            final displayPrice = (cartItem.birimFiyat * (1 - iskonto / 100)).toStringAsFixed(2);
            _priceControllers[key]!.text = displayPrice;
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
        SyncService.downloadSearchResultImages(_filteredProducts, onImagesDownloaded: () {
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
    await AudioService.instance.playWrong();
  }

  /// Her ürün için sıralı ses çalar
  /// SUSPENDED ürünler (miktar <= 0): HER ZAMAN dit.mp3
  /// Normal ürünler - İlk okutma: beepk.mp3, sonraki tüm okutmalar: boopk.mp3
  Future<void> playBeepForProduct(ProductModel product) async {
    // ✅ Suspended kontrolü: miktar 0 veya negatif ise suspended
    // NOT: ProductImage'deki showBanner ile AYNI kontrol!
    final isSuspended = (product.miktar ?? 0) <= 0;

    // 🐛 DEBUG
    print('🔊 playBeepForProduct(${product.stokKodu}): isSuspended=$isSuspended, miktar=${product.miktar}');

    // ⚠️ SUSPENDED ÜRÜN: HER ZAMAN dit.mp3 çal
    if (isSuspended) {
      print('🔊 Playing DIT (SUSPENDED product)');
      await AudioService.instance.playDit();
      return; // Suspended ürünler için sayaç kullanmıyoruz
    }

    // ✅ NORMAL ÜRÜN: Sayaç mantığı ile beepk/boopk çal
    final currentCount = _productScanCount[product.stokKodu] ?? 0;

    // ✅ CRITICAL: Sayacı HEMEN artır (ses çalmadan önce!)
    // Bu race condition'ı önler (ard arda hızlı okutunca sayaç doğru artar)
    _productScanCount[product.stokKodu] = currentCount + 1;

    print('🔊 playBeepForProduct(${product.stokKodu}): count=$currentCount → ${_productScanCount[product.stokKodu]}');

    // İlk okutma (currentCount == 0): beepk.mp3
    // Sonraki tüm okutmalar: boopk.mp3
    if (currentCount == 0) {
      // İlk okutma - beepk.mp3
      print('🔊 Playing BEEPK (first scan)');
      await AudioService.instance.playBeepK();
    } else {
      // Sonraki okutmalar - boopk.mp3
      print('🔊 Playing BOOPK (repeat scan)');
      await AudioService.instance.playBoopK();
    }
  }

  void _onBarcodeScanned(String barcode) {
    if (!mounted) return; // Widget dispose edilmişse çık

    print('✅ Barcode scanned: $barcode');

    // Flag set et ki AppBar TextField'ın onChanged'i tetiklenmesin
    _isUpdatingFromScanner = true;
    _searchController2.text = barcode;
    _isUpdatingFromScanner = false;

    // _filterProducts içinde zaten ses çalıyor, burada tekrar çalmasına gerek yok
    _filterProducts();
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

  // --- Filtering & Searching ---
  void _filterProducts({String? queryOverride}) async {
    final provider = Provider.of<CartProvider>(context, listen: false);
    final query = (queryOverride ?? _searchController2.text).trimRight().toLowerCase();
    final fromUI = queryOverride != null;

    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts.take(50).toList();
        _generateImageFutures(_filteredProducts);
      });
      return;
    }

    // ⚡ Arama yapılıyorsa veritabanından direkt ara (SQL LIKE kullan)
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();

    // SQL LIKE sorgusu oluştur
    String whereClause = queryWords.map((_) =>
      '(urunAdi LIKE ? OR stokKodu LIKE ? OR barcode1 LIKE ? OR barcode2 LIKE ? OR barcode3 LIKE ? OR barcode4 LIKE ?)'
    ).join(' AND ');

    List<String> whereArgs = [];
    for (var word in queryWords) {
      final likePattern = '%$word%';
      whereArgs.addAll([likePattern, likePattern, likePattern, likePattern, likePattern, likePattern]);
    }

    final searchResults = await db.query(
      'Product',
      where: 'aktif = ? AND ($whereClause)',
      whereArgs: [1, ...whereArgs],
      orderBy: 'sortOrder ASC',
      limit: 50,
    );

    if (!mounted) return;

    final filtered = searchResults.map((json) => ProductModel.fromMap(json)).toList();

    // ✅ Ürünleri alfabetik + stok bazlı sırala
    await _sortProductsWithStock(filtered);

    setState(() {
      _filteredProducts = filtered; // Zaten 50 ile limitli
      _generateImageFutures(_filteredProducts);
    });

    // ✅ Arama sonuçları için stok bilgilerini yükle
    await _loadStockInfoForProducts(filtered);

    // ✅ OPTIMIZE: Birimleri ve resimleri PARALEL yükle
    _scheduleImageDownload(); // Resim indirmeyi hemen başlat (paralel)

    // ✅ OPTIMIZE: Sadece yeni ürünler için birimleri toplu olarak yükle
    await _loadBirimlerForNewProducts(filtered);

    // Arama yapıldığında listenin en üste scroll edilmesi
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    if (!fromUI) {
      if (_filteredProducts.length == 1 && RegExp(r'^\d+$').hasMatch(query)) {
        final product = _filteredProducts.first;
        final key = product.stokKodu;

        // ⚠️ SUSPENDED KONTROL: miktar <= 0 ise sepete EKLEME!
        final isSuspended = (product.miktar ?? 0) <= 0;
        if (isSuspended) {
          print('⚠️ SUSPENDED ürün sepete EKLENMEDİ: ${product.urunAdi} (miktar: ${product.miktar})');
          playBeepForProduct(product); // Ses çal (ditdit.mp3)
          _clearAndFocusBarcode();
          return; // Sepete ekleme - sadece ses çal ve çık
        }

        // ✅ Seçili birimi al (yoksa default)
        final selectedBirim = _selectedBirimMap[key];
        final selectedBirimKey = selectedBirim?.key;

        print('🔍 BARCODE SCAN - Product: ${product.urunAdi}');
        print('   stokKodu: $key');
        print('   selectedBirim: ${selectedBirim?.birimadi} (fiyat7: ${selectedBirim?.fiyat7})');
        print('   _isBoxMap[$key]: ${_isBoxMap[key]}');

        // ✅ Birim tipini seçili birimden al (yoksa default: UNIT)
        final birimTipi = selectedBirim != null
            ? (selectedBirim.birimkod ?? selectedBirim.birimadi ?? 'UNIT').toUpperCase()
            : 'UNIT';

        print('   birimTipi: $birimTipi');

        // ✅ Birimler listesi kontrolü (artık birimKey yok)
        final hasBirimler = _productBirimlerMap[key]?.isNotEmpty ?? false;
        final hasFiyat = (product.adetFiyati.toString() != '0') ||
                        (product.kutuFiyati.toString() != '0');

        if (hasBirimler || hasFiyat) {
          final cartItem = provider.items[key];
          final iskonto = cartItem?.iskonto ?? 0;

          // Fiyatı seçili birimden veya default'tan al
          double birimFiyat;
          if (selectedBirim != null) {
            // ✅ Birim fiyatını fiyat7 sütunundan al (dinamik fiyatlandırma)
            birimFiyat = selectedBirim.fiyat7 ?? 0;
            print('   ✅ Using selectedBirim.fiyat7: $birimFiyat');
          } else {
            // Eski sistem: Box/Unit fiyatı (fallback - birim bulunamazsa)
            final isBox = _isBoxMap[key] ?? false;
            birimFiyat = isBox
                ? double.tryParse(product.kutuFiyati.toString()) ?? 0
                : double.tryParse(product.adetFiyati.toString()) ?? 0;
            print('   ⚠️ Using fallback (isBox=$isBox): $birimFiyat');
          }

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
            selectedBirimKey: selectedBirimKey, // ✅ Seçili birimi kaydet
          );
          // Başarılı ekleme sonrası temizle ve fokusla
          playBeepForProduct(product); // ✅ Product gönder
        }
        _clearAndFocusBarcode();
      } else if (_filteredProducts.isEmpty && query.length > 10 && RegExp(r'^\d+$').hasMatch(query)) {
        playWrong();
        _clearAndFocusBarcode();
      }
    }
  }

  void _clearAndFocusBarcode() {
    // El terminali için sadece controller'ı temizle, focus'u koru
    _searchController2.clear(); // Tek controller kullan
    // Focus'u hemen geri ver, delay olmadan
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
    final provider = Provider.of<CartProvider>(context, listen: false);
    final newQuantity = int.tryParse(value) ?? 0;

    // ⚠️ FIX: _isBoxMap yerine getBirimTipiFromProduct kullan (doğru birim tipini alır)
    final birimTipi = getBirimTipiFromProduct(product) ?? 'UNIT';

    final currentQuantity = provider.getmiktar(key, birimTipi);
    final difference = newQuantity - currentQuantity;

    if (difference == 0) return;

    if (newQuantity <= 0) {
      provider.removeItem(key, birimTipi);
      // ✅ Ürün sepetten çıkarıldığında scan sayacını sıfırla
      _productScanCount.remove(key);
    } else {
      // ✅ FIX: Mevcut sepet item'ındaki custom fiyatı koru!
      final cartKey = '${key}_$birimTipi';
      final existingCartItem = provider.items[cartKey];

      final selectedBirim = _selectedBirimMap[key];

      // Eğer sepette bu birim için custom fiyat varsa onu kullan, yoksa orijinal fiyatı al
      final fiyat = existingCartItem?.birimFiyat ?? (
          selectedBirim != null
              ? (selectedBirim.fiyat7 ?? 0)
              : (birimTipi == 'UNIT' || birimTipi == 'Unit')
                  ? double.tryParse(product.adetFiyati.toString()) ?? 0
                  : double.tryParse(product.kutuFiyati.toString()) ?? 0
      );

      final iskonto = existingCartItem?.iskonto ?? provider.getIskonto(key);

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
        selectedBirimKey: _selectedBirimMap[key]?.key, // ✅ Seçili birimi kaydet
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

    // ✅ Seçili birimden birimkod'u al (UPPERCASE)
    final selectedBirim = _selectedBirimMap[key];
    if (selectedBirim != null) {
      return (selectedBirim.birimkod ?? selectedBirim.birimadi ?? 'UNIT').toUpperCase();
    }

    // ⚠️ Fallback: Eski mantık (uyumluluk için) - UPPERCASE
    final isBox = _isBoxMap[key] ?? ((double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0);
    if (isBox && (double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0) return 'BOX';
    if (!isBox && (double.tryParse(product.adetFiyati.toString()) ?? 0) > 0) return 'UNIT';
    if ((double.tryParse(product.kutuFiyati.toString()) ?? 0) > 0) return 'BOX';
    if ((double.tryParse(product.adetFiyati.toString()) ?? 0) > 0) return 'UNIT';
    return null;
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CartProvider>(context);
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    String musteriId = customer?.kod ?? "";
    final cartItems = provider.items.values.toList();
    // ✅ Tüm birimleri topla (dinamik birim sistemi için)
    final totalQuantity = cartItems.fold<int>(0, (sum, item) => sum + item.miktar);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleSpacing: 0,
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
            onChanged: (value) {
              // Scanner'dan güncelleme yapılıyorsa ignore et (çift çağrıyı önle)
              if (_isUpdatingFromScanner) return;

              // Debounce timer: Timer'ı iptal et ve yeniden başlat
              _searchDebounceTimer?.cancel();
              print('⏱️ Search debounce timer started (500ms) for: "$value"');
              _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  print('✅ Search debounce timer fired for: "$value"');
                  _filterProducts(queryOverride: value);
                }
              });
            },
          ),
        ),
        actions: [
          _buildShoppingCartIcon(cartItems.length, totalQuantity),
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
                  controller: _searchController2, // Tek controller kullan - controller sync kaldırıldı
                  onChanged: (value) {
                    // El terminali için debounce: Timer'ı iptal et ve yeniden başlat
                    _scanDebounceTimer?.cancel();
                    _scanDebounceTimer = Timer(const Duration(milliseconds: 150), () {
                      if (mounted) {
                        _filterProducts();
                      }
                    });
                  },
                  onSubmitted: (value) {
                    // Enter tuşuna basıldığında timer'ı iptal et ve hemen işle
                    _scanDebounceTimer?.cancel();
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
      onTap: () async {
        // CartView2'ye git
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const CartView2()));

        // CartView2'den döndükten sonra scan sayacını temizle
        _cleanupScanCounters();

        // ✅ Sepet tamamen boşsa tüm scan counter'ları temizle
        final provider = Provider.of<CartProvider>(context, listen: false);
        if (provider.items.isEmpty) {
          setState(() {
            _productScanCount.clear();
            print('🧹 Sepet boş - tüm scan counter\'lar temizlendi');
          });
        }
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
    return Center(child: Text('cart.no_products'.tr()));
  }

  Widget _buildProductList(CartProvider provider) {
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final key = product.stokKodu;

        final selectedType = getBirimTipiFromProduct(product);
        final cartKey = '${key}_${selectedType ?? 'UNIT'}';
        final cartItem = provider.items[cartKey];

        // ✅ Controller'ları oluştur (sadece bir kez)
        if (!_priceControllers.containsKey(key)) {
          final initialPrice = cartItem != null
              ? (cartItem.birimFiyat * (1 - cartItem.iskonto / 100)).toStringAsFixed(2)
              : (selectedType ?? 'UNIT').toUpperCase() == 'UNIT'
              ? (double.tryParse(product.adetFiyati.toString()) ?? 0).toStringAsFixed(2)
              : (double.tryParse(product.kutuFiyati.toString()) ?? 0).toStringAsFixed(2);
          _priceControllers[key] = TextEditingController(text: initialPrice);
        }
        if (!_discountControllers.containsKey(key)) {
          final iskonto = cartItem?.iskonto ?? 0;
          _discountControllers[key] = TextEditingController(text: iskonto > 0 ? iskonto.toString() : '');
        }

        // ✅ Controller'lar oluşturulduktan SONRA: CartProvider'dan güncel değerlerle senkronize et
        // ⚠️ KRITIK: Focus varsa (kullanıcı yazmaya başlamış) otomatik doldurma yapma!

        // Price controller senkronizasyonu
        if (!(_priceFocusNodes[key]?.hasFocus ?? false)) {
          final expectedPrice = cartItem != null
              ? (cartItem.birimFiyat * (1 - cartItem.iskonto / 100)).toStringAsFixed(2)
              : (selectedType ?? 'UNIT').toUpperCase() == 'UNIT'
              ? (double.tryParse(product.adetFiyati.toString()) ?? 0).toStringAsFixed(2)
              : (double.tryParse(product.kutuFiyati.toString()) ?? 0).toStringAsFixed(2);

          if (_priceControllers[key]!.text != expectedPrice) {
            _priceControllers[key]!.text = expectedPrice;
          }
        }

        // Discount controller senkronizasyonu
        if (!(_discountFocusNodes[key]?.hasFocus ?? false)) {
          final iskonto = cartItem?.iskonto ?? 0;
          final expectedDiscount = iskonto > 0 ? iskonto.toString() : '';

          if (_discountControllers[key]!.text != expectedDiscount) {
            _discountControllers[key]!.text = expectedDiscount;
          }
        }
        if (!_priceFocusNodes.containsKey(key)) {
          _priceFocusNodes[key] = FocusNode();
        }
        if (!_discountFocusNodes.containsKey(key)) {
          _discountFocusNodes[key] = FocusNode();
        }
        if (!_quantityControllers.containsKey(key)) {
          final birimTipi = selectedType ?? (_isBoxMap[key] ?? false ? 'Box' : 'Unit');
          _quantityControllers[key] = TextEditingController(text: provider.getmiktar(key, birimTipi).toString());
        }

        // Load birimler for this product if not loaded
        if (!_productBirimlerMap.containsKey(key)) {
          _loadBirimlerForProduct(product);
        }

        return ProductListItem(
          key: ValueKey(product.stokKodu),
          product: product,
          provider: provider,
          imageFuture: _imageFutures[key],
          priceController: _priceControllers[key]!,
          priceFocusNode: _priceFocusNodes[key]!,
          discountController: _discountControllers[key]!,
          quantityController: _quantityControllers[key]!,
          discountFocusNode: _discountFocusNodes[key]!,
          isBox: _isBoxMap[key] ?? false,
          quantity: context.watch<CartProvider>().getmiktar(key, (_isBoxMap[key] ?? false) ? 'Box' : 'Unit'),
          birimler: _productBirimlerMap[key] ?? [],
          selectedBirim: _selectedBirimMap[key],
          suggestionsInfoMap: _suggestionsInfoMap,
          onBirimTipiChanged: (isNowBox) {
            // ⚠️ DEPRECATED: Bu callback artık kullanılmıyor
            // onBirimChanged callback'i tüm işi yapıyor
          },
          onBirimChanged: (BirimModel? newBirim) {
            setState(() {
              _selectedBirimMap[key] = newBirim;
            });

            print('🔄 onBirimChanged in cart_view.dart:');
            print('   stokKodu: $key');
            print('   newBirim: ${newBirim?.birimadi} (fiyat7: ${newBirim?.fiyat7})');

            // ✅ Seçili birimi CartProvider'a kaydet
            if (newBirim != null) {
              // ⚠️ FIX: ESKİ birim tipindeki item'ı bul (tüm sepet itemlarını tara)
              CartItem? oldCartItem;
              String? oldCartKey;

              // Sepetteki bu stokKodu'na ait tüm itemları kontrol et
              // ✅ FIX: FREE itemları hariç tut (FREE itemların stokKodu'nda (FREE) var)
              for (var entry in provider.items.entries) {
                if (entry.key.startsWith('${product.stokKodu}_') &&
                    !entry.value.stokKodu.contains('(FREE')) {
                  oldCartItem = entry.value;
                  oldCartKey = entry.key;
                  break;
                }
              }

              print('   oldCartKey: $oldCartKey');
              print('   oldCartItem exists: ${oldCartItem != null}');

              if (oldCartItem != null && oldCartKey != null) {
                final birimTipi = (newBirim.birimkod ?? newBirim.birimadi ?? 'UNIT').toUpperCase();
                final birimFiyat = newBirim.fiyat7 ?? 0; // ✅ fiyat7 kullan
                final newCartKey = '${product.stokKodu}_$birimTipi';

                print('   birimTipi: $birimTipi');
                print('   newCartKey: $newCartKey');
                print('   birimFiyat: $birimFiyat');

                // ⚠️ KRITIK: Eski item'ı sil, yeni item ekle (birim tipi değiştiği için key değişir)
                if (oldCartKey != newCartKey) {
                  print('   🔄 Birim değişti, eski item siliniyor ve yeni item ekleniyor');
                  provider.removeItem(oldCartKey);
                }

                provider.addOrUpdateItem(
                  stokKodu: product.stokKodu,
                  urunAdi: product.urunAdi,
                  birimFiyat: birimFiyat,
                  urunBarcode: product.barcode1,
                  miktar: oldCartItem.miktar, // ⚠️ FIX: Eski miktarı koru (0 DEĞİL!)
                  iskonto: oldCartItem.iskonto,
                  birimTipi: birimTipi,
                  vat: product.vat,
                  imsrc: product.imsrc,
                  adetFiyati: product.adetFiyati,
                  kutuFiyati: product.kutuFiyati,
                  selectedBirimKey: newBirim.key, // ✅ Seçili birimi kaydet
                );

                // ✅ KRITIK: Price controller'ı yeni birim fiyatıyla güncelle
                final priceController = _priceControllers[key];
                if (priceController != null) {
                  priceController.text = birimFiyat.toStringAsFixed(2);
                  print('   ✅ Price controller updated to: ${birimFiyat.toStringAsFixed(2)}');
                } else {
                  print('   ⚠️ Price controller not found for key: $key');
                }
              } else {
                print('   ⚠️ Eski cart item bulunamadı - sepette item yok');
              }
            }
          },
          onQuantityChanged: (newQuantity) {
            setState(() {
              _quantityMap[key] = newQuantity;
              // ✅ Miktar 0'a düştüğünde scan sayacını temizle
              if (newQuantity <= 0) {
                _productScanCount.remove(key);
              }
            });
          },
          updateQuantityFromTextField: (value) => _updateQuantityFromTextField(key, value, product),
          formatPriceField: () => _formatPriceField(_priceControllers[key]!),
          getBirimTipi: () => getBirimTipiFromProduct(product),
          availableStock: _stockInfoMap[product.stokKodu],
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

class ProductListItem extends StatefulWidget {
  final ProductModel product;
  final CartProvider provider;
  final Future<String?>? imageFuture;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final TextEditingController discountController;
  final TextEditingController quantityController;
  final FocusNode discountFocusNode;
  final bool isBox;
  final int quantity;
  final List<BirimModel> birimler;
  final BirimModel? selectedBirim;
  final ValueChanged<bool> onBirimTipiChanged;
  final ValueChanged<BirimModel?> onBirimChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> updateQuantityFromTextField;
  final VoidCallback formatPriceField;
  final String? Function() getBirimTipi;
  final double? availableStock; // ✅ Stok bilgisi
  final Map<String, String> suggestionsInfoMap; // ✅ Suggestions cache

  const ProductListItem({
    super.key,
    required this.product,
    required this.provider,
    this.imageFuture,
    required this.priceController,
    required this.priceFocusNode,
    required this.discountController,
    required this.quantityController,
    required this.discountFocusNode,
    required this.isBox,
    required this.quantity,
    required this.birimler,
    required this.selectedBirim,
    required this.onBirimTipiChanged,
    required this.onBirimChanged,
    required this.onQuantityChanged,
    required this.updateQuantityFromTextField,
    required this.formatPriceField,
    required this.getBirimTipi,
    this.availableStock,
    required this.suggestionsInfoMap,
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
    final cartKey = '${widget.product.stokKodu}_$birimTipi';
    final cartProvider = context.watch<CartProvider>();
    final anlikMiktar = cartProvider.getmiktar(widget.product.stokKodu, birimTipi);
    final cartItem = cartProvider.items[cartKey];

    // ✅ Build içinde controller değiştirme - build bittikten SONRA yap
    // ⚠️ KRITIK: Focus varsa (kullanıcı yazmaya başlamış) otomatik doldurma yapma!
    if (!_quantityFocusNode.hasFocus && widget.quantityController.text != anlikMiktar.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Callback içinde tekrar kontrol et: Focus hala yoksa güncelle
        if (mounted && !_quantityFocusNode.hasFocus && widget.quantityController.text != anlikMiktar.toString()) {
          widget.quantityController.text = anlikMiktar.toString();
        }
      });
    }

    // ✅ FIX: Price controller'ı de sepetteki güncel ve INDIRIMLI fiyatla senkronize et
    if (cartItem != null && !widget.priceFocusNode.hasFocus) {
      final discountedPrice = cartItem.birimFiyat * (1 - cartItem.iskonto / 100);
      final expectedPriceText = discountedPrice.toStringAsFixed(2);
      if (widget.priceController.text != expectedPriceText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !widget.priceFocusNode.hasFocus && widget.priceController.text != expectedPriceText) {
            widget.priceController.text = expectedPriceText;
          }
        });
      }
    }

    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(
            imageFuture: widget.imageFuture,
            product: widget.product,
            selectedBirim: widget.selectedBirim,
            availableStock: widget.availableStock,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: ProductDetails(
              product: widget.product,
              provider: widget.provider,
              priceController: widget.priceController,
              priceFocusNode: widget.priceFocusNode,
              discountController: widget.discountController,
              quantityController: widget.quantityController,
              discountFocusNode: widget.discountFocusNode,
              quantityFocusNode: _quantityFocusNode, // Pass focus node down
              isBox: widget.isBox,
              quantity: anlikMiktar,
              birimler: widget.birimler,
              selectedBirim: widget.selectedBirim,
              onBirimTipiChanged: widget.onBirimTipiChanged,
              onBirimChanged: widget.onBirimChanged,
              onQuantityChanged: widget.onQuantityChanged,
              updateQuantityFromTextField: widget.updateQuantityFromTextField,
              formatPriceField: widget.formatPriceField,
              getBirimTipi: widget.getBirimTipi,
              suggestionsInfoMap: widget.suggestionsInfoMap,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImage extends StatefulWidget {
  final Future<String?>? imageFuture;
  final ProductModel product;
  final BirimModel? selectedBirim;
  final double? availableStock; // ✅ Parent'tan geçilecek

  const ProductImage({
    super.key,
    this.imageFuture,
    required this.product,
    this.selectedBirim,
    this.availableStock,
  });

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  // ✅ Stok bilgisi artık parent'tan gelecek, initState'te yükleme yok

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
    // ✅ Banner'ı Depostok stok bilgisine göre göster
    final showBanner = (widget.availableStock ?? widget.product.miktar ?? 0) <= 0;

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
                // Suspended banner for products with id == 1 (ilk ürün)
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
    // ✅ Stok bilgisi artık parent'tan geldiği için loading yok

    // ✅ Depostok fallback mantığından gelen stok bilgisini kullan (UNIT cinsinden)
    final unitStock = widget.availableStock ?? widget.product.miktar ?? 0.0;

    // ✅ Seçili birime göre stoğu hesapla (carpan ile böl)
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

    // Add subtle shadow effect
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class ProductDetails extends StatefulWidget {
  final ProductModel product;
  final CartProvider provider;
  final TextEditingController priceController;
  final FocusNode priceFocusNode;
  final TextEditingController discountController;
  final TextEditingController quantityController;
  final FocusNode discountFocusNode;
  final FocusNode quantityFocusNode;
  final bool isBox;
  final int quantity;
  final List<BirimModel> birimler;
  final BirimModel? selectedBirim;
  final ValueChanged<bool> onBirimTipiChanged;
  final ValueChanged<BirimModel?> onBirimChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> updateQuantityFromTextField;
  final VoidCallback formatPriceField;
  final String? Function() getBirimTipi;
  final Map<String, String> suggestionsInfoMap; // ✅ Cache map'i parent'tan al

  const ProductDetails({
    super.key,
    required this.product,
    required this.provider,
    required this.priceController,
    required this.priceFocusNode,
    required this.discountController,
    required this.quantityController,
    required this.discountFocusNode,
    required this.quantityFocusNode,
    required this.isBox,
    required this.quantity,
    required this.birimler,
    required this.selectedBirim,
    required this.onBirimTipiChanged,
    required this.onBirimChanged,
    required this.onQuantityChanged,
    required this.updateQuantityFromTextField,
    required this.formatPriceField,
    required this.getBirimTipi,
    required this.suggestionsInfoMap,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  String _oldPriceValue = '';

  @override
  void initState() {
    super.initState();
    widget.discountFocusNode.addListener(_onDiscountFocusChange);
    widget.priceFocusNode.addListener(_onPriceFocusChange);
  }

  @override
  void dispose() {
    widget.discountFocusNode.removeListener(_onDiscountFocusChange);
    widget.priceFocusNode.removeListener(_onPriceFocusChange);
    super.dispose();
  }

  void _onDiscountFocusChange() {
    if (widget.discountFocusNode.hasFocus) {
      // Focus kazanıldığında alanı temizle
      widget.discountController.clear();
    } else {
      // Odak kaybedildiğinde provider'ı güncelle. Bu, hem Enter tuşuna basıldığında
      // (bu da odak kaybına neden olur) hem de başka bir alana tıklandığında
      // tutarlı bir davranış sağlar.
      _applyDiscountToProvider(widget.discountController.text);
    }
  }

  // ✅ Helper metod: Discount'u provider'a uygula
  void _applyDiscountToProvider(String val) {
    final selectedType = widget.getBirimTipi() ?? 'Unit';
    final cartKey = '${widget.product.stokKodu}_$selectedType';
    final cartItem = widget.provider.items[cartKey];

    // ⚠️ SADECE sepette olan itemler için provider'ı güncelle
    // Eğer item henüz sepette değilse, sadece preview için controller'ları güncelle
    if (cartItem == null || cartItem.miktar <= 0) {
      // Item sepette değil - sadece preview için controller'ları güncelle
      // ✅ FIX: selectedBirim.fiyat7'den fiyat al (product.adetFiyati/kutuFiyati DEĞİL!)
      double previewPrice;
      if (widget.selectedBirim != null) {
        // Seçili birim varsa fiyat7'den al
        previewPrice = widget.selectedBirim!.fiyat7 ?? 0;
      } else {
        // Yoksa eski mantık (fallback)
        previewPrice = (selectedType.toUpperCase() == 'UNIT')
            ? (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
            : (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (val.isEmpty) {
            widget.discountController.text = '';
            widget.priceController.text = previewPrice.toStringAsFixed(2);
          } else {
            double discountPercent = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
            if (discountPercent > 100) discountPercent = 100;
            final discountedPrice = previewPrice * (1 - (discountPercent / 100));
            widget.priceController.text = discountedPrice.toStringAsFixed(2);
          }
        }
      });
      return;
    }

    // Item sepette var - provider'ı güncelle
    final currentBirimFiyat = cartItem.birimFiyat;

    if (val.isEmpty) {
      // İskonto kaldırıldı
      widget.provider.addOrUpdateItem(
        stokKodu: widget.product.stokKodu,
        miktar: 0, // +0 = quantity doesn't change
        iskonto: 0.0,
        birimTipi: selectedType,
        urunAdi: widget.product.urunAdi,
        birimFiyat: currentBirimFiyat,
        vat: widget.product.vat,
        imsrc: widget.product.imsrc,
        adetFiyati: widget.product.adetFiyati,
        kutuFiyati: widget.product.kutuFiyati,
        urunBarcode: widget.product.barcode1,
        selectedBirimKey: widget.selectedBirim?.key,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.discountController.text = '';
          widget.priceController.text = currentBirimFiyat.toStringAsFixed(2);
        }
      });
    } else {
      double discountPercent = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
      if (discountPercent > 100) discountPercent = 100;

      final discountedPrice = currentBirimFiyat * (1 - (discountPercent / 100));

      widget.provider.addOrUpdateItem(
        stokKodu: widget.product.stokKodu,
        miktar: 0, // +0 = quantity doesn't change
        iskonto: discountPercent,
        birimTipi: selectedType,
        urunAdi: widget.product.urunAdi,
        birimFiyat: currentBirimFiyat,
        vat: widget.product.vat,
        imsrc: widget.product.imsrc,
        adetFiyati: widget.product.adetFiyati,
        kutuFiyati: widget.product.kutuFiyati,
        urunBarcode: widget.product.barcode1,
        selectedBirimKey: widget.selectedBirim?.key,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.discountController.text = discountPercent.toString();
          widget.priceController.text = discountedPrice.toStringAsFixed(2);
        }
      });
    }
  }

  void _onPriceFocusChange() {
    if (widget.priceFocusNode.hasFocus) {
      // Focus kazanıldığında eski değeri sakla ve alanı temizle
      _oldPriceValue = widget.priceController.text;
      widget.priceController.clear();
    } else {
      // ✅ Focus kaybında provider'a kaydet
      // ANCAK sadece ürün sepette varsa (quantity > 0)
      if (widget.quantity <= 0) {
        // Ürün sepette yok, kaydetme!
        return;
      }

      // ✅ Boş alan varsa eski değeri geri yükle
      if (widget.priceController.text.isEmpty && _oldPriceValue.isNotEmpty) {
        if (mounted) {
          widget.priceController.text = _oldPriceValue;
        }
        return; // Boş ise eski değer geri yüklendi, işlem tamamlandı
      }

      final yeniFiyat = double.tryParse(widget.priceController.text.replaceAll(',', '.')) ?? 0;

      // ✅ Güncel birim tipini al
      final currentBirimType = widget.getBirimTipi() ?? 'Unit';

      // ⚠️ KRITIK: Orijinal fiyatı selectedBirim.fiyat7'den al (product.kutuFiyati/adetFiyati DEĞİL!)
      var orjinalFiyat = widget.selectedBirim != null
          ? (widget.selectedBirim!.fiyat7 ?? 0)
          : (currentBirimType == 'Unit' || currentBirimType == 'UNIT')
              ? (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
              : (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0);
      if (orjinalFiyat <= 0) orjinalFiyat = yeniFiyat;

      // ✅ FİYAT OVERRIDE MANTĞI: Fiyat artışı = Price Override
      double gonderilecekBirimFiyat;
      double hesaplananIskonto;

      if (yeniFiyat >= orjinalFiyat && orjinalFiyat > 0) {
        // Price increase = Price Override (update birimFiyat, iskonto=0)
        gonderilecekBirimFiyat = yeniFiyat;
        hesaplananIskonto = 0.0;
      } else {
        // Price decrease = Discount (keep birimFiyat, calculate iskonto)
        gonderilecekBirimFiyat = orjinalFiyat;
        hesaplananIskonto = (orjinalFiyat > 0)
            ? double.parse((((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100)).toStringAsFixed(2))
            : 0.0;
      }

      widget.provider.addOrUpdateItem(
        stokKodu: widget.product.stokKodu,
        urunAdi: widget.product.urunAdi,
        birimFiyat: gonderilecekBirimFiyat,
        urunBarcode: widget.product.barcode1,
        miktar: 0,
        iskonto: hesaplananIskonto,
        birimTipi: currentBirimType,
        vat: widget.product.vat,
        imsrc: widget.product.imsrc,
        adetFiyati: widget.product.adetFiyati,
        kutuFiyati: widget.product.kutuFiyati,
        selectedBirimKey: widget.selectedBirim?.key,
      );

      // Fiyatı formatla ve controller'ları güncelle
      // PostFrameCallback kullanarak güncellemeyi bir sonraki frame'e ertele
      final formattedValue = yeniFiyat.toStringAsFixed(2);
      final expectedDiscount = hesaplananIskonto > 0 ? hesaplananIskonto.toString() : '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.priceController.text != formattedValue) {
            widget.priceController.text = formattedValue;
          }

          if (widget.discountController.text != expectedDiscount) {
            widget.discountController.text = expectedDiscount;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final selectedType = widget.getBirimTipi() ?? 'Unit';

    // ✅ MİMARİ DEĞİŞİKLİK: Price ve Discount alanları SADECE kullanıcı tarafından yönetilir
    // Provider'dan otomatik güncelleme YAPILMAZ (race condition'ı önler)
    // Sadece quantity değiştiğinde veya başka bir ürün seçildiğinde güncelleme yapılır

    // NOT: Discount controller'ı da artık otomatik güncelleme yapmıyor
    // Kullanıcı fiyat/indirim girdikten sonra provider'a kaydediliyor
    // Provider tekrar notify ettiğinde bu değerler zaten doğru olduğu için değişmiyor


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.urunAdi,
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
                      Expanded(flex: 11, child: _buildDiscountTextField(context, selectedType)),
                      SizedBox(width: 2.w),
                      Flexible(flex: 10, child: _buildFreeItemControl(context, customer)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            _buildQuantityControl(context, selectedType),
          ],
        ),
        // ✅ Yeşil bilgi satırı (Suggestions'tan)
        FutureBuilder<String>(
          future: _getSuggestionInfo(customer?.kod),
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
    );
  }

  Widget _buildUnitSelector(BuildContext context) {
    // ⚠️ REMOVED OLD FALLBACK: All products now load birimler from database
    // If birimler is empty, show a placeholder instead of trying to build a dropdown
    if (widget.birimler.isEmpty) {
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

    // Use actual birimler from database
    if (widget.birimler.length == 1) {
      final birim = widget.birimler.first;
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

    return Container(
      height: 8.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<BirimModel>(
        value: widget.selectedBirim,
        isDense: true,
        underline: Container(),
        style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        items: widget.birimler.map((birim) {
          return DropdownMenuItem<BirimModel>(
            value: birim,
            child: Text(birim.displayName),
          );
        }).toList(),
        onChanged: (BirimModel? newBirim) {
          if (newBirim != null) {
            widget.onBirimChanged(newBirim);
            // ⚠️ Deprecated: onBirimTipiChanged artık kullanılmıyor (onBirimChanged yeterli)
            // Geriye uyumluluk için varsayılan değer gönder
            widget.onBirimTipiChanged(false);
          }
        },
      ),
    );
  }

  Widget _buildPriceTextField(BuildContext context, String selectedType) {
    return Container(
      height: 8.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.priceController,
        focusNode: widget.priceFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        enabled: widget.quantity > 0,
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
          // ✅ MİMARİ DEĞİŞİKLİK: Sadece discount controller'ı güncelle
          // Provider'a KAYDETME (onEditingComplete'te kaydedilecek)
          final yeniFiyat = double.tryParse(value.replaceAll(',', '.')) ?? 0;
          var orjinalFiyat = selectedType == 'Unit'
              ? (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
              : (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0);
          if (orjinalFiyat <= 0) orjinalFiyat = yeniFiyat;

          final indirimOrani = (orjinalFiyat > 0 && yeniFiyat < orjinalFiyat)
              ? double.parse((((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100)).toStringAsFixed(2))
              : 0.0;

          // Sadece discount controller'ı güncelle (local state)
          if (!widget.discountFocusNode.hasFocus) {
            widget.discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';
          }
        },
        onEditingComplete: () {
          widget.formatPriceField();
          // ✅ Provider'a KAYDETMartık burada kaydet (focus kaybında)
          final yeniFiyat = double.tryParse(widget.priceController.text.replaceAll(',', '.')) ?? 0;
          var orjinalFiyat = selectedType == 'Unit'
              ? (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
              : (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0);
          if (orjinalFiyat <= 0) orjinalFiyat = yeniFiyat;

          final indirimOrani = (orjinalFiyat > 0 && yeniFiyat < orjinalFiyat)
              ? double.parse((((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100)).toStringAsFixed(2))
              : 0.0;

          widget.provider.addOrUpdateItem(
            stokKodu: widget.product.stokKodu,
            urunAdi: widget.product.urunAdi,
            birimFiyat: orjinalFiyat,
            urunBarcode: widget.product.barcode1,
            miktar: 0,
            iskonto: indirimOrani,
            birimTipi: selectedType,
            vat: widget.product.vat,
            imsrc: widget.product.imsrc,
            adetFiyati: widget.product.adetFiyati,
            kutuFiyati: widget.product.kutuFiyati,
            selectedBirimKey: widget.selectedBirim?.key,
          );
          widget.priceFocusNode.unfocus();
        },
        onSubmitted: (value) {
          widget.formatPriceField();
          // ✅ Provider'a KAYDET (submit'te)
          final yeniFiyat = double.tryParse(value.replaceAll(',', '.')) ?? 0;
          var orjinalFiyat = selectedType == 'Unit'
              ? (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
              : (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0);
          if (orjinalFiyat <= 0) orjinalFiyat = yeniFiyat;

          final indirimOrani = (orjinalFiyat > 0 && yeniFiyat < orjinalFiyat)
              ? double.parse((((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100)).toStringAsFixed(2))
              : 0.0;

          widget.provider.addOrUpdateItem(
            stokKodu: widget.product.stokKodu,
            urunAdi: widget.product.urunAdi,
            birimFiyat: orjinalFiyat,
            urunBarcode: widget.product.barcode1,
            miktar: 0,
            iskonto: indirimOrani,
            birimTipi: selectedType,
            vat: widget.product.vat,
            imsrc: widget.product.imsrc,
            adetFiyati: widget.product.adetFiyati,
            kutuFiyati: widget.product.kutuFiyati,
            selectedBirimKey: widget.selectedBirim?.key,
          );
          widget.priceFocusNode.unfocus();
        },
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: widget.discountController,
            focusNode: widget.discountFocusNode,
            decoration: InputDecoration(
              prefixText: '%',
              prefixStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.error),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
            onChanged: (val) {
              // ✅ Her değişiklikte hem preview hem de provider'ı güncelle
              final cartKey = '${widget.product.stokKodu}_${selectedType == 'Unit' ? 'UNIT' : 'BOX'}';
              final cartItem = widget.provider.items[cartKey];

              // ✅ FIX: Mevcut birimFiyat'ı al (selectedBirim.fiyat7'den!)
              double currentPrice;
              if (cartItem != null) {
                // Sepette varsa sepetteki fiyatı kullan (price override olabilir)
                currentPrice = cartItem.birimFiyat;
              } else if (widget.selectedBirim != null) {
                // Sepette yoksa selectedBirim.fiyat7'den al
                currentPrice = widget.selectedBirim!.fiyat7 ?? 0;
              } else {
                // Yoksa fallback: eski mantık
                currentPrice = (selectedType.toUpperCase() == 'UNIT')
                    ? (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
                    : (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0);
              }

              if (val.isEmpty) {
                // İskonto kaldırıldı - SADECE eğer item sepette varsa provider'ı güncelle
                if (cartItem != null && cartItem.miktar > 0) {
                  widget.provider.addOrUpdateItem(
                    stokKodu: widget.product.stokKodu,
                    miktar: 0, // +0 = quantity doesn't change
                    iskonto: 0.0,
                    birimTipi: selectedType,
                    urunAdi: widget.product.urunAdi,
                    birimFiyat: currentPrice,
                    vat: widget.product.vat,
                    imsrc: widget.product.imsrc,
                    adetFiyati: widget.product.adetFiyati,
                    kutuFiyati: widget.product.kutuFiyati,
                    urunBarcode: widget.product.barcode1,
                    selectedBirimKey: widget.selectedBirim?.key,
                  );
                }

                // Price controller'ı orijinal fiyata döndür (preview için)
                if (!widget.priceFocusNode.hasFocus) {
                  final expectedPrice = currentPrice.toStringAsFixed(2);
                  if (widget.priceController.text != expectedPrice) {
                    widget.priceController.text = expectedPrice;
                  }
                }
                return;
              }

              double discountPercent = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
              discountPercent = discountPercent.clamp(0.0, 100.0);

              final discountedPrice = currentPrice * (1 - (discountPercent / 100));

              // SADECE eğer item sepette varsa provider'ı güncelle
              if (cartItem != null && cartItem.miktar > 0) {
                widget.provider.addOrUpdateItem(
                  stokKodu: widget.product.stokKodu,
                  miktar: 0, // +0 = quantity doesn't change
                  iskonto: discountPercent,
                  birimTipi: selectedType,
                  urunAdi: widget.product.urunAdi,
                  birimFiyat: currentPrice,
                  vat: widget.product.vat,
                  imsrc: widget.product.imsrc,
                  adetFiyati: widget.product.adetFiyati,
                  kutuFiyati: widget.product.kutuFiyati,
                  urunBarcode: widget.product.barcode1,
                  selectedBirimKey: widget.selectedBirim?.key,
                );
              }

              // Price controller'ı güncel fiyata güncelle (preview için)
              if (!widget.priceFocusNode.hasFocus) {
                final expectedPrice = discountedPrice.toStringAsFixed(2);
                if (widget.priceController.text != expectedPrice) {
                  widget.priceController.text = expectedPrice;
                }
              }
            },
            // ✅ FIX: Enter basıldığında sadece focus'u kapat (onChanged zaten provider'ı güncelledi)
            onSubmitted: (val) {
              widget.discountFocusNode.unfocus();
            },
            // ✅ Focus kaybında sadece unfocus yap (onChanged zaten provider'ı güncelledi)
            onEditingComplete: () {
              widget.discountFocusNode.unfocus();
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
    final count = widget.provider.items.values
        .where((item) => item.urunAdi == '${widget.product.urunAdi}_(FREE)' && item.birimTipi == type)
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
    String selectedBirimTipi = (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0) > 0 ? 'Box' : 'Unit';
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
                  if((double.tryParse(widget.product.adetFiyati.toString()) ?? 0) > 0) DropdownMenuItem(value: 'Unit', child: Text('cart.unit'.tr())),
                  if((double.tryParse(widget.product.kutuFiyati.toString()) ?? 0) > 0) DropdownMenuItem(value: 'Box', child: Text('cart.box'.tr())),
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

    widget.provider.customerName = customer!.kod!;
    final freeKey = "${widget.product.stokKodu}_(FREE)";

    widget.provider.addOrUpdateItem(
      stokKodu: freeKey,
      urunAdi: "${widget.product.urunAdi}_(FREE)",
      birimFiyat: 0,
      miktar: result['miktar'],
      urunBarcode: widget.product.barcode1,
      iskonto: 100,
      birimTipi: result['birimTipi'],
      imsrc: widget.product.imsrc,
      vat: widget.product.vat,
      adetFiyati: '0',
      kutuFiyati: '0',
      selectedBirimKey: null, // ✅ FREE item için birim yok
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
                      key: ValueKey('quantity_${widget.product.stokKodu}'),
                      controller: widget.quantityController,
                      focusNode: widget.quantityFocusNode,
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
                      onSubmitted: (value) => widget.updateQuantityFromTextField(value),
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
    final bool isEnabled = isIncrement || widget.quantity > 0;
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
            final newQuantity = widget.quantity + (isIncrement ? 1 : -1);

            // ✅ FIX: Mevcut sepet item'ındaki custom fiyatı koru!
            final cartKey = '${widget.product.stokKodu}_$selectedType';
            final existingCartItem = widget.provider.items[cartKey];

            // Eğer sepette bu birim için custom fiyat varsa onu kullan, yoksa orijinal fiyatı al
            final fiyat = existingCartItem?.birimFiyat ?? (
                widget.selectedBirim != null
                    ? (widget.selectedBirim!.fiyat7 ?? 0)
                    : (selectedType == 'Box' || selectedType == 'BOX')
                        ? (double.tryParse(widget.product.kutuFiyati.toString()) ?? 0)
                        : (double.tryParse(widget.product.adetFiyati.toString()) ?? 0)
            );

            print('➕ Increment/Decrement Button:');
            print('   selectedBirim: ${widget.selectedBirim?.birimadi} (fiyat7: ${widget.selectedBirim?.fiyat7})');
            print('   selectedType: $selectedType');
            print('   cartKey: $cartKey');
            print('   existingCartItem birimFiyat: ${existingCartItem?.birimFiyat}');
            print('   fiyat (preserved): $fiyat');

            final iskonto = existingCartItem?.iskonto ?? widget.provider.getIskonto(widget.product.stokKodu);

            widget.provider.addOrUpdateItem(
              urunAdi: widget.product.urunAdi,
              stokKodu: widget.product.stokKodu,
              birimFiyat: fiyat,
              adetFiyati: widget.product.adetFiyati,
              kutuFiyati: widget.product.kutuFiyati,
              vat: widget.product.vat,
              urunBarcode: widget.product.barcode1,
              miktar: isIncrement ? 1 : -1, // Decrement by 1
              iskonto: iskonto,
              birimTipi: selectedType,
              imsrc: widget.product.imsrc,
              selectedBirimKey: widget.selectedBirim?.key, // ✅ Seçili birimi kaydet
            );

            widget.onQuantityChanged(newQuantity);
            widget.quantityController.text = '$newQuantity';
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

  Color _getProductNameColor(BuildContext context) {
    final isPassive = widget.product.aktif == 0;
    if (isPassive) return Colors.red;
    return Theme.of(context).colorScheme.onSurface;
  }

  /// ✅ OPTIMIZE: Suggestions bilgisini cache-first yaklaşımla getirir
  /// İlk kez yüklendiğinde DB'den çeker ve cache'e ekler, sonra cache'den döner
  Future<String> _getSuggestionInfo(String? musteriId) async {
    if (musteriId == null || musteriId.isEmpty) return "";

    final stokKodu = widget.product.stokKodu;

    // ✅ Cache'de var mı kontrol et
    if (widget.suggestionsInfoMap.containsKey(stokKodu)) {
      return widget.suggestionsInfoMap[stokKodu]!;
    }

    // ✅ Cache'de yok - DB'den yükle
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.query(
        'Suggestions',
        where: 'MusteriId = ? AND StokKodu = ?',
        whereArgs: [musteriId, stokKodu],
        limit: 1,
      );

      if (result.isEmpty) {
        widget.suggestionsInfoMap[stokKodu] = ""; // Cache'e "yok" olarak kaydet
        return "";
      }

      final suggestion = result.first;
      final miktar = (suggestion['Miktar'] as num?)?.toDouble() ?? 0.0;
      final birimTipi = suggestion['BirimTipi'] as String? ?? 'Unit';
      final toplamTutar = (suggestion['ToplamTutar'] as num?)?.toDouble() ?? 0.0;
      final iskonto = (suggestion['Iskonto'] as num?)?.toInt() ?? 0;
      final sonSatisTarihi = suggestion['SonSatisTarihi'] as String?;

      if (sonSatisTarihi == null) {
        widget.suggestionsInfoMap[stokKodu] = "";
        return "";
      }

      // Tarihi parse et
      final tarih = DateTime.tryParse(sonSatisTarihi);
      if (tarih == null) {
        widget.suggestionsInfoMap[stokKodu] = "";
        return "";
      }

      final formattedDate = "${tarih.day.toString().padLeft(2, '0')}/${tarih.month.toString().padLeft(2, '0')}/${tarih.year}";
      final info = "[Qty:${miktar}x$birimTipi] [Total:${toplamTutar.toStringAsFixed(2)}] [Dsc:$iskonto%] [Date:$formattedDate]";

      // ✅ Cache'e kaydet
      widget.suggestionsInfoMap[stokKodu] = info;
      return info;
    } catch (e) {
      print('❌ Suggestions bilgisi alınamadı: $e');
      widget.suggestionsInfoMap[stokKodu] = ""; // Hata durumunda cache'e kaydet
      return "";
    }
  }
}


