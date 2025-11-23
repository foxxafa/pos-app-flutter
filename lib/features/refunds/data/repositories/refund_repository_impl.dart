// lib/features/refunds/data/repositories/refund_repository_impl.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:sqflite/sqflite.dart';

class RefundRepositoryImpl implements RefundRepository {
  final DatabaseHelper dbHelper;
  final NetworkInfo networkInfo;
  final Dio dio;

  RefundRepositoryImpl({
    required this.dbHelper,
    required this.networkInfo,
    required this.dio,
  });

  Future<Database> get _database async => await dbHelper.database;

  // ============= Refund List Methods =============

  @override
  Future<List<Refund>> fetchRefunds(String cariKod) async {
    try {
      final url = '${ApiConfig.musteriUrunleriUrl}&carikod=$cariKod';
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        final refunds = jsonData.map((item) => Refund.fromJson(item)).toList();

        // Save to SQLite
        final db = await _database;
        await db.delete('Refunds'); // Clear old records
        for (final refund in refunds) {
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
            'vat': refund.vat,
            'iskonto': refund.iskonto,
            'birimFiyat': refund.birimFiyat,
            'toplamTutar': refund.toplamTutar,
          });
        }

        return refunds;
      } else {
        throw Exception('Refund verileri alınamadı. [${response.statusCode}]');
      }
    } catch (e) {
      // Offline: fetch from local database
      if (!await networkInfo.isConnected) {
        print('⚠️ Offline mode - fetching refunds from local database');
        final db = await _database;
        final maps = await db.query('Refunds');
        return maps.map((row) {
          return Refund(
            fisNo: row['fisNo'] as String,
            musteriId: row['musteriId'] as String,
            fisTarihi: DateTime.parse(row['fisTarihi'] as String),
            unvan: row['unvan'] as String,
            stokKodu: row['stokKodu'] as String,
            urunAdi: row['urunAdi'] as String,
            urunBarcode: row['urunBarcode'] as String,
            miktar: (row['miktar'] as double?) ?? 0.0,
            iskonto: (row['iskonto'] as num?)?.toDouble() ?? 0.0,
            vat: (row['vat'] as int?) ?? 0,
            birim: row['birim'] as String,
            birimFiyat: (row['birimFiyat'] as double?) ?? 0.0,
            toplamTutar: row['toplamTutar'] != null ? (row['toplamTutar'] as num?)?.toDouble() : null,
          );
        }).toList();
      }
      rethrow;
    }
  }

  @override
  Future<List<Refund>> getRefundsByMusteriId(String musteriId) async {
    final db = await _database;
    final maps = await db.query(
      'Refunds',
      where: 'musteriId = ?',
      whereArgs: [musteriId],
    );

    return maps.map((row) {
      return Refund(
        fisNo: row['fisNo'] as String,
        musteriId: row['musteriId'] as String,
        fisTarihi: DateTime.parse(row['fisTarihi'] as String),
        unvan: row['unvan'] as String,
        stokKodu: row['stokKodu'] as String,
        urunAdi: row['urunAdi'] as String,
        urunBarcode: row['urunBarcode'] as String,
        miktar: (row['miktar'] as num).toDouble(),
        iskonto: (row['iskonto'] as num).toDouble(),
        vat: row['vat'] as int,
        birim: row['birim'] as String,
        birimFiyat: (row['birimFiyat'] as num).toDouble(),
        toplamTutar: row['toplamTutar'] != null ? (row['toplamTutar'] as num?)?.toDouble() : null,
      );
    }).toList();
  }

  @override
  Future<List<Refund>> getRefundsByMusteriIdAndStokKodu(
      String musteriId, String stokKodu) async {
    final db = await _database;

    final maps = await db.query(
      'Refunds',
      where: 'musteriId = ? AND stokKodu = ?',
      whereArgs: [musteriId, stokKodu],
    );

    return maps.map((row) {
      return Refund(
        fisNo: row['fisNo'] as String,
        musteriId: row['musteriId'] as String,
        fisTarihi: DateTime.parse(row['fisTarihi'] as String),
        unvan: row['unvan'] as String,
        stokKodu: row['stokKodu'] as String,
        urunAdi: row['urunAdi'] as String,
        urunBarcode: row['urunBarcode'] as String,
        miktar: (row['miktar'] as num).toDouble(),
        iskonto: (row['iskonto'] as num).toDouble(),
        vat: row['vat'] as int,
        birim: row['birim'] as String,
        birimFiyat: (row['birimFiyat'] as num).toDouble(),
        toplamTutar: row['toplamTutar'] != null ? (row['toplamTutar'] as num?)?.toDouble() : null,
      );
    }).toList();
  }

  @override
  Future<void> insertPendingRefund(Map<String, dynamic> pendingData) async {
    final db = await _database;
    await db.insert('PendingRefunds', pendingData);
  }

  // ============= Refund Send Methods =============

  /// Send refund to backend
  /// Returns: 'success', 'duplicate', or 'failed'
  Future<String> _sendRefundInternal(RefundSendModel refund) async {
    if (!await networkInfo.isConnected) {
      await saveRefundOffline(refund);
      print("📥 İnternet yok, refund offline kaydedildi.");
      return 'failed';
    }

    print(jsonEncode(refund.toJson()));

    try {
      final response = await dio.post(
        ApiConfig.iadeUrl,
        data: refund.toJson(),
      );

      if (response.statusCode == 200) {
        // ✅ Check backend's IsSuccessStatusCode field
        final data = response.data;
        if (data is Map && data['IsSuccessStatusCode'] == true) {
          print("✅ Refund başarıyla gönderildi: ${data['message']} (FisNo: ${refund.fis.fisNo})");
          return 'success';
        } else {
          // ✅ Check if error is due to duplicate FisNo
          final errorMessage = data['message']?.toString() ?? response.data.toString();
          if (errorMessage.contains('already been taken') || errorMessage.contains('Receipt Number')) {
            print("⚠️ Refund duplicate tespit edildi (backend'de zaten var): ${refund.fis.fisNo}");
            return 'duplicate';
          }

          print("❌ Refund backend tarafından reddedildi: $errorMessage");
          await saveRefundOffline(refund);
          return 'failed';
        }
      } else {
        print("❌ Refund HTTP hatası (${response.statusCode}): ${response.data}");
        await saveRefundOffline(refund);
        return 'failed';
      }
    } catch (e) {
      print("💥 Refund gönderimi sırasında hata: $e");
      await saveRefundOffline(refund);
      return 'failed';
    }
  }

  @override
  Future<bool> sendRefund(RefundSendModel refund) async {
    final result = await _sendRefundInternal(refund);
    return result == 'success';
  }

  @override
  Future<bool> saveRefundOffline(RefundSendModel refund) async {
    final db = await _database;

    // Create table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS refund_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      )
    ''');

    // ✅ Check if fisNo column exists
    final tableInfo = await db.rawQuery('PRAGMA table_info(refund_queue)');
    final hasFisNoColumn = tableInfo.any((column) => column['name'] == 'fisNo');

    // ✅ Add fisNo column if it doesn't exist (migration for existing tables)
    if (!hasFisNoColumn) {
      try {
        await db.execute('ALTER TABLE refund_queue ADD COLUMN fisNo TEXT');
        print("✅ fisNo column added to refund_queue");
      } catch (e) {
        print("⚠️ Error adding fisNo column: $e");
      }
    }

    // ✅ Check if this fisNo already exists in queue to prevent duplicates
    try {
      final existingRefund = await db.query(
        'refund_queue',
        where: 'fisNo = ?',
        whereArgs: [refund.fis.fisNo],
        limit: 1,
      );

      if (existingRefund.isNotEmpty) {
        print("⚠️ Refund with fisNo ${refund.fis.fisNo} already exists in queue, skipping duplicate");
        return false; // Duplicate, not saved
      }
    } catch (e) {
      // If fisNo column doesn't exist yet, continue (will be caught on next run)
      print("⚠️ Error checking for duplicate fisNo: $e");
    }

    await db.insert(
      'refund_queue',
      {
        'fisNo': refund.fis.fisNo,
        'data': jsonEncode(refund.toJson())
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore duplicates silently
    );

    print("📥 Refund offline queue'ya kaydedildi (FisNo: ${refund.fis.fisNo})");
    print(jsonEncode(refund.toJson()));
    return true; // Successfully saved
  }

  @override
  Future<List<Map<String, dynamic>>> getOfflineRefunds() async {
    final db = await _database;
    return await db.query('refund_queue');
  }

  @override
  Future<void> deleteRefundById(int id) async {
    final db = await _database;
    await db.delete('refund_queue', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> sendPendingRefunds() async {
    if (!await networkInfo.isConnected) {
      print("📴 Hâlâ internet yok, gönderim yapılmadı.");
      return;
    }

    final db = await _database;

    // Create table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS refund_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      )
    ''');

    // ✅ Check if fisNo column exists
    final tableInfo = await db.rawQuery('PRAGMA table_info(refund_queue)');
    final hasFisNoColumn = tableInfo.any((column) => column['name'] == 'fisNo');

    // ✅ Add fisNo column if it doesn't exist (migration for existing tables)
    if (!hasFisNoColumn) {
      try {
        await db.execute('ALTER TABLE refund_queue ADD COLUMN fisNo TEXT');
        print("✅ fisNo column added to refund_queue");
      } catch (e) {
        print("⚠️ Error adding fisNo column: $e");
      }
    }

    final rawList = await db.query('refund_queue');

    for (var row in rawList) {
      final int id = row['id'] as int;
      final String data = row['data'] as String;

      try {
        final decoded = jsonDecode(data);
        final fis = RefundFisModel(
          fisNo: decoded['fis']['FisNo'],
          fistarihi: decoded['fis']['Fistarihi'],
          musteriId: decoded['fis']['MusteriId'],
          toplamtutar: decoded['fis']['Toplamtutar'],
          aciklama: decoded['fis']['aciklama'] ?? '',
          status: decoded['fis']['Status'] ?? 2,
          iadeNedeni: decoded['fis']['IadeNedeni'] ?? '',
        );

        final satirlar = (decoded['satirlar'] as List).map((item) {
          return RefundItemModel(
            stokKodu: item['StokKodu'],
            urunAdi: item['UrunAdi'],
            miktar: item['Miktar'],
            birimFiyat: item['BirimFiyat'],
            toplamTutar: item['ToplamTutar'],
            vat: item['vat'],
            birimTipi: item['BirimTipi'],
            durum: item['Durum'],
            urunBarcode: item['UrunBarcode'],
            iskonto: item['Iskonto'],
            aciklama: item['aciklama'],
          );
        }).toList();

        final refund = RefundSendModel(fis: fis, satirlar: satirlar);
        final result = await _sendRefundInternal(refund);

        if (result == 'success') {
          await deleteRefundById(id);
          print("✅ Offline refund gönderildi ve silindi (id: $id, FisNo: ${fis.fisNo})");
        } else if (result == 'duplicate') {
          // ✅ Duplicate detected - delete from queue since it was already processed
          await deleteRefundById(id);
          print("🗑️ Duplicate refund queue'dan temizlendi (id: $id, FisNo: ${fis.fisNo})");
        } else {
          // Failed - keep in queue for retry
          print("❌ Refund gönderimi başarısız, queue'da bırakıldı (id: $id, FisNo: ${fis.fisNo})");
        }
      } catch (e) {
        print("💥 Parsing hatası (id: $id): $e");
      }
    }
  }
}