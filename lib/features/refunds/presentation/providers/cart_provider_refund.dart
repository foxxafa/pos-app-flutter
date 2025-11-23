import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';


class RCartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Timer? _debounceTimer;

  Map<String, CartItem> get items => {..._items};

String _customerName = '';
set customerName(String value) {
  _customerName = value;
}

String get customerName => _customerName;

  double getIskonto(String stokKodu) {
    return _items[stokKodu]?.iskonto ?? 0.0;
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
    // ⚠️ FIX: items getter değil, _items kullan (getter kopya döndürür!)
    if (_items.containsKey(key)) {
      _items[key]!.miktar = newMiktar;
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
    double iskonto = 0.0,
    String birimTipi = 'Box',
    int durum = 1,
    int vat = 18,
    String adetFiyati = '', // yeni parametre
    String kutuFiyati = '', // yeni parametre
    String? selectedBirimKey, // ✅ Seçili birim key'i (String tipinde - BirimModel.key ile uyumlu)
  }) {
    print('📦 REFUND addOrUpdateItem:');
    print('   stokKodu: $stokKodu');
    print('   miktar param: $miktar');
    print('   birimTipi: $birimTipi');
    print('   birimFiyat: $birimFiyat');
    print('   selectedBirimKey: $selectedBirimKey');

    if (_items.containsKey(stokKodu)) {
      print('   ✅ Item EXISTS');
      final current = _items[stokKodu]!;
      print('   Current miktar BEFORE: ${current.miktar}');
      print('   Current birimTipi: ${current.birimTipi}');

      current.miktar += miktar;
      print('   Current miktar AFTER += $miktar: ${current.miktar}');

      if (current.miktar <= 0) {
        _items.remove(stokKodu);
        print('   ❌ Item REMOVED (miktar <= 0)');
      } else {
        current.birimFiyat = birimFiyat;
        current.iskonto = iskonto;
        current.birimTipi = birimTipi;
        current.vat = vat;
        current.imsrc = imsrc;
        current.durum = durum;
        current.adetFiyati = adetFiyati;
        current.kutuFiyati = kutuFiyati;
        current.selectedBirimKey = selectedBirimKey; // ✅ Update selectedBirimKey
        print('   ✅ Item UPDATED');
      }
    } else {
      // Don't create new item if quantity is 0 or negative
      if (miktar <= 0) {
        print('   ⚠️ NOT creating item (miktar <= 0)');
        return;
      }

      print('   🆕 Creating NEW item with miktar: $miktar');
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
        selectedBirimKey: selectedBirimKey, // ✅ Set selectedBirimKey for new item
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
    _debounceTimer?.cancel(); // Cancel any pending save
    await _saveCartToDatabase(); // Save immediately when clearing
    notifyListeners();
  }

  @override
void notifyListeners() {
  // ✅ Debounce: 300ms içinde birden fazla çağrı varsa son çağrıyı kullan
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    _saveCartToDatabase();
  });
  super.notifyListeners();
}

@override
void dispose() {
  _debounceTimer?.cancel();
  super.dispose();
}

Future<void> _saveCartToDatabase() async {
  print('💾 _saveCartToDatabase: Saving ${_items.length} items for customer: $_customerName');
  final dbHelper = DatabaseHelper();
  await dbHelper.clearRefundCartItemsByCustomer(_customerName); // önce temizle
  for (final item in _items.values) {
    await dbHelper.insertRefundCartItem(item, _customerName);
  }
  print('✅ Database save completed');
}

Future<void> loadCartRefundFromDatabase(String customerName) async {
  print('📂 loadCartRefundFromDatabase: Loading cart for customer: $customerName');
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
      selectedBirimKey: item['selectedBirimKey'], // ✅ Load selectedBirimKey from DB
    );

    _items[cartItem.stokKodu] = cartItem;
  }

  print('✅ Loaded ${_items.length} items from database');
 // notifyListeners(); - Don't notify here to avoid save loop
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
