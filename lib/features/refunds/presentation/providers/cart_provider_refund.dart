import 'package:flutter/material.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';


class RCartProvider extends ChangeNotifier {
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
    return _items[stokKodu]?.birimTipi ?? 'Unit';
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
    String adetFiyati = '', // yeni parametre
    String kutuFiyati = '', // yeni parametre
  }) {
    if (_items.containsKey(stokKodu)) {
      print("stokkou $stokKodu");
      final current = _items[stokKodu]!;
      current.miktar += miktar;
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
      // Don't create new item if quantity is 0 or negative
      if (miktar <= 0) {
        return;
      }

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
    _items.remove(stokKodu);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCartToDatabase();
    notifyListeners();
  }

  @override
void notifyListeners() {
  _saveCartToDatabase(); // buradan çağır
  super.notifyListeners();
}

Future<void> _saveCartToDatabase() async {
  final dbHelper = DatabaseHelper();
  await dbHelper.clearRefundCartItemsByCustomer(_customerName); // önce temizle
  for (final item in _items.values) {
    await dbHelper.insertRefundCartItem(item, _customerName);
    print("a1a2a3");
    dbHelper.printAllCartItems(); print("a1a2a3");
  }
}

Future<void> loadCartRefundFromDatabase(String customerName) async {
  final dbHelper = DatabaseHelper();
  final cartData = await dbHelper.getRefundCartItemsByCustomer(customerName);

  _items.clear(); // önce temizle
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

      print("a1a2a3");
    dbHelper.printAllCartItems(); print("a1a2a3");

 // notifyListeners();
}

  double get toplamTutar {
    double toplam = 0;
    _items.forEach((key, item) {
      toplam += item.indirimliTutar;
    });
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
