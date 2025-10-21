import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/features/cart/domain/repositories/cart_repository.dart';

class CartItem {
  final String stokKodu;
  final String urunAdi;
  int miktar;
  double birimFiyat;

  int vat;
  String birimTipi;
  int durum;
  String urunBarcode;
  int iskonto;
  String? imsrc;

  String adetFiyati; // yeni alan
  String kutuFiyati; // yeni alan
  String aciklama = "";
  int birimKey1; // yeni alan
  int birimKey2; // yeni alan

  CartItem({
    required this.stokKodu,
    required this.urunAdi,
    this.miktar = 1,
    required this.birimFiyat,
    required this.vat,
    this.birimTipi = 'Unit',
    this.durum = 1,
    required this.urunBarcode,
    this.iskonto = 0,
    this.imsrc,
    this.adetFiyati = '',
    this.kutuFiyati = '',
    this.aciklama = '',
    this.birimKey1 = 0,
    this.birimKey2 = 0,
  });

  double get fiyat => birimFiyat * miktar;

  double get indirimliTutar {
    final araToplam = birimFiyat * miktar;
    final indirimMiktari = araToplam * iskonto / 100;
    final indirimliAraToplam = araToplam - indirimMiktari;
    final kdvliTutar = indirimliAraToplam * (1 + vat / 100);
    return kdvliTutar;
  }
}

extension CartItemVatExtension on CartItem {
  double get vatTutari {
    final araToplam = birimFiyat * miktar;
    final indirimliAraToplam = araToplam - (araToplam * iskonto / 100);
    return indirimliAraToplam * (vat / 100);
  }
}

extension CartItemExtension on CartItem {
  Map<String, dynamic> toJson() {
    return {
      "StokKodu": stokKodu,
      "UrunAdi": urunAdi,
      "Miktar": miktar,
      "BirimFiyat": birimFiyat,
      "ToplamTutar": fiyat,
      "vat": vat,
      "BirimTipi": birimTipi,
      "Durum": durum,
      "UrunBarcode": urunBarcode,
      "Iskonto": iskonto,
      "Imsrc": imsrc,
      "AdetFiyati": adetFiyati,
      "KutuFiyati": kutuFiyati,
      "Aciklama": aciklama,
      "BirimKey1": birimKey1,
      "BirimKey2": birimKey2,
    };
  }
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final CartRepository? _cartRepository;

  CartProvider({CartRepository? cartRepository}) : _cartRepository = cartRepository;

  Map<String, CartItem> get items => {..._items};

  // ✅ Debounce timer to prevent multiple rapid database saves
  Timer? _debounceTimer;
  bool _hasPendingSave = false;
  bool _isSavingToDatabase = false; // Prevent concurrent saves

  String _customerName = '';
  set customerName(String value) {
    _customerName = value;
  }

  String get customerName => _customerName;

  String _customerKod = '';
  set customerKod(String value) {
    _customerKod = value;
  }

  String get customerKod => _customerKod;

  String _fisNo = '';
  set fisNo(String value) {
    _fisNo = value;
  }

  String get fisNo => _fisNo;

  int getIskonto(String stokKodu, [String? birimTipi]) {
    if (birimTipi != null) {
      final cartKey = '${stokKodu}_$birimTipi';
      return _items[cartKey]?.iskonto ?? 0;
    }
    // Backward compatibility: eski key ile dene
    return _items[stokKodu]?.iskonto ?? 0;
  }

  String getBirimTipi(String stokKodu, [String? birimTipi]) {
    if (birimTipi != null) {
      final cartKey = '${stokKodu}_$birimTipi';
      return _items[cartKey]?.birimTipi ?? birimTipi;
    }
    // Backward compatibility: eski key ile dene
    return _items[stokKodu]?.birimTipi ?? 'Box';
  }

  double getBirimFiyat(String stokKodu, [String? birimTipi]) {
    if (birimTipi != null) {
      final cartKey = '${stokKodu}_$birimTipi';
      return _items[cartKey]?.birimFiyat ?? 0.0;
    }
    // Backward compatibility: eski key ile dene
    return _items[stokKodu]?.birimFiyat ?? 0.0;
  }

  int getmiktar(String stokKodu, [String? birimTipi]) {
    if (birimTipi != null) {
      final cartKey = '${stokKodu}_$birimTipi';
      return _items[cartKey]?.miktar ?? 0;
    }
    // Backward compatibility: eski key ile dene
    return _items[stokKodu]?.miktar ?? 0;
  }

  void updateMiktar(String key, int newMiktar) {
    if (items.containsKey(key)) {
      items[key]!.miktar = newMiktar;
      notifyListeners();
    }
  }

  double get toplamKdvTutari {
    double toplam = 0;
    _items.forEach((_, item) {
      toplam += item.vatTutari;
    });
    return toplam;
  }

  void updateAciklama(String stokKodu, String yeniAciklama) {
    if (_items.containsKey(stokKodu)) {
      _items[stokKodu]!.aciklama = yeniAciklama;
      notifyListeners();
    }
  }

  void addOrUpdateItem({
    required String stokKodu,
    required String urunAdi,
    required double birimFiyat,
    required String urunBarcode,
    String? imsrc,
    int miktar = 1,
    int iskonto = 0,
    String birimTipi = 'Box',
    int durum = 1,
    int vat = 18,
    String adetFiyati = '',
    String kutuFiyati = '',
    int birimKey1 = 0,
    int birimKey2 = 0,
  }) {
    // ⚠️ KRITIK: fisNo set edilmemişse UYARI (OrderInfoProvider tarafından set edilmelidir)
    if (_fisNo.isEmpty || _fisNo == '') {
      print("⚠️ CRITICAL: addOrUpdateItem called but fisNo is empty!");
      print("⚠️ Please ensure cartProvider.fisNo is set from OrderInfoProvider BEFORE calling addOrUpdateItem!");
      print("⚠️ Stack trace: ${StackTrace.current}");
    }

    // ⚠️ KRITIK: customerKod set edilmemişse UYARI
    if (_customerKod.isEmpty && _customerName.isNotEmpty) {
      print("⚠️ CRITICAL: addOrUpdateItem called but customerKod is empty! customerName='$_customerName'");
      print("⚠️ Please ensure cartProvider.customerKod is set BEFORE calling addOrUpdateItem!");
      print("⚠️ Stack trace: ${StackTrace.current}");
    }

    // Sepet anahtarı: stokKodu + birimTipi (aynı ürünün farklı birimleri ayrı item olacak)
    final cartKey = '${stokKodu}_$birimTipi';

    if (_items.containsKey(cartKey)) {
      print("cartKey $cartKey");
      final current = _items[cartKey]!;
      current.miktar += miktar;
      if (current.miktar <= 0) {
        _items.remove(cartKey);
      } else {
        current.birimFiyat = birimFiyat;
        current.iskonto = iskonto;
        current.birimTipi = birimTipi;
        current.vat = vat;
        current.imsrc = imsrc;
        current.durum = durum;
        current.adetFiyati = adetFiyati;
        current.kutuFiyati = kutuFiyati;
        current.birimKey1 = birimKey1;
        current.birimKey2 = birimKey2;
      }
    } else {
      _items[cartKey] = CartItem(
        stokKodu: stokKodu,
        urunAdi: urunAdi,
        birimFiyat: birimFiyat,
        miktar: miktar,
        urunBarcode: urunBarcode,
        iskonto: iskonto,
        birimTipi: birimTipi,
        durum: durum,
        imsrc: imsrc,
        vat: vat,
        adetFiyati: adetFiyati,
        kutuFiyati: kutuFiyati,
        birimKey1: birimKey1,
        birimKey2: birimKey2,
      );
    }

    notifyListeners();
  }

  void removeItem(String stokKodu, [String? birimTipi]) {
    if (birimTipi != null) {
      // Yeni format: stokKodu_birimTipi
      final cartKey = '${stokKodu}_$birimTipi';
      _items.remove(cartKey);
    } else {
      // Eski format desteği veya tüm birim tiplerini sil
      final keysToRemove = <String>[];
      for (final key in _items.keys) {
        if (key == stokKodu || key.startsWith('${stokKodu}_')) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        _items.remove(key);
      }
    }
    notifyListeners();
  }

  Future<void> clearCart() async {
    print("DEBUG: CartProvider.clearCart() called - items before clear: ${_items.length}");
    _items.clear();
    print("DEBUG: CartProvider items cleared - current count: ${_items.length}");

    // ✅ Database kaydetme başarısız olsa bile devam et
    try {
      await _saveCartToDatabase();
      print("DEBUG: CartProvider _saveCartToDatabase() completed successfully");
    } catch (e) {
      print("ERROR: CartProvider _saveCartToDatabase() failed: $e");
      // Hata olsa bile devam et - memory'den zaten temizlendi
    }

    notifyListeners();
    print("DEBUG: CartProvider notifyListeners() completed");
  }

  /// Sadece memory'den temizle, database kayıtlarını koru
  void clearCartMemoryOnly() {
    print("DEBUG: CartProvider.clearCartMemoryOnly() called - items before clear: ${_items.length}");
    _items.clear();
    print("DEBUG: CartProvider memory cleared - database kept intact");

    // ✅ KRITIK: debounce timer'ı iptal et - database'e kaydetme!
    // Çünkü bellekten temizliyoruz ama database'de kalması gerekiyor (isPlaced=1 kayıtları)
    _debounceTimer?.cancel();
    _hasPendingSave = false;

    // notifyListeners() ÇAĞIRMA - çünkü database'e kaydetmek istemiyoruz
    // Sadece UI'ı güncelle
    super.notifyListeners();
  }

  @override
  void notifyListeners() {
    // ✅ Debounce database saves to prevent multiple rapid writes
    // Increased from 300ms to 800ms to reduce frequency when user rapidly clicks +/-
    _hasPendingSave = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 800), () {
      if (_hasPendingSave && !_isSavingToDatabase) {
        _hasPendingSave = false;
        _saveCartToDatabase().catchError((error) {
          print("Error saving cart to database: $error");
        });
      }
    });

    super.notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveCartToDatabase() async {
    // ✅ Prevent concurrent database saves
    if (_isSavingToDatabase) {
      print("DEBUG _saveCartToDatabase: Already saving, skipping this call");
      return;
    }

    // ✅ If cart is empty, don't clear database - just skip save
    // This preserves placed orders (isPlaced=1) and Saved Carts
    if (_items.isEmpty) {
      print("DEBUG _saveCartToDatabase: Skipping save - cart is empty (preserving placed orders and Saved Carts)");
      return;
    }

    _isSavingToDatabase = true;

    try {
      // Use actual customer kod and fisNo
      String actualCustomerKod = _customerKod.isEmpty ? '' : _customerKod;
      String actualCustomerName = _customerName.isEmpty ? 'Unknown Customer' : _customerName;
      String actualFisNo = _fisNo.isEmpty ? '' : _fisNo;

      // ⚠️ WARNING: If customerKod is empty but customerName has a code-like value, it means
      // the calling code forgot to set customerKod. Let's fix it here temporarily.
      if (actualCustomerKod.isEmpty && actualCustomerName.isNotEmpty && !actualCustomerName.contains('Unknown')) {
        // Check if customerName looks like a code (short, no spaces, no special chars except dash)
        if (actualCustomerName.length < 20 && !actualCustomerName.contains(' ') && !actualCustomerName.contains('(')) {
          print("⚠️ WARNING: customerKod is empty but customerName='$actualCustomerName' looks like a code. Using it as customerKod.");
          actualCustomerKod = actualCustomerName;
        }
      }

      // Debug: Print what we're saving
      print("DEBUG _saveCartToDatabase: customerKod = '$actualCustomerKod', customerName = '$actualCustomerName', fisNo = '$actualFisNo', items count = ${_items.length}");

      // Use repository if available, otherwise fall back to DatabaseHelper
      if (_cartRepository != null) {
        // Clear existing items for this order (fisNo + customer)
        await _cartRepository.clearCartByCustomer(actualCustomerName);
        print("DEBUG _saveCartToDatabase: clearCartByCustomer completed for '$actualCustomerName'");

        // Insert all current cart items with fisNo and customerKod
        for (final item in _items.values) {
          await _cartRepository.insertCartItemForCustomer({
            'fisNo': actualFisNo,
            'customerKod': actualCustomerKod,
            'stokKodu': item.stokKodu,
            'urunAdi': item.urunAdi,
            'birimFiyat': item.birimFiyat,
            'miktar': item.miktar,
            'urunBarcode': item.urunBarcode,
            'iskonto': item.iskonto,
            'birimTipi': item.birimTipi,
            'durum': item.durum,
            'imsrc': item.imsrc,
            'vat': item.vat,
            'adetFiyati': item.adetFiyati,
            'kutuFiyati': item.kutuFiyati,
          }, actualCustomerName);
        }
        print("DEBUG _saveCartToDatabase: ${_items.length} items inserted for customerKod='$actualCustomerKod' (FisNo: $actualFisNo)");
      } else {
        // Fallback to DatabaseHelper for backward compatibility
        print("DEBUG _saveCartToDatabase (DatabaseHelper fallback): customerKod = '$actualCustomerKod', fisNo = '$actualFisNo', items count = ${_items.length}");

        final dbHelper = DatabaseHelper();

        // Clear existing items for this customer (using customerName for backward compatibility)
        await dbHelper.clearCartItemsByCustomer(actualCustomerName);

        // Insert with fisNo and customerKod
        final db = await dbHelper.database;
        for (final item in _items.values) {
          await db.insert('cart_items', {
            'fisNo': actualFisNo,
            'customerKod': actualCustomerKod,
            'customerName': actualCustomerName, // Keep for backward compatibility
            'stokKodu': item.stokKodu,
            'urunAdi': item.urunAdi,
            'birimFiyat': item.birimFiyat,
            'miktar': item.miktar,
            'urunBarcode': item.urunBarcode,
            'iskonto': item.iskonto,
            'birimTipi': item.birimTipi,
            'durum': item.durum,
            'imsrc': item.imsrc,
            'vat': item.vat,
            'adetFiyati': item.adetFiyati,
            'kutuFiyati': item.kutuFiyati,
          });
        }
      }
    } finally {
      // ✅ Always reset the flag, even if an error occurred
      _isSavingToDatabase = false;
    }
  }

  /// Force immediate save to database, bypassing debounce timer
  /// Use this when you need to ensure data is saved immediately (e.g., after Load Order)
  Future<void> forceSaveToDatabase() async {
    print("DEBUG forceSaveToDatabase: Canceling debounce timer and forcing immediate save");

    // Cancel any pending debounced save
    _debounceTimer?.cancel();
    _hasPendingSave = false;

    // Force immediate save
    await _saveCartToDatabase();
  }

  Future<void> loadCartFromDatabase(String customerName) async {
    print("DEBUG loadCartFromDatabase: Loading cart for customer '$customerName'");

    List<Map<String, dynamic>> cartData;

    // Use repository if available, otherwise fall back to DatabaseHelper
    if (_cartRepository != null) {
      try {
        cartData = await _cartRepository.getCartItemsByCustomer(customerName);
        print("DEBUG loadCartFromDatabase (Repository): Found ${cartData.length} items for '$customerName'");
      } catch (e) {
        print("ERROR loadCartFromDatabase (Repository): $e");
        cartData = [];
      }
    } else {
      // Fallback to DatabaseHelper
      final dbHelper = DatabaseHelper();
      cartData = await dbHelper.getCartItemsByCustomer(customerName);
      print("DEBUG loadCartFromDatabase (DatabaseHelper): Found ${cartData.length} items for '$customerName'");
    }

    _items.clear();

    // ⚠️ DO NOT override customerName here! It should be set by SalesCustomerProvider.setCustomer()
    // The parameter 'customerName' is only used for database query (backward compatibility)
    // _customerName = customerName;  // ❌ REMOVED - causes customerName to be overwritten with CODE

    // ✅ If cart data found, load fisNo and customerKod from first item
    if (cartData.isNotEmpty) {
      final firstItem = cartData.first;
      final loadedFisNo = firstItem['fisNo']?.toString() ?? '';
      final loadedCustomerKod = firstItem['customerKod']?.toString() ?? '';

      if (loadedFisNo.isNotEmpty) {
        _fisNo = loadedFisNo;
        print("DEBUG loadCartFromDatabase: Loaded existing fisNo: $_fisNo");
      }

      if (loadedCustomerKod.isNotEmpty) {
        _customerKod = loadedCustomerKod;
        print("DEBUG loadCartFromDatabase: Loaded existing customerKod: $_customerKod");
      }
    }

    for (final item in cartData) {
      final cartItem = CartItem(
        stokKodu: item['stokKodu'],
        urunAdi: item['urunAdi'],
        birimFiyat: item['birimFiyat'],
        miktar: item['miktar'],
        urunBarcode: item['urunBarcode'],
        iskonto: item['iskonto'],
        birimTipi: item['birimTipi'],
        durum: item['durum'],
        imsrc: item['imsrc'],
        vat: item['vat'],
        adetFiyati: item['adetFiyati'],
        kutuFiyati: item['kutuFiyati'],
      );

      final cartKey = '${cartItem.stokKodu}_${cartItem.birimTipi}';
      _items[cartKey] = cartItem;
    }
    print("DEBUG loadCartFromDatabase: Loaded ${_items.length} items into provider for '$customerName'");

    // ✅ Notify listeners so UI updates with loaded cart
    notifyListeners();
  }

  /// Load cart by fisNo (order number) - for resuming incomplete orders
  Future<void> loadCartByFisNo(String fisNo) async {
    print("DEBUG loadCartByFisNo: Loading cart for fisNo '$fisNo'");

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // ✅ Load all items with this fisNo (only if not placed yet)
    final cartData = await db.query(
      'cart_items',
      where: 'fisNo = ? AND (isPlaced IS NULL OR isPlaced = ?)',
      whereArgs: [fisNo, 0],
    );

    print("DEBUG loadCartByFisNo: Found ${cartData.length} items for fisNo '$fisNo'");

    if (cartData.isEmpty) {
      print("WARNING: No items found for fisNo '$fisNo' or order already placed");
      return;
    }

    _items.clear();

    // ✅ Load fisNo, customerKod, and customerName from the first item
    final firstItem = cartData.first;
    _fisNo = firstItem['fisNo']?.toString() ?? '';
    _customerKod = firstItem['customerKod']?.toString() ?? '';
    _customerName = firstItem['customerName']?.toString() ?? '';

    print("DEBUG loadCartByFisNo: Loaded order info - fisNo: '$_fisNo', customerKod: '$_customerKod', customerName: '$_customerName'");

    // Load all items into cart
    for (final item in cartData) {
      final cartItem = CartItem(
        stokKodu: item['stokKodu']?.toString() ?? '',
        urunAdi: item['urunAdi']?.toString() ?? '',
        birimFiyat: (item['birimFiyat'] is num)
            ? (item['birimFiyat'] as num).toDouble()
            : double.tryParse(item['birimFiyat']?.toString() ?? '0') ?? 0.0,
        miktar: (item['miktar'] is num)
            ? (item['miktar'] as num).toInt()
            : int.tryParse(item['miktar']?.toString() ?? '0') ?? 0,
        urunBarcode: item['urunBarcode']?.toString() ?? '',
        iskonto: (item['iskonto'] is num)
            ? (item['iskonto'] as num).toInt()
            : int.tryParse(item['iskonto']?.toString() ?? '0') ?? 0,
        birimTipi: item['birimTipi']?.toString() ?? 'Box',
        durum: (item['durum'] is num)
            ? (item['durum'] as num).toInt()
            : int.tryParse(item['durum']?.toString() ?? '1') ?? 1,
        imsrc: item['imsrc']?.toString(),
        vat: (item['vat'] is num)
            ? (item['vat'] as num).toInt()
            : int.tryParse(item['vat']?.toString() ?? '0') ?? 0,
        adetFiyati: item['adetFiyati']?.toString() ?? '',
        kutuFiyati: item['kutuFiyati']?.toString() ?? '',
      );

      final cartKey = '${cartItem.stokKodu}_${cartItem.birimTipi}';
      _items[cartKey] = cartItem;
    }

    print("DEBUG loadCartByFisNo: Loaded ${_items.length} items into provider");
    notifyListeners();
  }

  double get toplamTutar {
    double toplam = 0;
    _items.forEach((key, item) {
      toplam += item.indirimliTutar;
    });
    return toplam;
  }

  double get indirimsizToplamTutar {
    double toplam = 0;
    _items.forEach((key, item) {
      toplam += item.birimFiyat * item.miktar;
    });
    return toplam;
  }

double get toplamIndirimTutari {
  double toplam = 0;

  for (final item in _items.values) {

    // Orijinal birim fiyat (KDV'siz)
    final orjinalNetFiyat = item.birimFiyat;

    // İndirimli birim fiyat (KDV'siz)
    final indirimliNetFiyat = orjinalNetFiyat * (1 - item.iskonto / 100);

    // Fark * miktar = toplam indirim (KDV'siz)
    final indirimTutari = (orjinalNetFiyat - indirimliNetFiyat) * item.miktar;

    toplam += indirimTutari;
  }

  return toplam;
}



  int get toplamMiktar {
    int toplam = 0;
    _items.forEach((key, item) {
      toplam += item.miktar;
    });
    return toplam;
  }
}

extension CartItemFormatter on CartItem {
  String toFormattedString() {
    return '''
Stok Kodu   : $stokKodu
Ürün Adı    : $urunAdi
Miktar      : $miktar
Birim Fiyat : $birimFiyat
Adet Fiyat  : $adetFiyati
Kutu Fiyat  : $kutuFiyati
Birim Tipi  : $birimTipi
Barkod      : $urunBarcode
İskonto     : $iskonto
Aciklama    : $aciklama
''';
  }
}
