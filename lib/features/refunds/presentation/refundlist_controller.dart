import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';

class RefundListController {
  final String baseUrl = 'https://test.rowhub.net/index.php?r=apimobil/musteriurunleri';

  Future<Database> _getDatabase() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    return await dbHelper.database;
  }

  Future<List<Refund>> fetchRefunds(String cariKod) async {
    try {
      final url = Uri.parse('$baseUrl&carikod=$cariKod');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final refunds = jsonData.map((item) => Refund.fromJson(item)).toList();

        // Kaydet SQLite'a
        final db = await _getDatabase();
        await db.delete('Refunds'); // temizle eski kayıtları
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
    } on SocketException {
      // Offline: verileri localden çek
      final db = await _getDatabase();
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
  }

Future<void> insertPendingRefund(Map<String, dynamic> pendingData) async {
  DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database; // await unutma!
  await db.insert('PendingRefunds', pendingData);
}

Future<List<Refund>> getRefundsByMusteriId(String musteriId) async {
  final db = await _getDatabase();
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


Future<List<Refund>> getRefundsByMusteriIdAndStokKodu(
    String musteriId, String stokKodu) async {
  final db = await _getDatabase();

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

}
