// lib/core/sync/sync_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/orders/domain/repositories/order_repository.dart';
import 'package:pos_app/features/products/domain/repositories/product_repository.dart';
import 'package:pos_app/features/products/domain/repositories/unit_repository.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:pos_app/features/orders/domain/entities/order_model.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Core synchronization service that coordinates multiple repositories
/// Handles data sync, image downloads, and pending operations
class SyncService {
  final CustomerRepository? customerRepository;
  final OrderRepository? orderRepository;
  final ProductRepository? productRepository;
  final RefundRepository? refundRepository;
  final UnitRepository? unitRepository;

  SyncService({
    this.customerRepository,
    this.orderRepository,
    this.productRepository,
    this.refundRepository,
    this.unitRepository,
  });

  // CLEAN SYNC
  cleanSync() async {
    print('🔄 Clean Sync başlatılıyor...');

    // Önce yarım kalan resim indirme işlemi var mı kontrol et
    await checkAndResumeImageDownload();

    if (customerRepository != null) {
      await customerRepository!.fetchAndStoreCustomers();
    }
    await syncPendingRefunds();
    //open database
    DatabaseHelper dbHelper = DatabaseHelper();
    Database db = await dbHelper.database;
      // Customer tablosu kaldırıldı - artık kullanılmıyor

    // Customer tablosu artık kullanılmıyor - CustomerBalance kullanılıyor
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

    print('📦 Ürün senkronizasyonu başlatılıyor...');
    //sync işlemleri
    await SyncProducts(DateTime(2024, 5, 1, 15, 55, 30));
    print('✅ Ürün senkronizasyonu tamamlandı');
    //await SyncCustomers(DateTime.now());

    // await SyncCustomers(DateTime(2024, 5, 1, 15, 55, 30)); // Customer sync devre dışı

    // Birimler ve Barkodlar senkronizasyonu
    if (unitRepository != null) {
      print('📦 Birimler ve Barkodlar senkronizasyonu başlatılıyor...');
      await unitRepository!.clearAllBirimler();
      await unitRepository!.clearAllBarkodlar();
      final success = await unitRepository!.fetchAndStoreBirimler();
      if (success) {
        print('✅ Birimler ve Barkodlar senkronizasyonu tamamlandı');
      } else {
        print('⚠️ Birimler ve Barkodlar senkronizasyonu başarısız');
      }
    }

    print('⏰ Son güncelleme zamanı kaydediliyor...');
    //update sonu son update saati güncelleme
    await saveLastUpdateTime(DateTime.now());
    print('✅ Clean Sync tamamlandı!');

    // Sync tamamlandıktan sonra resim indirmeyi başlat
    print('📦 Resim indirme başlatılıyor...');
    _downloadImagesInBackground();
    // Database açık kalacak - App Inspector için
  }

  //UPDATE SYNC
  updateSync() async {
    if (customerRepository != null) {
      await customerRepository!.fetchAndStoreCustomers();
    }
    await syncPendingRefunds();

    DateTime? lastUpdate = await getLastUpdateTime();
    print("last update $lastUpdate");
    //daha önce update edildi ve bu tarih kaydedildiyse
    if (lastUpdate != null) {
      await SyncProducts(lastUpdate);
      // await SyncCustomers(lastUpdate); // Customer sync devre dışı

      // Birimler ve Barkodlar güncellemeleri
      if (unitRepository != null) {
        print('📦 Birimler ve Barkodlar güncellemeleri kontrol ediliyor...');
        final success = await unitRepository!.fetchAndUpdateBirimler(lastUpdate);
        if (success) {
          print('✅ Birimler ve Barkodlar güncellendi');
        } else {
          print('⚠️ Birimler ve Barkodlar güncellemesi başarısız');
        }
      }

      //son update zamanı güncelleme
      await saveLastUpdateTime(DateTime.now());
      print('✅ Update Sync tamamlandı!');

      // Sync tamamlandıktan sonra resim indirmeyi başlat
      print('📦 Resim indirme başlatılıyor...');
      _downloadImagesInBackground();
    } else {
      print('Son güncelleme zamanı yok, updateSync() çalıştırılmadı.');
    }

    // Database açık kalacak - App Inspector için
  }

  //SYNC CUSTOMERS - DEVRE DIŞI (Customer tablosu kaldırıldı)
  //SYNC CUSTOMERS - ARTİK CUSTOMERBALANCE KULLANILIYOR
  Future<void> SyncCustomers(DateTime lastupdatedate) async {
    // Bu fonksiyon devre dışı - Customer tablosu kaldırıldı
    // Artık sadece CustomerBalance kullanılıyor (balancecontroller.fetchAndStoreCustomers() ile)
    print('SyncCustomers devre dışı - CustomerBalance kullanılıyor');
    return;
  }

  Future<void> SyncAllRefunds() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // 1. API'den sadece refund yapılabilecek carikod'ları al
    final apiResponse = await http.get(
      Uri.parse(ApiConfig.iademusterileriUrl),
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

    // 2. Veritabanındaki tüm CustomerBalance kayıtlarını al
    final customers = await db.query('CustomerBalance');

    // 3. Sadece API'den gelen carikod'lara sahip olanları filtrele
    final filteredCustomers =
        customers.where((customer) {
          final cariKod = customer['kod']?.toString().trim();
          return allowedCariKodlar.contains(cariKod);
        }).toList();

    print('✓ Senkronize edilecek müşteri sayısı: ${filteredCustomers.length}');

    // 4. Her uygun müşteri için refund senkronizasyonu yap
    for (final customer in filteredCustomers) {
      final cariKod = customer['kod'].toString().trim();

      print("🔄 Senkronize ediliyor: $cariKod");

      try {
        if (refundRepository != null) {
          final refunds = await refundRepository!.fetchRefunds(cariKod);
          print('✅ ${refunds.length} refund senkronize edildi: $cariKod');
        } else {
          print('⚠️ RefundRepository not provided');
        }
      } catch (e) {
        print('⛔ $cariKod refund senkronizasyonu başarısız: $e');
      }
    }
  }

  Future<void> syncPendingRefunds() async {
    if (refundRepository != null) {
      await refundRepository!.sendPendingRefunds();
    } else {
      print('⚠️ RefundRepository not provided');
    }
  }

  //SYNC PRODUCTS
  Future<void> SyncProducts(DateTime lastUpdateDate) async {
    List<ProductModel>? products;

    if (productRepository != null) {
      products = await productRepository!.getNewProduct(lastUpdateDate);
    } else {
      print('⚠️ ProductRepository not provided');
      return;
    }

    print("✅ ${products?.length ?? 0} ürün alındı");

    // Resim indirme kaldırıldı - sync sonrasında yapılacak

    DatabaseHelper dbHelper = DatabaseHelper();
    Database db = await dbHelper.database;

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
            imsrc TEXT,
            sortOrder INTEGER
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
      if (!columns.contains('sortOrder')) {
        await db.execute("ALTER TABLE Product ADD COLUMN sortOrder INTEGER;");
      }
    }

    if (products != null) {
      // ✅ Ürünleri sırala ve sortOrder ekle
      print('🔄 Ürünler sıralanıyor... (${products.length} ürün)');

      // İlk 5 ürünün sıralama öncesi halini göster
      if (products.length > 0) {
        print('📋 Sıralama öncesi ilk 5 ürün:');
        for (int i = 0; i < (products.length < 5 ? products.length : 5); i++) {
          print('  [$i] ${products[i].urunAdi}');
        }
      }

      products.sort((a, b) {
        final nameA = a.urunAdi.trim();
        final nameB = b.urunAdi.trim();

        // İlk karaktere bak (boş string kontrolü)
        if (nameA.isEmpty) return 1;
        if (nameB.isEmpty) return -1;

        final firstCharA = nameA[0];
        final firstCharB = nameB[0];

        // İlk karakter harf mi kontrol et
        final startsWithLetterA = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(firstCharA);
        final startsWithLetterB = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(firstCharB);

        // Harfle başlayanlar önce, sayı/özel karakterle başlayanlar sonra
        if (startsWithLetterA && !startsWithLetterB) return -1;
        if (!startsWithLetterA && startsWithLetterB) return 1;

        // İkisi de aynı tipte başlıyorsa alfabetik sırala
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

      // İlk 5 ürünün sıralama sonrası halini göster
      if (products.length > 0) {
        print('✅ Sıralama sonrası ilk 5 ürün:');
        for (int i = 0; i < (products.length < 5 ? products.length : 5); i++) {
          final name = products[i].urunAdi.trim();
          final firstChar = name.isNotEmpty ? name[0] : '';
          final startsWithLetter = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ]').hasMatch(firstChar);
          print('  [$i] ${products[i].urunAdi} (sortOrder: $i, ilkKarakter: "$firstChar", harf: $startsWithLetter)');
        }
      }

      print('✅ Ürün sıralaması tamamlandı');

      // ✅ Transaction içinde batch operation - deadlock önlenir
      // Local değişken oluştur (null-safety için)
      final productList = products;
      print('📦 ${productList.length} ürün veritabanına yazılıyor...');
      await db.transaction((txn) async {
        final batch = txn.batch();

        for (int i = 0; i < productList.length; i++) {
          final productMap = productList[i].toMap();
          productMap['sortOrder'] = i; // Sıra numarası ekle
          batch.insert('Product', productMap);
        }

        await batch.commit(noResult: true);
      });
      print('✅ Ürün veritabanı yazma tamamlandı');
    }
  }

  Future<void> syncPendingSales() async {
    String savedApiKey = "";

    DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

    if (result.isNotEmpty) {
      savedApiKey = result.first['apikey'];
      print('Retrieved API Key: $savedApiKey');
    } else {
      print('No API Key found.');
    }
    // Sadece pending ve retry_count < 3 olanları al
    final pendingList = await db.query(
      'PendingSales',
      where: "(status = 'pending' OR status IS NULL) AND (retry_count < 3 OR retry_count IS NULL)",
      orderBy: 'created_at ASC',
    );

    debugPrint('📤 ${pendingList.length} pending sipariş gönderilecek');

    int successCount = 0;
    int failedCount = 0;

    for (final item in pendingList) {
      final itemId = item['id'];
      final retryCount = (item['retry_count'] as int?) ?? 0;

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

        debugPrint('📤 Gönderiliyor: ${fisModel.fisNo} (Deneme: ${retryCount + 1})');

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
        bool success = false;
        if (orderRepository != null) {
          success = await orderRepository!.submitOrder(
            fisModel: fisModel,
            orderItems: satirlar,
            bearerToken: savedApiKey,
          );
        } else {
          debugPrint('⚠️ OrderRepository not provided, skipping order submission');
        }

        if (success) {
          // Başarılıysa sil
          await db.delete(
            'PendingSales',
            where: 'id = ?',
            whereArgs: [itemId],
          );

          debugPrint("✅ Sipariş gönderildi: ${fisModel.fisNo}");
          successCount++;
        } else {
          throw Exception('Server returned false');
        }
      } catch (e) {
        failedCount++;
        final errorMsg = e.toString();
        debugPrint("❌ Gönderim hatası (ID: $itemId): $errorMsg");

        // Retry count artır ve hatayı kaydet
        final newRetryCount = retryCount + 1;

        if (newRetryCount >= 3) {
          // 3 deneme sonrası failed olarak işaretle
          await db.update(
            'PendingSales',
            {
              'retry_count': newRetryCount,
              'status': 'failed',
              'last_error': errorMsg.length > 500 ? errorMsg.substring(0, 500) : errorMsg,
            },
            where: 'id = ?',
            whereArgs: [itemId],
          );
          debugPrint("⛔ Sipariş başarısız olarak işaretlendi (3 deneme): ID $itemId");
        } else {
          // Retry count artır, status pending kalsın
          await db.update(
            'PendingSales',
            {
              'retry_count': newRetryCount,
              'last_error': errorMsg.length > 500 ? errorMsg.substring(0, 500) : errorMsg,
            },
            where: 'id = ?',
            whereArgs: [itemId],
          );
          debugPrint("🔄 Sipariş tekrar denenecek: ID $itemId (Deneme: $newRetryCount/3)");
        }
      }
    }

    debugPrint('📊 Sync Özeti: ✅ $successCount başarılı, ❌ $failedCount başarısız');
  }

  // GET LAST UPDATE TIME - SharedPreferences kullanarak
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('last_sync_time');

      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      print('⚠️ Son güncelleme zamanı okunamadı: $e');
      return null;
    }
  }

  // SAVE LAST UPDATE TIME - SharedPreferences kullanarak
  Future<void> saveLastUpdateTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', time.toIso8601String());
      print('✅ Son güncelleme zamanı kaydedildi: ${time.toIso8601String()}');
    } catch (e) {
      print('⚠️ Son güncelleme zamanı kaydedilemedi: $e');
    }
  }

  // Arka planda resim indirme - sync'i bloklamaz ve uygulama kapansa bile devam eder
  void _downloadImagesInBackground() async {
    // Debug modunda arka plan resim indirme özelliğini kapat
    if (kDebugMode) {
      print('🔧 Debug modunda arka plan resim indirme devre dışı');
      return;
    }

    try {
      // Resim indirme durumunu kaydet
      await _saveImageDownloadState('started');

      // Veritabanından ürünleri al
      DatabaseHelper dbHelper = DatabaseHelper();
      Database db = await dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query('Product');
      final products = maps.map((map) => ProductModel.fromMap(map)).toList();

      if (products.isNotEmpty) {
        print('📱 Resim indirme arka planda başlatıldı - uygulama kapansa bile devam eder');
        await downloadImages(products);
        await _saveImageDownloadState('completed');
      }
    } catch (e) {
      print('⚠️ Resim indirme hatası: $e');
      await _saveImageDownloadState('failed');
    }
  }

  // Resim indirme durumunu veritabanına kaydet
  Future<void> _saveImageDownloadState(String state) async {
    try {
      DatabaseHelper dbHelper = DatabaseHelper();
      Database db = await dbHelper.database;

      // State tablosu yoksa oluştur
      await db.execute('''
        CREATE TABLE IF NOT EXISTS AppState (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      final now = DateTime.now().toIso8601String();

      await db.delete('AppState', where: 'key = ?', whereArgs: ['image_download_state']);
      await db.insert('AppState', {
        'key': 'image_download_state',
        'value': state,
        'updated_at': now,
      });
    } catch (e) {
      print('⚠️ State kaydetme hatası: $e');
    }
  }

  // Yarım kalan resim indirme işlemini kontrol et ve devam ettir
  Future<void> checkAndResumeImageDownload() async {
    try {
      DatabaseHelper dbHelper = DatabaseHelper();
      Database db = await dbHelper.database;

      // Create AppState table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS AppState (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      final result = await db.query(
        'AppState',
        where: 'key = ?',
        whereArgs: ['image_download_state'],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final state = result.first['value'] as String;
        final updatedAt = DateTime.parse(result.first['updated_at'] as String);
        final timeDiff = DateTime.now().difference(updatedAt).inHours;

        if (state == 'started' && timeDiff < 24) {
          print('🔄 Yarım kalan resim indirme işlemi devam ettiriliyor...');
          _downloadImagesInBackground();
        } else if (state == 'completed') {
          print('✅ Resim indirme zaten tamamlanmış');
        }
      } else {
        print('📱 İlk kez resim indirme yapılacak');
      }
    } catch (e) {
      print('⚠️ Resim indirme durumu kontrol hatası: $e');
    }
  }

Future<void> downloadImages(List<ProductModel>? products) async {
  final dir = await getApplicationDocumentsDirectory();

  if (products == null || products.isEmpty) {
    print('⚠️ Ürün listesi boş veya null.');
    return;
  }

  _backgroundDownloadActive = true;
  print('🔄 Arka plan resim indirme başlatıldı');

  // Resimleri öncelik sırasına göre ayır
  final priorityProducts = <ProductModel>[];
  final regularProducts = <ProductModel>[];

  // Öncelik algoritması:
  // 1. Aktif ürünler öncelikli
  // 2. Fiyatı olan ürünler öncelikli
  // 3. Barkodu olan ürünler öncelikli
  final sortedProducts = products.where((p) => p.imsrc != null && p.imsrc!.isNotEmpty).toList();

  sortedProducts.sort((a, b) {
    // Aktif ürünler önce
    int activeCompare = b.aktif.compareTo(a.aktif);
    if (activeCompare != 0) return activeCompare;

    // Fiyatı olanlar önce
    bool aHasPrice = (a.adetFiyati.isNotEmpty && a.adetFiyati != '0');
    bool bHasPrice = (b.adetFiyati.isNotEmpty && b.adetFiyati != '0');
    int priceCompare = bHasPrice.toString().compareTo(aHasPrice.toString());
    if (priceCompare != 0) return priceCompare;

    // Barkodu olanlar önce
    bool aHasBarcode = a.barcode1.isNotEmpty;
    bool bHasBarcode = b.barcode1.isNotEmpty;
    return bHasBarcode.toString().compareTo(aHasBarcode.toString());
  });

  for (var product in sortedProducts) {
    // Cart view'de görünen ürünleri öncelikle indir
    // İlk 50 ürün hemen gösterilir, 500 ürüne kadar arama sonucu gösterilebilir
    if (priorityProducts.length < 500) {
      priorityProducts.add(product);
    } else {
      regularProducts.add(product);
    }
  }

  final totalWithImages = priorityProducts.length + regularProducts.length;
  print('📦 ${totalWithImages} resimli ürün bulundu');
  print('🔥 ${priorityProducts.length} öncelikli resim');
  print('📁 ${regularProducts.length} normal resim');

  int downloaded = 0;

  // Önce öncelikli resimleri indir
  if (priorityProducts.isNotEmpty) {
    print('🔥 Öncelikli resimler indiriliyor...');
    downloaded = await _downloadBatchWithProgress(priorityProducts, dir.path, downloaded, totalWithImages);
  }

  // Sonra geri kalanları indir
  if (regularProducts.isNotEmpty) {
    print('📁 Normal resimler indiriliyor...');
    downloaded = await _downloadBatchWithProgress(regularProducts, dir.path, downloaded, totalWithImages);
  }

  print('✅ Resim indirme tamamlandı');
  _backgroundDownloadActive = false;
}

Future<int> _downloadBatchWithProgress(List<ProductModel> products, String dirPath, int initialCount, int total) async {
  const int maxConcurrent = 3;
  int downloaded = initialCount;

  for (int i = 0; i < products.length; i += maxConcurrent) {
    final batch = products.skip(i).take(maxConcurrent);
    final futures = <Future<void>>[];

    for (final product in batch) {
      futures.add(_downloadSingleImage(product.imsrc!, dirPath));
    }

    // Her batch'i bekle
    await Future.wait(futures);
    downloaded += futures.length;

    // İlerleme göster (her 10 resimde bir)
    if (downloaded % 10 == 0) {
      print('📦 $downloaded/$total resim indirildi...');
    }

    // Memory GC için kısa bekleme
    await Future.delayed(Duration(milliseconds: 100));
  }

  return downloaded;
}

Future<void> _downloadSingleImage(String url, String dirPath) async {
  try {
    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'unknown.jpg';

    final filePath = '$dirPath/$fileName';
    final file = File(filePath);

    // Dosya zaten varsa veya aktif indirme varsa atla
    if (await file.exists() || _activeDownloads.contains(fileName)) {
      return;
    }

    _activeDownloads.add(fileName);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✓ İndirildi: $fileName');
      }
    } finally {
      _activeDownloads.remove(fileName);
    }
  } catch (e) {
    // Sessizce geç - resim indirme hatası sync'i durdurmasın
  }
}

// Duplicate indirmeyi önlemek için aktif indirme listesi
static final Set<String> _activeDownloads = <String>{};

// Genel arka plan resim indirme durumu
static bool _backgroundDownloadActive = false;

// Arama sonucu ürünlerin resimlerini hemen indir (Cart View'den çağrılır)
static Future<void> downloadSearchResultImages(List<ProductModel> searchProducts, {Function? onImagesDownloaded}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final futures = <Future<void>>[];

    for (final product in searchProducts) {
      if (product.imsrc != null && product.imsrc!.isNotEmpty) {
        // Dosya var mı kontrol et
        final uri = Uri.parse(product.imsrc!);
        final fileName = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'unknown.jpg';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        // Dosya yoksa ve aktif indirme yapılmıyorsa indir
        if (!await file.exists() && !_activeDownloads.contains(fileName)) {
          _activeDownloads.add(fileName);
          futures.add(_downloadSearchImageWithCleanup(product.imsrc!, dir.path, product.urunAdi, fileName));
        }
      }
    }

    if (futures.isNotEmpty) {
      print('🔍 ${futures.length} arama sonucu resmi indiriliyor...');
      await Future.wait(futures);
      print('✅ Arama sonucu resimleri indirildi');

      // Resimler indirildikten sonra callback çağır (UI'ı yenile)
      if (onImagesDownloaded != null) {
        onImagesDownloaded();
      }
    }
  } catch (e) {
    print('⚠️ Arama resmi indirme hatası: $e');
  }
}

static Future<void> _downloadSearchImageWithCleanup(String url, String dirPath, String productName, String fileName) async {
  try {
    final filePath = '$dirPath/$fileName';
    final file = File(filePath);

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      print('🔍 Arama resmi indirildi: $productName');
    }
  } catch (e) {
    print('⚠️ $productName resmi indirilemedi');
  } finally {
    // İndirme tamamlandı - listeden çıkar
    _activeDownloads.remove(fileName);
  }
}

// Cart items için basit resim indirme (ProductModel oluşturmadan)
static Future<void> downloadCartItemImages(List<dynamic> cartItems, {Function? onImagesDownloaded}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final futures = <Future<void>>[];

    for (final item in cartItems) {
      final imsrc = item.imsrc;
      final urunAdi = item.urunAdi ?? 'Ürün';

      if (imsrc != null && imsrc.isNotEmpty) {
        final uri = Uri.parse(imsrc);
        final fileName = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'unknown.jpg';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        if (!await file.exists() && !_activeDownloads.contains(fileName)) {
          _activeDownloads.add(fileName);
          futures.add(_downloadSearchImageWithCleanup(imsrc, dir.path, urunAdi, fileName));
        }
      }
    }

    if (futures.isNotEmpty) {
      print('🛒 ${futures.length} sepet resmi indiriliyor...');
      await Future.wait(futures);
      print('✅ Sepet resimleri indirildi');

      if (onImagesDownloaded != null) {
        onImagesDownloaded();
      }
    }
  } catch (e) {
    print('⚠️ Sepet resmi indirme hatası: $e');
  }
}

// Arka plan resim indirme durumunu kontrol et
static bool isBackgroundDownloadActive() => _backgroundDownloadActive;

}