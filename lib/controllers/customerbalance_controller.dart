import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:pos_app/models/customer_balance.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerBalanceController {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
     CREATE TABLE CustomerBalance(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  unvan TEXT,
  vergiNo TEXT,
  vergiDairesi TEXT,
  adres TEXT,
  telefon TEXT,
  email TEXT,
  kod TEXT,
  postcode TEXT,
  city TEXT,
  contact TEXT,
  mobile TEXT,
  bakiye TEXT
)
    ''');
  }


Future<String> getCustomerBalanceByName(String customerName) async {
  print("DB CLOSE TIME 1");
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');

  final db = await openReadOnlyDatabase(path);

  final result = await db.query(
    'CustomerBalance',
    columns: ['bakiye'],
    where: 'LOWER(unvan) = ?',
    whereArgs: [customerName.toLowerCase()],
    limit: 1,
  );

  await db.close();

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
Future<void> printAllCustomerBalances() async {print("DB CLOSE TIME 2");
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');

  final db = await openReadOnlyDatabase(path);
  final result = await db.query('CustomerBalance');
  await db.close();

  for (var row in result) {
    print('--- Müşteri ---');
    row.forEach((key, value) {
      print('$key: $value');
    });
    print('----------------\n');
  }
}

  Future<void> insertCustomers(List<CustomerBalanceModel> customers) async {
      String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');
  final dbClient = await openDatabase(path);
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
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'pos_database.db');
  final db = await openDatabase(path);

  await db.delete('CustomerBalance');
  print('CustomerBalance tablosu temizlendi.');
  }

Future<void> fetchAndStoreCustomers() async {
  String savedApiKey = "";

  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');

  // Veritabanını aç
  Database db = await openDatabase(
    path,
    version: 1,
  );

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
    Uri.parse('https://test.rowhub.net/index.php?r=apimobil/musterilistesi'),
    headers: {
      'Authorization': 'Bearer $savedApiKey',
    },
  );

  if (response.statusCode == 200) {
    print("respsdfo ${response.body}");
    final List<dynamic> data = json.decode(response.body);
    final customers = data
        .map((json) => CustomerBalanceModel.fromJson(json))
        .toList();
    await clearAll();
    await insertCustomers(customers);
  } else {
    throw Exception('Veri alınamadı: ${response.statusCode}');
  }
}



Future<CustomerBalanceModel?> getCustomerByUnvan(String unvan) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'pos_database.db');

  final dbClient = await openDatabase(path);

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
