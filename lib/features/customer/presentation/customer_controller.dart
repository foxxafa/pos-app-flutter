import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pos_app/features/customer/domain/entities/customer_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/api_config.dart';

class CustomerController {

Future<List<CustomerModel>?> getNewCustomer(DateTime date) async {
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
    '${ApiConfig.indexPhpBase}?r=apimobil/getnewcustomer&time=$formattedDate',
  );
print("giden 1 $url");
print("giden apikey $savedApiKey");
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $savedApiKey',
      'Accept': 'application/json',
    },
  );
print("giden 2 ${response.headers}");

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print("giden 3 $data");
    // customers listesi burada:
    if(data['status']==1){
          final List customersJson = data['customers'];

    // Listeyi CustomerModel listesine dönüştür
    final customers = customersJson.map((json) => CustomerModel.fromJson(json)).toList();

    return customers;
    }
return null;
  } else {
    print('giden Hata oluştu: ${response.statusCode}');
    print("giden hata response ${response.body}");
    return null;
  }
} 

}
