import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pos_app/controllers/customer_controller.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/controllers/order_controller.dart';
import 'package:pos_app/controllers/product_controller.dart';
import 'package:pos_app/controllers/refundlist_controller.dart';
import 'package:pos_app/controllers/refundsend_controller.dart';
import 'package:pos_app/models/order_model.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SyncController {
  final balancecontroller = CustomerBalanceController();

  // CLEAN SYNC
  // CLEAN SYNC
  cleanSync() async {
    balancecontroller.fetchAndStoreCustomers();
    print("0");
    syncPendingRefunds();
    print("1");
    //open database
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');

    print("2");
    Database db = await openDatabase(path, version: 1);
      await db.delete('Customer');

    print("3");
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='updateDates';",
    );
    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE updateDates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          update_time TEXT NOT NULL
        )
      ''');
    }

    //eskiyi silme işlemi
    await db.transaction((txn) async {
      // Önce tablo var mı kontrol et
      var result = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='Customer';",
      );

      if (result.isNotEmpty) {
        // Tablo varsa sil
        await txn.delete('Customer');
        print('Customer tablosu bulundu ve silindi.');
      } else {
        print('Customer tablosu bulunamadı, silme işlemi yapılmadı.');
      }
    });
    print("4");
    //eskiyi silme işlemi
    await db.transaction((txn) async {
      // Önce tablo var mı kontrol et
      var result = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='Product';",
      );

      if (result.isNotEmpty) {
        // Tablo varsa sil
        await txn.delete('Product');
        print('Product tablosu bulundu ve silindi.');
      } else {
        print('Product tablosu bulunamadı, silme işlemi yapılmadı.');
      }
    });

    print("5");
    //sync işlemleri
    await SyncProducts(DateTime(2024, 5, 1, 15, 55, 30));
    print("6");
    //await SyncCustomers(DateTime.now());

    await SyncCustomers(DateTime(2024, 5, 1, 15, 55, 30));

    print("7");
    //update sonu son update saati güncelleme
    String nowString = DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now());
    await db.insert('updateDates', {'update_time': nowString});
    print("DB CLOSE TIME 4");
    await db.close();
  }

  //UPDATE SYNC
  //UPDATE SYNC
  updateSync() async {
    balancecontroller.fetchAndStoreCustomers();
    syncPendingRefunds();
    //update sonu son update saati güncelleme
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');
    Database db = await openDatabase(path, version: 1);

    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='updateDates';",
    );
    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE updateDates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          update_time TEXT NOT NULL
        )
      ''');
    }

    DateTime? lastUpdate = await getLastUpdateTime(db);
    print("last update $lastUpdate");
    //daha önce update edildi ve bu tarih kaydedildiyse
    if (lastUpdate != null) {
      await SyncProducts(lastUpdate);
      await SyncCustomers(lastUpdate);

      //son update zamanı güncelleme
      String nowString = DateFormat(
        'dd.MM.yyyy HH:mm:ss',
      ).format(DateTime.now());
      await db.insert('updateDates', {'update_time': nowString});
    } else {
      print('Son güncelleme zamanı yok, updateSync() çalıştırılmadı.');
    }

    print("DB CLOSE TIME 5");
    await db.close();
  }

  //SYNC CUSTOMERS
  //SYNC CUSTOMERS
  //SYNC CUSTOMERS
  Future<void> SyncCustomers(DateTime lastupdatedate) async {
    final controller = CustomerController();
    //TODO keyi içerden alsın statik değil

    final customers = await controller.getNewCustomer(lastupdatedate);
    //print("all customers/()(() $customers");
    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');

    Database db = await openDatabase(path, version: 1);

    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='Customer';",
    );
    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE Customer (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          VergiNo TEXT,
          VergiDairesi TEXT,
          Adres TEXT,
          Telefon TEXT,
          Email TEXT,
          Kod TEXT,
          Unvan TEXT,
          PostCode TEXT,
          Aktif INTEGER NOT NULL
        )
      ''');
    } else {
      // Tablo varsa sadece verileri temizle
      // await db.delete('Customer');
    }

    if (customers != null) {
      await db.transaction((txn) async {
        // Eğer eski kayıtları temizlemek istersen açabilirsin
        // await txn.delete('Customer');

        for (var customer in customers) {
          await txn.insert('Customer', customer.toMap());
        }
      });

      List<Map> list = await db.query('Customer');

      print('-!_!_!_!_!_!_Customers in database: ${list.length} $list ');
    }
  }

  Future<void> SyncAllRefunds() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pos_database.db');
    final db = await openDatabase(path, version: 1);

    // 1. API'den sadece refund yapılabilecek carikod'ları al
    final apiResponse = await http.get(
      Uri.parse('https://test.rowhub.net/index.php?r=apimobil/iademusterileri'),
    );

    if (apiResponse.statusCode != 200) {
      print('⛔ API çağrısı başarısız: ${apiResponse.statusCode}');
      return;
    }

    final List<dynamic> allowedList = jsonDecode(apiResponse.body);
    final Set<String> allowedCariKodlar =
        allowedList
            .map((e) => e['MusteriId'].toString().trim()) // boşlukları temizle
            .toSet();

    // 2. Veritabanındaki tüm Customer kayıtlarını al
    final customers = await db.query('Customer');

    // 3. Sadece API'den gelen carikod'lara sahip olanları filtrele
    final filteredCustomers =
        customers.where((customer) {
          final cariKod = customer['Kod']?.toString().trim();
          return allowedCariKodlar.contains(cariKod);
        }).toList();

    print('✓ Senkronize edilecek müşteri sayısı: ${filteredCustomers.length}');

    // 4. Her uygun müşteri için refund senkronizasyonu yap
    for (final customer in filteredCustomers) {
      final cariKod = customer['Kod'].toString().trim();
      final musteriId = customer['id'].toString();

      print("🔄 Senkronize ediliyor: $cariKod");

      try {
        final refunds = await RefundListController().fetchRefunds(cariKod);

        // Önce sadece bu müşteriye ait eski refund kayıtlarını sil
        await db.delete(
          'Refunds',
          where: 'musteriId = ?',
          whereArgs: [musteriId],
        );

        // Yeni refund verilerini ekle
        for (final refund in refunds) {
          print("id");
          print(refund.musteriId);
          await db.insert('Refunds', {
            'fisNo': refund.fisNo,
            'musteriId': refund.musteriId,
            'fisTarihi': refund.fisTarihi.toIso8601String(),
            'unvan': refund.unvan,
            'stokKodu': refund.stokKodu,
            'urunAdi': refund.urunAdi,
            'urunBarcode': refund.urunBarcode,
            'miktar': refund.miktar,
            'birim': refund.birim,
            'birimFiyat': refund.birimFiyat,
          });
        }

        print('✅ ${refunds.length} refund senkronize edildi: $cariKod');
      } catch (e) {
        print('⛔ $cariKod refund senkronizasyonu başarısız: $e');
      }
    }
  }

  Future<void> syncPendingRefunds() async {
    await RefundSendController().sendPendingRefunds();
  }

  //SYNC PRODUCTS
  //SYNC PRODUCTS
  //SYNC PRODUCTS
  Future<void> SyncProducts(DateTime lastUpdateDate) async {
    final controller = ProductController();
    final products = await controller.getNewProduct(lastUpdateDate);
    print("prod finished: $products");
    downloadImages(products); // products zaten null olabilir, sorun değil

    var databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');

    Database db = await openDatabase(path, version: 1);

    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='Product';",
    );
    if (result.isEmpty) {
      await db.execute('''
          CREATE TABLE Product (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stokKodu TEXT,
            adetFiyati TEXT,
            kutuFiyati TEXT,
            pm1 TEXT,
            pm2 TEXT,
            pm3 TEXT,
            barcode1 TEXT,
            barcode2 TEXT,
            barcode3 TEXT,
            barcode4 TEXT,
            vat TEXT,
            urunAdi TEXT,
            birim1 TEXT,
            birimKey1 INTEGER,
            birim2 TEXT,
            birimKey2 INTEGER,
            aktif INTEGER,
            imsrc TEXT
          )
        ''');
    } else {
      // Sütunlar listesini al
      var columnsResult = await db.rawQuery("PRAGMA table_info(Product);");

      // Kolon isimlerini listele
      var columns = columnsResult.map((row) => row['name'] as String).toList();

      if (!columns.contains('imsrc')) {
        await db.execute("ALTER TABLE Product ADD COLUMN imsrc TEXT;");
      }
    }

    if (products != null) {
      await db.transaction((txn) async {
        for (var product in products) {
          await txn.insert('Product', product.toMap());
        }
      });

      //List<Map> list = await db.query('Product');
      //print('=== Products in database: ${list.length} $list===');
    }
  }

  Future<void> syncPendingSales() async {
    String savedApiKey = "";

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pos_database.db');

    final db = await openDatabase(path);

    List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

    if (result.isNotEmpty) {
      savedApiKey = result.first['apikey'];
      print('Retrieved API Key: $savedApiKey');
    } else {
      print('No API Key found.');
    }
    final pendingList = await db.query('PendingSales');

    for (final item in pendingList) {
      try {
        final fisJson = jsonDecode(item['fis'] as String);
        final satirlarJson = jsonDecode(item['satirlar'] as String);

        // FisModel oluştur
        final fisModel = FisModel(
          fisNo: fisJson['FisNo'],
          fistarihi: fisJson['Fistarihi'],
          musteriId: fisJson['MusteriId'],
          toplamtutar: fisJson['Toplamtutar']?.toDouble() ?? 0,
          odemeTuru: fisJson['OdemeTuru'],
          nakitOdeme: fisJson['NakitOdeme']?.toDouble() ?? 0,
          kartOdeme: fisJson['KartOdeme']?.toDouble() ?? 0,
          status: fisJson['Status'],
          deliveryDate: fisJson['DeliveryDate'],
          comment: fisJson['Comment'],
        );

        // CartItem listesi oluştur
        final satirlar =
            (satirlarJson as List<dynamic>).map((e) {
              return CartItem(
                stokKodu: e['StokKodu'],
                urunAdi: e['UrunAdi'] ?? '', // null olursa boş string
                miktar: e['Miktar'],
                birimFiyat: (e['BirimFiyat'] as num).toDouble(),
                vat: e['vat'],
                birimTipi: e['BirimTipi'],
                durum: e['Durum'],
                urunBarcode: e['UrunBarcode'],
                iskonto: e['Iskonto'],
                imsrc: e['Imsrc'],
              );
            }).toList();

        // Gönder
        OrderController orderController = OrderController();

        await orderController.satisGonder(
          fisModel: fisModel,
          satirlar: satirlar,
          bearerToken: savedApiKey,
        );

        // Başarılıysa sil
        await db.delete(
          'PendingSales',
          where: 'id = ?',
          whereArgs: [item['id']],
        );

        debugPrint(
          "Pending Satış gönderildi ve silindi: Fiş No ${fisModel.fisNo}",
        );
      } catch (e) {
        debugPrint("Gönderim hatası: $e");
      }
    }
  }

  // GET LAST UPDATE TIME
  // GET LAST UPDATE TIME
  Future<DateTime?> getLastUpdateTime(Database db) async {
    final List<Map<String, dynamic>> result = await db.query(
      'updateDates',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      String updateTimeString = result.first['update_time'] as String;
      final formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
      return formatter.parse(updateTimeString);
    } else {
      return null; // Tablo boşsa null döner
    }
  }

Future<void> downloadImages(List<ProductModel>? products) async {
  final dir = await getApplicationDocumentsDirectory();

  if (products == null || products.isEmpty) {
    print('⚠️ Ürün listesi boş veya null.');
    return;
  }

  for (final product in products) {
    final url = product.imsrc;

    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        final fileName = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'unknown.jpg'; // örnek: 10002.jpg

        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          print('✓ Kaydedildi: $fileName  -  $filePath');
        } else {
          print('❌ HTTP hatası: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Hata: $e');
      }
    }
  }

   
}

}
