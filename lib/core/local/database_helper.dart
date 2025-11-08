// lib/core/local/database_helper.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static const _databaseName = "pos_database.db";
  static const _databaseVersion = 9;  // Version artırıldı (cartrefund_items iskonto REAL için)

  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  // Unnamed constructor for backwards compatibility
  factory DatabaseHelper() => instance;

  // Single database instance
  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    debugPrint('Database path: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        debugPrint('Database opened successfully');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');
    await _createAllTables(db);
    debugPrint('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    debugPrint('⚠️ Database schema changed. Please uninstall and reinstall the app to apply changes.');

    // Migration kaldırıldı - Kullanıcılar uygulamayı yeniden yüklemelidir
    // Tüm tablolar _createAllTables metodunda güncel şema ile oluşturulur
  }

  Future<void> _createAllTables(Database db) async {
    // Login table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Login (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        apikey TEXT NOT NULL,
        day INTEGER NOT NULL
      )
    ''');

    // Customer table kaldırıldı - CustomerBalance kullanılıyor

    // Product table
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
        imsrc TEXT,
        sortOrder INTEGER,
        miktar REAL
      )
    ''');

    // CustomerBalance table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS CustomerBalance (
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

    // Cart items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fisNo TEXT,
        customerName TEXT,
        customerKod TEXT,
        isPlaced INTEGER DEFAULT 0,
        stokKodu TEXT,
        urunAdi TEXT,
        birimFiyat REAL,
        miktar INTEGER,
        urunBarcode TEXT,
        iskonto REAL,
        birimTipi TEXT,
        durum INTEGER,
        imsrc TEXT,
        vat INTEGER,
        adetFiyati TEXT,
        kutuFiyati TEXT
      )
    ''');

    // Refunds table - customer product list
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
        vat INTEGER,
        iskonto REAL,
        birim TEXT,
        birimFiyat REAL
      )
    ''');

    // Refund cart items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cartrefund_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT,
        stokKodu TEXT,
        urunAdi TEXT,
        birimFiyat REAL,
        miktar INTEGER,
        urunBarcode TEXT,
        iskonto REAL,
        birimTipi TEXT,
        durum INTEGER,
        imsrc TEXT,
        vat INTEGER,
        adetFiyati TEXT,
        kutuFiyati TEXT
      )
    ''');

    // Pending sales table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingSales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fis TEXT NOT NULL,
        satirlar TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        last_error TEXT
      )
    ''');

    // Pending refunds table
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

    // Tahsilatlar table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tahsilatlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        method TEXT
      )
    ''');

    // Birimler (Units) table - Ürün birimleri (UNIT, BOX, PALLET vb.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Birimler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        birimadi TEXT,
        birimkod TEXT,
        carpan REAL DEFAULT 1.0,
        fiyat1 REAL,
        fiyat2 REAL,
        fiyat3 REAL,
        fiyat4 REAL,
        fiyat5 REAL,
        fiyat6 REAL,
        fiyat7 REAL,
        fiyat8 REAL,
        fiyat9 REAL,
        fiyat10 REAL,
        _key TEXT,
        _key_scf_stokkart TEXT,
        StokKodu TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Barkodlar (Barcodes) table - Ürün barkodları
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Barkodlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        _key TEXT,
        _key_scf_stokkart_birimleri TEXT,
        barkod TEXT,
        turu TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Depostok (Depot Stock) table - Depo bazlı stok miktarları
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Depostok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        StokKodu TEXT NOT NULL,
        birim TEXT NOT NULL,
        miktar REAL DEFAULT 0.0
      )
    ''');

    // Index ekle - performans için (StokKodu + birim composite index)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_depostok_stokkodu_birim
      ON Depostok(StokKodu, birim)
    ''');

    // NOTE: AppState and refund_queue tables are created dynamically
    // at runtime in their respective services (sync_service.dart and
    // refund_repository_impl.dart) using CREATE TABLE IF NOT EXISTS.
    // This maintains backward compatibility with existing databases.

    // NOTE: UpdateDates tablosu kaldırıldı - Artık son senkronizasyon zamanı
    // SharedPreferences'ta 'last_sync_time' anahtarı ile saklanıyor (sync_service.dart)
  }

  // ============= CRUD Operations =============

  // Generic query method
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Generic insert method
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  // Generic update method
  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  // Generic delete method
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Custom query method
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // ============= Special Methods =============

  // Find pending sale by FisNo (FIXED: using existing database connection)
  Future<Map<String, dynamic>?> findPendingSaleByFisNo(String fisNo) async {
    final db = await database; // Use singleton instance
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

  // Check if table exists
  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Get table count
  Future<int> getTableCount(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Clear table
  Future<int> clearTable(String tableName) async {
    final db = await database;
    return await db.delete(tableName);
  }

  // Transaction helper
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // ============= Database Management =============

  // We don't close the database to keep it available for App Inspector
  // If you need to close it for some reason, uncomment this:
  // Future<void> closeDatabase() async {
  //   if (_database != null && _database!.isOpen) {
  //     await _database!.close();
  //     _database = null;
  //   }
  // }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    return {
      'path': db.path,
      'isOpen': db.isOpen,
      'version': await db.getVersion(),
    };
  }

  // For backwards compatibility with old code
  Future<Database> get db async => database;

  // ============= Legacy Methods for Backwards Compatibility =============

  // Legacy method used in startup_view.dart
  Future<void> createTablesIfNotExists(Database db) async {
    await _createAllTables(db);
  }

  // ============= Cart Helper Methods (from CartDatabaseHelper) =============

  Future<void> clearCartItemsByCustomer(String customerName, {String? fisNo, String? customerKod}) async {
    final db = await database;
    // ✅ SADECE aktif sepet kayıtlarını sil (isPlaced=0 veya NULL)
    // Placed orders'ı (isPlaced=1) koru!

    // ✅ FisNo ve customerKod ile filtrele (aynı müşterinin birden fazla sepeti olabilir!)
    if (fisNo != null && fisNo.isNotEmpty && customerKod != null && customerKod.isNotEmpty) {
      await db.delete(
        'cart_items',
        where: 'customerKod = ? AND fisNo = ? AND (isPlaced IS NULL OR isPlaced = ?)',
        whereArgs: [customerKod, fisNo, 0],
      );
      print('DEBUG clearCartItemsByCustomer: Cleared cart for customerKod=$customerKod, fisNo=$fisNo');
    } else {
      // Fallback: customerName ile sil (eski davranış - tüm sepetleri siler)
      await db.delete(
        'cart_items',
        where: 'customerName = ? AND (isPlaced IS NULL OR isPlaced = ?)',
        whereArgs: [customerName, 0],
      );
      print('DEBUG clearCartItemsByCustomer: Cleared ALL carts for customerName=$customerName (no fisNo specified)');
    }
  }

  Future<List<Map<String, dynamic>>> getCartItemsByCustomer(String customerIdentifier) async {
    final db = await database;
    // ✅ SADECE henüz place order yapılmamış siparişleri getir (isPlaced=0 veya NULL)
    // ✅ customerIdentifier ile hem customerName hem customerKod'u kontrol et
    return await db.query(
      'cart_items',
      where: '(customerName = ? OR customerKod = ?) AND (isPlaced IS NULL OR isPlaced = ?)',
      whereArgs: [customerIdentifier, customerIdentifier, 0],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCartItems() async {
    final db = await database;
    return await db.query('cart_items');
  }

  void printAllCartItems() async {
    final items = await getAllCartItems();
    print('--- CARTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT ---');

    for (var item in items) {
      print('--- CART ITEM ---');
      print('Müşteri       : ${item['customerName']}');
      print('Stok Kodu     : ${item['stokKodu']}');
      print('Ürün Adı      : ${item['urunAdi']}');
      print('Miktar        : ${item['miktar']}');
      print('Fiyat         : ${item['birimFiyat']}');
      print('İskonto       : ${item['iskonto']}');
      print('Birim Tipi    : ${item['birimTipi']}');
      print('Barkod        : ${item['urunBarcode']}');
      print('Durum         : ${item['durum']}');
      print('------------------');
    }
  }

  Future<void> insertCartItem(dynamic item, String customerName) async {
    final db = await database;
    await db.insert('cart_items', {
      'customerName': customerName,
      'stokKodu': item.stokKodu,
      'urunAdi': item.urunAdi,
      'birimFiyat': item.birimFiyat,
      'miktar': item.miktar,
      'urunBarcode': item.urunBarcode,
      'iskonto': item.iskonto,
      'birimTipi': item.birimTipi,
      'durum': item.durum,
      'imsrc': item.imsrc,
      'vat': item.vat,
      'adetFiyati': item.adetFiyati,
      'kutuFiyati': item.kutuFiyati,
    });
  }

  // ============= Refund Cart Helper Methods (from CartDatabaseRefundHelper) =============

  Future<void> clearRefundCartItemsByCustomer(String customerName) async {
    final db = await database;
    await db.delete(
      'cartrefund_items',
      where: 'customerName = ?',
      whereArgs: [customerName],
    );
  }

  Future<List<Map<String, dynamic>>> getRefundCartItemsByCustomer(String customerName) async {
    final db = await database;
    return await db.query(
      'cartrefund_items',
      where: 'customerName = ?',
      whereArgs: [customerName],
    );
  }

  Future<List<Map<String, dynamic>>> getAllRefundCartItems() async {
    final db = await database;
    return await db.query('cartrefund_items');
  }

  void printAllRefundCartItems() async {
    final items = await getAllRefundCartItems();
    print('--- REFUND CARTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT ---');

    for (var item in items) {
      print('--- REFUND CART ITEM ---');
      print('Müşteri       : ${item['customerName']}');
      print('Stok Kodu     : ${item['stokKodu']}');
      print('Ürün Adı      : ${item['urunAdi']}');
      print('Miktar        : ${item['miktar']}');
      print('Fiyat         : ${item['birimFiyat']}');
      print('İskonto       : ${item['iskonto']}');
      print('Birim Tipi    : ${item['birimTipi']}');
      print('Barkod        : ${item['urunBarcode']}');
      print('Durum         : ${item['durum']}');
      print('------------------');
    }
  }

  Future<void> insertRefundCartItem(dynamic item, String customerName) async {
    final db = await database;
    await db.insert('cartrefund_items', {
      'customerName': customerName,
      'stokKodu': item.stokKodu,
      'urunAdi': item.urunAdi,
      'birimFiyat': item.birimFiyat,
      'miktar': item.miktar,
      'urunBarcode': item.urunBarcode,
      'iskonto': item.iskonto,
      'birimTipi': item.birimTipi,
      'durum': item.durum,
      'imsrc': item.imsrc,
      'vat': item.vat,
      'adetFiyati': item.adetFiyati,
      'kutuFiyati': item.kutuFiyati,
    });
  }
}