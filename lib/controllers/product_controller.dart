import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:pos_app/models/customer_model.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

class ProductController {
  final String _baseUrl = 'https://test.rowhub.net/index.php';

Future<List<ProductModel>?> getNewProduct(DateTime date) async {
  final formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
  String formattedDate = formatter.format(date);
    String savedApiKey="";
    String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'pos_database.db');


  // 2. Veritabanını aç veya oluştur
  Database db = await openDatabase(
    path,
    version: 1,
  );

  // 4. Apikey değerini veritabanından çek
  List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

  if (result.isNotEmpty) {
   savedApiKey = result.first['apikey'];
    print('Retrieved API Key: $savedApiKey');
  } else {
    print('No API Key found.');
  }

  final Uri url = Uri.parse(
    '$_baseUrl?r=apimobil/getnewproducts&time=$formattedDate',
  );

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $savedApiKey',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // products listesi burada:
    if(data['status']==1){
          final List productsJson = data['customers'];

    // Listeyi CustomerModel listesine dönüştür
    final products = productsJson.map((json) => ProductModel.fromJson(json)).toList();

final mata = json.decode(response.body);


final List<dynamic> customers = mata['customers'];

// JM JELLY STAND ( METAL ) ürününü tam olarak yazdır
for (var customer in customers) {
  if (customer['UrunAdi'] == 'JM JELLY STAND ( METAL )') {
    print('JM JELLY STAND ( METAL ) verisi:');
    print(customer);
    break; // yalnızca ilk eşleşeni yazdır, istersen break'i kaldır
  }
}

print('\nİlk 10 ürün verisi:\n');

int count = 0;
for (var customer in customers) {
  print('[$count] ${customer}');
  print('---');

  count++;
  if (count >= 10) break;
}


    return products;
    }
return null;
  } else {
    print('Hata oluştu: ${response.statusCode}');
    print("hata response ${response.body}");
    return null;
  }
} 

}
