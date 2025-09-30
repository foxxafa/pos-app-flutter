import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';

class RefundSendController {
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    DatabaseHelper dbHelper = DatabaseHelper();
    _db = await dbHelper.database;
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS refund_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      )
    ''');
    return _db!;
  }

  /// Refund gönderimi - internet varsa gönder, yoksa sqflite'a kaydet
  Future<bool> sendRefund(RefundSendModel refund) async {
    const String url = 'https://test.rowhub.net/index.php?r=apimobil/iade';

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await saveRefundOffline(refund);
      print("📥 İnternet yok, refund offline kaydedildi.");
      return false;
    }
    print(jsonEncode(refund.toJson()));

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(refund.toJson()),
      );

      if (response.statusCode == 200) {
        print("✅ Refund gönderildi: ${response.body}");
        return true;
      } else {
        print("❌ Refund başarısız: ${response.body}");
        await saveRefundOffline(refund);
        return false;
      }
    } catch (e) {
      print("💥 Refund Hatası: $e");
      await saveRefundOffline(refund);
      return false;
    }
  }

  /// Offline refund kaydetme
  Future<void> saveRefundOffline(RefundSendModel refund) async {
    final database = await db;
    await database.insert(
      'refund_queue',
      {'data': jsonEncode(refund.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    ); 
    print("saved ?))()()");
    print(jsonEncode(refund.toJson()));

    print("saved ?))()()");
  }

  /// Offline refund'ları listele
  Future<List<Map<String, dynamic>>> getOfflineRefunds() async {
    final database = await db;
    return await database.query('refund_queue');
  }

  /// Refund satırını sil (başarıyla gönderildiyse)
  Future<void> deleteRefundById(int id) async {
    final database = await db;
    await database.delete('refund_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Tüm offline refund'ları gönder
  Future<void> sendPendingRefunds() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      print("📴 Hâlâ internet yok, gönderim yapılmadı.");
      return;
    }

    final database = await db;
    final rawList = await database.query('refund_queue');

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
          odemeTuru: decoded['fis']['OdemeTuru'],
          nakitOdeme: decoded['fis']['NakitOdeme'],
          kartOdeme: decoded['fis']['KartOdeme'],
          aciklama: decoded['fis']['aciklama'],
          status: decoded['fis']['Status'],
          iadeNedeni: decoded['fis']['IadeNedeni'],
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
