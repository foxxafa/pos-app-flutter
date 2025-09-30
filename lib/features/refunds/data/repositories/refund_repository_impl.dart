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
            iskonto: (row['iskonto'] as int?) ?? 0,
            vat: (row['vat'] as int?) ?? 0,
            birim: row['birim'] as String,
            birimFiyat: (row['birimFiyat'] as double?) ?? 0.0,
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
        iskonto: row['iskonto'] as int,
        vat: row['vat'] as int,
        birim: row['birim'] as String,
        birimFiyat: (row['birimFiyat'] as num).toDouble(),
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
        iskonto: row['iskonto'] as int,
        vat: row['vat'] as int,
        birim: row['birim'] as String,
        birimFiyat: (row['birimFiyat'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<void> insertPendingRefund(Map<String, dynamic> pendingData) async {
    final db = await _database;
    await db.insert('PendingRefunds', pendingData);
  }

  // ============= Refund Send Methods =============

  @override
  Future<bool> sendRefund(RefundSendModel refund) async {
    if (!await networkInfo.isConnected) {
      await saveRefundOffline(refund);
      print("📥 İnternet yok, refund offline kaydedildi.");
      return false;
    }

    print(jsonEncode(refund.toJson()));

    try {
      final response = await dio.post(
        ApiConfig.iadeUrl,
        data: refund.toJson(),
      );

      if (response.statusCode == 200) {
        print("✅ Refund gönderildi: ${response.data}");
        return true;
      } else {
        print("❌ Refund başarısız: ${response.data}");
        await saveRefundOffline(refund);
        return false;
      }
    } catch (e) {
      print("💥 Refund Hatası: $e");
      await saveRefundOffline(refund);
      return false;
    }
  }

  @override
  Future<void> saveRefundOffline(RefundSendModel refund) async {
    final db = await _database;

    // Create table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS refund_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      )
    ''');

    await db.insert(
      'refund_queue',
      {'data': jsonEncode(refund.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("📥 Refund offline queue'ya kaydedildi");
    print(jsonEncode(refund.toJson()));
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
        final success = await sendRefund(refund);

        if (success) {
          await deleteRefundById(id);
          print("✅ Offline refund gönderildi ve silindi (id: $id)");
        } else {
          print("❌ Refund gönderimi başarısız (id: $id)");
        }
      } catch (e) {
        print("💥 Parsing hatası (id: $id): $e");
      }
    }
  }
}