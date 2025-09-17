// cart_database_helper.dart
import 'package:path/path.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:sqflite/sqflite.dart';

class CartDatabaseRefundHelper {
  static final CartDatabaseRefundHelper _instance = CartDatabaseRefundHelper._internal();
  factory CartDatabaseRefundHelper() => _instance;
  CartDatabaseRefundHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'pos_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
      },
    );
  }

Future<void> clearCartItemsByCustomer(String customerName) async {
     _db = await _initDb();

  final db = await database;
  await db.delete(
    'cartrefund_items',
    where: 'customerName = ?',
    whereArgs: [customerName],
  );
}

Future<Database> getDatabase() async {
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');
  return await openDatabase(path);
}

Future<List<Map<String, dynamic>>> getCartItemsByCustomer(String customerName) async {
  final db = await getDatabase();
  return await db.query(
    'cartrefund_items',
    where: 'customerName = ?',
    whereArgs: [customerName],
  );
}


Future<List<Map<String, dynamic>>> getAllCartItems() async {
  final db = await getDatabase();
  return await db.query('cartrefund_items');
}
void printAllCartItems() async {
  final dbHelper = CartDatabaseRefundHelper();
  final items = await dbHelper.getAllCartItems();
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
    print('------------------\n');
  }
}

  Future<void> insertCartItem(CartItem item, String customerName) async {
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
