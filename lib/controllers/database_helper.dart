import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db == null || !_db!.isOpen) {
      _db = await _initDb();
    }
    return _db!;
  }

  Future<Map<String, dynamic>?> findPendingSaleByFisNo(String fisNo) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(join(dbPath, 'pos_database.db'));

    final result = await db.query('PendingSales');

    for (final row in result) {
      final fisStr = row['fis']?.toString();
      if (fisStr == null) continue;

      final fisMap = jsonDecode(fisStr);
      if (fisMap['FisNo'] == fisNo) {
        return {
          'fis': fisStr,
          'satirlar': row['satirlar']?.toString() ?? '[]',
        };
      }
    }

    return null;
  }


  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pos_database.db');
    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final database = await db;
    return await database.query(table);
  }

  Future<void> closeDb() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> createTablesIfNotExists(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS Login (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      apikey TEXT NOT NULL,
      day INTEGER NOT NULL
    )
  ''');
    await db.execute('''
     CREATE TABLE IF NOT EXISTS CustomerBalance(
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

            await db.execute('''
          CREATE TABLE IF NOT EXISTS cart_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerName TEXT,
            stokKodu TEXT,
            urunAdi TEXT,
            birimFiyat REAL,
            miktar INTEGER,
            urunBarcode TEXT,
            iskonto INTEGER,
            birimTipi TEXT,
            durum INTEGER,
            imsrc TEXT,
            vat INTEGER,
            adetFiyati TEXT,
            kutuFiyati TEXT
          )
        ''');
       await db.execute('''
          CREATE TABLE IF NOT EXISTS PendingRefunds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fisNo TEXT,
            musteriId TEXT,
            fisTarihi TEXT,
            toplamtutar REAL,
            satirlar TEXT
          );
        ''');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Refunds (
            fisNo TEXT,
            musteriId TEXT,
            fisTarihi TEXT,
            unvan TEXT,
            stokKodu TEXT,
            urunAdi TEXT,
            urunBarcode TEXT,
            miktar REAL,
            vat int,
            iskonto int,
            birim TEXT,
            birimFiyat REAL
          );
        ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS updateDates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      update_time TEXT NOT NULL
    )
  ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS cartrefund_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerName TEXT,
            stokKodu TEXT,
            urunAdi TEXT,
            birimFiyat REAL,
            miktar INTEGER,
            urunBarcode TEXT,
            iskonto INTEGER,
            birimTipi TEXT,
            durum INTEGER,
            imsrc TEXT,
            vat INTEGER,
            adetFiyati TEXT,
            kutuFiyati TEXT
          )
        ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS Customer (
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

  await db.execute('''
    CREATE TABLE IF NOT EXISTS Product (
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
      birimKey2 TEXT,
      aktif INTEGER,
      imsrc TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS PendingSales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fis TEXT,
      satirlar TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS tahsilatlar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data TEXT,
      method TEXT
    )
  ''');
}

}
