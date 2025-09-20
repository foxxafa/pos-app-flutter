import 'package:flutter/material.dart';
import 'package:pos_app/controllers/cartdatabase_helper.dart';

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
    this.aciklama = ''
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
    };
  }
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  String _customerName = '';
  set customerName(String value) {
    _customerName = value;
  }

  String get customerName => _customerName;

  int getIskonto(String stokKodu) {
    return _items[stokKodu]?.iskonto ?? 0;
  }

  String getBirimTipi(String stokKodu) {
    return _items[stokKodu]?.birimTipi ?? 'Box';
  }

  double getBirimFiyat(String stokKodu) {
    return _items[stokKodu]?.birimFiyat ?? 0.0;
  }

  int getmiktar(String stokKodu) {
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
  }) {
    print("DEBUG CartProvider: addOrUpdateItem stokKodu=$stokKodu, miktar=$miktar");
    if (_items.containsKey(stokKodu)) {
      print("DEBUG CartProvider: item exists, current miktar=${_items[stokKodu]!.miktar}");
      final current = _items[stokKodu]!;
      current.miktar += miktar;
      print("DEBUG CartProvider: after addition, new miktar=${current.miktar}");
      if (current.miktar <= 0) {
        _items.remove(stokKodu);
      } else {
        current.birimFiyat = birimFiyat;
        current.iskonto = iskonto;
        current.birimTipi = birimTipi;
        current.vat = vat;
        current.imsrc = imsrc;
        current.durum = durum;
        current.adetFiyati = adetFiyati;
        current.kutuFiyati = kutuFiyati;
      }
    } else {
      _items[stokKodu] = CartItem(
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
      );
    }

    notifyListeners();
  }

  void removeItem(String stokKodu) {
    print("DEBUG CartProvider: removeItem stokKodu=$stokKodu");
    final removed = _items.remove(stokKodu);
    print("DEBUG CartProvider: removed item: ${removed != null}");
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    _saveCartToDatabase();
    super.notifyListeners();
  }

  void _saveCartToDatabase() async {
    // Use actual customer name instead of empty string
    String actualCustomerName = _customerName.isEmpty ? 'Unknown Customer' : _customerName;

    // Debug: Print what we're saving
    print("DEBUG CartProvider saving: customerName = '$actualCustomerName'");

    final dbHelper = CartDatabaseHelper();
    await dbHelper.clearCartItemsByCustomer(actualCustomerName);
    for (final item in _items.values) {
      await dbHelper.insertCartItem(item, actualCustomerName);
    }
  }

  Future<void> loadCartFromDatabase(String customerName) async {
    final dbHelper = CartDatabaseHelper();
    final cartData = await dbHelper.getCartItemsByCustomer(customerName);

    _items.clear();
    _customerName = customerName;

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

      _items[cartItem.stokKodu] = cartItem;
    }

    // notifyListeners(); // isteğe bağlı
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
