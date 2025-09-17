import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pos_app/models/order_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sizer/sizer.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({Key? key}) : super(key: key);

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  List<Map<String, dynamic>> _pendingSales = [];
  List<Map<String, dynamic>> _pendingTahsilatlar = [];

  @override
  void initState() {
    super.initState();
    _loadPendingData();
  }

  Future<void> _loadPendingData() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_database.db');
    final db = await openDatabase(path, version: 1);

    // PendingSales tablosunu oluştur
    await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingSales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fis TEXT,
        satirlar TEXT
      )
    ''');

    // tahsilatlar tablosunu oluştur
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tahsilatlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        method TEXT
      )
    ''');

    final sales = await db.query('PendingSales');
    final tahsilatlar = await db.query('tahsilatlar');

    setState(() {
      _pendingSales = sales;
      _pendingTahsilatlar = tahsilatlar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PENDING')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🧾 Pending Orders", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            if (_pendingSales.isEmpty)
              Text("No pending sales.", style: TextStyle(fontSize: 13.sp))
            else
              ..._pendingSales.map((item) {
                final fisJson = jsonDecode(item['fis']);
                final satirlarJson = jsonDecode(item['satirlar']);

                final fis = FisModel(
                  fisNo: fisJson['FisNo'],
                  fistarihi: fisJson['Fistarihi'],
                  musteriId: fisJson['MusteriId'],
                  toplamtutar: fisJson['Toplamtutar']?.toDouble() ?? 0,
                  odemeTuru: fisJson['OdemeTuru'],
                  nakitOdeme: fisJson['NakitOdeme']?.toDouble() ?? 0,
                  kartOdeme: fisJson['KartOdeme']?.toDouble() ?? 0,
                  status: fisJson['Status'], deliveryDate: fisJson['DeliveryDate'], comment: fisJson['Comment'],
                );

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 1.h),
                  child: Padding(
                    padding: EdgeInsets.all(2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fiş No: ${fis.fisNo}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15.sp)),
                        SizedBox(height: 0.5.h),
                        Text("Tarih: ${fis.fistarihi}", style: TextStyle(fontSize: 13.sp)),
                        Text("Toplam: ${fis.toplamtutar.toStringAsFixed(2)}", style: TextStyle(fontSize: 13.sp)),
                        Text("Ürün Sayısı: ${satirlarJson.length}", style: TextStyle(fontSize: 13.sp)),
                        Divider(height: 2.h),
                        ...satirlarJson.map<Widget>((s) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.5.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(s['UrunAdi'] ?? 'Ürün',
                                        style: TextStyle(fontSize: 12.sp))),
                                Text("Adet: ${s['adet'] ?? 1}", style: TextStyle(fontSize: 12.sp)),
                                Text("${(s['ToplamTutar'] ?? 0).toStringAsFixed(2)}", style: TextStyle(fontSize: 12.sp)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }),

            SizedBox(height: 3.h),
            Text("💵 Pending Transactions", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            if (_pendingTahsilatlar.isEmpty)
              Text("No pending payments.", style: TextStyle(fontSize: 13.sp))
            else
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 1.h,
                crossAxisSpacing: 1.h,
                childAspectRatio: 0.75,
                children: _pendingTahsilatlar.map((item) {
                  final data = jsonDecode(item['data']);
                  final method = item['method'];

                  return Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: EdgeInsets.all(1.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${(data['tutar'] ?? 0).toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 0.5.h),
                          Text("Cari: ${data['carikod']}", style: TextStyle(fontSize: 11.sp)),
                          Text("Yöntem: $method", style: TextStyle(fontSize: 11.sp)),
                          Text("Açıklama:", style: TextStyle(fontSize: 11.sp)),
                          Text("${data['aciklama']}", style: TextStyle(fontSize: 10.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Spacer(),
                          Text("Kullanıcı: ${data['username']}", style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

                          SizedBox(height: 3.h),
            Text("↩️ Pending Refunds", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: () async {
                final dbPath = await getDatabasesPath();
                final path = join(dbPath, 'pos_database.db');
                final db = await openDatabase(path);
                await db.execute('''
  CREATE TABLE IF NOT EXISTS PendingRefunds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fisNo TEXT,
    musteriId TEXT,
    fisTarihi TEXT,
    toplamtutar REAL,
    satirlar TEXT
  )
''');

                return await db.query('PendingRefunds');
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

            
  final refunds = snapshot.data ?? [];
    
    if (refunds.isEmpty) {
                  return Text("No pending refunds.", style: TextStyle(fontSize: 13.sp));
                }

return Column(
  children: refunds.map((refund) {
    final itemsJson = refund['satirlar'] ?? '[]';
String formattedItems;
try {
  final decoded = jsonDecode(itemsJson);
  if (decoded is List) {
    formattedItems = decoded.map((e) => e.toString()).join('\n\n'); // Her item arası boş satır
  } else {
    formattedItems = itemsJson;
  }
} catch (e) {
  formattedItems = itemsJson; // JSON decode edilemezse direkt string göster
}


    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Fis No: ${refund['fisNo']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            Text("Musteri ID: ${refund['musteriId']}"),
            Text("Tarih: ${refund['fisTarihi']}"),
            Divider(height: 2.h),
Text(formattedItems, style: TextStyle(fontSize: 12.sp))
          ],
        ),
      ),
    );
  }).toList(),
);

              },
            ),

          ],
        ),
      ),
    );
  }
}
