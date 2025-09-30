import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos_app/features/transactions/domain/entities/cheque_model.dart';
import 'package:pos_app/features/transactions/domain/entities/transaction_model.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';

class TahsilatController {
  Future<bool> sendTahsilat(
      BuildContext context, TahsilatModel model, String method,{ChequeModel? cheque_model}) async {
String url;
final normalizedMethod = method.trim().toLowerCase();

if (normalizedMethod == "cash"|| normalizedMethod == "nakit") {
  url = 'https://test.rowhub.net/index.php?r=apimobil/nakittahsilat';
} else if (normalizedMethod == "cheque" || normalizedMethod == "cek" || normalizedMethod == "çek") {
  url = 'https://test.rowhub.net/index.php?r=apimobil/cektahsilat';
} else if (normalizedMethod == "bank" || normalizedMethod == "banka") {
  url = 'https://test.rowhub.net/index.php?r=apimobil/bankatahsilat';
} else if (normalizedMethod == "credit card" || normalizedMethod == "kredikarti") {
  url = 'https://test.rowhub.net/index.php?r=apimobil/kredikartitahsilat';
} else {
  throw Exception("Geçersiz ödeme yöntemi: $method");
}


if(method=="Cheque"){
  final token = Provider.of<UserProvider>(context, listen: false).apikey;
  print("token $token");
  try {
    print("odeme ${jsonEncode(cheque_model!.toJson())}");
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(cheque_model.toJson()),
    );
  
    if (response.statusCode == 200) {
      print("Tahsilat başarılı: ${response.body}");
      return true;
    } else {
      print("Tahsilat başarısız: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Tahsilat hatası: $e");
    return false;
  }
}

    else {
  final token = Provider.of<UserProvider>(context, listen: false).apikey;
    print("token $token");

  try {
    print(jsonEncode(model.toJson()));
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(model.toJson()),
    );
  
    if (response.statusCode == 200) {
      print("Tahsilat başarılı response.body: ${response.body}");
      return true;
    } else {
      print("Tahsilat başarısız response.body: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Tahsilat hatası: $e");
    return false;
  }
}
  }
}
