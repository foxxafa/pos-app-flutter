import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/api_config.dart';

class ProductController {

Future<List<ProductModel>?> getNewProduct(DateTime date) async {
  final formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
  String formattedDate = formatter.format(date);
    String savedApiKey="";


  // 2. Veritabanını aç veya oluştur
  DatabaseHelper dbHelper = DatabaseHelper();
  Database db = await dbHelper.database;

  // 4. Apikey değerini veritabanından çek
  List<Map> result = await db.rawQuery('SELECT apikey FROM Login LIMIT 1');

  if (result.isNotEmpty) {
   savedApiKey = result.first['apikey'];
    print('Retrieved API Key: $savedApiKey');
  } else {
    print('No API Key found.');
  }

  final Uri url = Uri.parse(
    '${ApiConfig.indexPhpBase}?r=apimobil/getnewproducts&time=$formattedDate',
  );

  // HTTP client with timeout and retry
  final client = http.Client();
  http.Response? response;
  int maxRetries = 3;
  int retryDelay = 5; // seconds

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print('📡 Ürün indirme denemesi $attempt/$maxRetries...');

      response = await client.get(
        url,
        headers: {
          'Authorization': 'Bearer $savedApiKey',
          'Accept': 'application/json',
        },
      ).timeout(Duration(minutes: 5)); // 5 dakika timeout

      break; // Başarılı olursa döngüden çık

    } catch (e) {
      print('⚠️ Deneme $attempt başarısız: $e');

      if (attempt == maxRetries) {
        print('❌ Tüm denemeler başarısız oldu');
        client.close();
        return null;
      }

      print('🔄 $retryDelay saniye bekleyip tekrar denenecek...');
      await Future.delayed(Duration(seconds: retryDelay));
      retryDelay *= 2; // Exponential backoff
    }
  }

  client.close();

  if (response == null) {
    print('❌ HTTP response null - network problemi');
    return null;
  }

  print('✅ HTTP response alındı: ${response.statusCode}');

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // products listesi burada:
    if(data['status']==1){
          final List productsJson = data['customers'];

    // Listeyi CustomerModel listesine dönüştür
    final products = productsJson.map((json) => ProductModel.fromJson(json)).toList();

    print('✅ ${products.length} ürün başarıyla alındı');
    return products;

    } else {
      print('❌ API status: ${data['status']} - Ürün bulunamadı');
      return null;
    }
  } else {
    print('❌ HTTP Error: ${response.statusCode}');
    return null;
  }
} 

}
