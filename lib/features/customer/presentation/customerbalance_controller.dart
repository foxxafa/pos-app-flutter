import 'package:pos_app/features/customer/domain/entities/customer_balance.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pos_app/core/network/api_config.dart';

class CustomerBalanceController {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {

    DatabaseHelper dbHelper = DatabaseHelper();
    return await dbHelper.database;
  }



Future<String> getCustomerBalanceByName(String customerName) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  final result = await db.query(
    'CustomerBalance',
    columns: ['bakiye'],
    where: 'LOWER(unvan) = ?',
    whereArgs: [customerName.toLowerCase()],
    limit: 1,
  );

  // Database açık kalacak - App Inspector için

  if (result.isNotEmpty) {
    return result[0]['bakiye']?.toString() ?? '0.00';
  } else {
    return '0.00'; // müşteri bulunamazsa varsayılan değer
  }
}

  Future<void> insertCustomer(CustomerBalanceModel model) async {
    final dbClient = await db;
    await dbClient.insert(
      'CustomerBalance',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
Future<void> printAllCustomerBalances() async {
  DatabaseHelper dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final result = await db.query('CustomerBalance');
  // Database açık kalacak - App Inspector için

  for (var row in result) {
    print('--- Müşteri ---');
    row.forEach((key, value) {
      print('$key: $value');
    });
    print('----------------\n');
  }
}

  Future<void> insertCustomers(List<CustomerBalanceModel> customers) async {
      DatabaseHelper dbHelper = DatabaseHelper();
  final dbClient = await dbHelper.database;
    final batch = dbClient.batch();

    for (var customer in customers) {
      batch.insert(
        'CustomerBalance',
        customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<CustomerBalanceModel>> getAllCustomers() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps =
        await dbClient.query('CustomerBalance');

    return List.generate(maps.length,
        (i) => CustomerBalanceModel.fromJson(maps[i]));
  }



  Future<void> clearAll() async {
  DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

  await db.delete('CustomerBalance');
  print('CustomerBalance tablosu temizlendi.');
  }

Future<void> fetchAndStoreCustomers() async {
  String savedApiKey = "";


  // Veritabanını aç
  DatabaseHelper dbHelper = DatabaseHelper();
  Database db = await dbHelper.database;

  // Apikey'i çek
  List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

  if (result.isNotEmpty) {
    savedApiKey = result.first['apikey'];
    print('Retrieved API Key: $savedApiKey');
  } else {
    print('No API Key found.');
    return; // Apikey yoksa devam etmeye gerek yok
  }

  final response = await http.get(
    Uri.parse(ApiConfig.musteriListesiUrl),
    headers: {
      'Authorization': 'Bearer $savedApiKey',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    final customers = data
        .map((json) => CustomerBalanceModel.fromJson(json))
        .toList();

    print('👥 ${customers.length} müşteri alındı');
    await clearAll();
    await insertCustomers(customers);
    print('✅ Müşteri veritabanı güncellendi');
  } else {
    throw Exception('Veri alınamadı: ${response.statusCode}');
  }
}



Future<CustomerBalanceModel?> getCustomerByUnvan(String unvan) async {

  DatabaseHelper dbHelper = DatabaseHelper();
  final dbClient = await dbHelper.database;

  final List<Map<String, dynamic>> maps = await dbClient.query(
    'CustomerBalance',
    where: 'unvan = ?',
    whereArgs: [unvan],
    limit: 1,
  );

  // dbClient.close(); // İstersen burada kapatabilirsin ama çoğu zaman gerekmez

  if (maps.isNotEmpty) {
    return CustomerBalanceModel.fromJson(maps.first);
  }
  return null;
}

}
