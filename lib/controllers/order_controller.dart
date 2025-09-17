import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:pos_app/models/order_model.dart';
import 'package:pos_app/providers/cart_provider.dart';

class OrderController {

  Future<void> satisGonder({
    required FisModel fisModel,
    required List<CartItem> satirlar,
    required String bearerToken, // Token opsiyonel parametre olarak eklendi
  }) async {

    final url = Uri.parse("https://test.rowhub.net/index.php?r=apimobil/satis"); //eskisi apikasa*

final body = jsonEncode({
  "fis": fisModel.toJson(),
  "satirlar": satirlar.map((e) {
final cleanedStokKodu = e.stokKodu
    .replaceAll('_(FREEUnit)', '')
    .replaceAll('_(FREEBox)', '')
    .replaceAll(' (FREEUnit)', '')
    .replaceAll(' (FREEBox)', '')
    .trim();

    
final cleanedUrunAdi = e.urunAdi
    .replaceAll('_(FREEUnit)', '')
    .replaceAll('_(FREEBox)', '')
    .replaceAll(' (FREEUnit)', '')
    .replaceAll(' (FREEBox)', '')
    .trim();

final cleanedJson = Map<String, dynamic>.from(e.toJson());
cleanedJson['StokKodu'] = cleanedStokKodu;
cleanedJson['UrunAdi'] = cleanedUrunAdi;
    return cleanedJson;
  }).toList(),
});

    
print("bearer token: $bearerToken");

print("satıis : $body");

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $bearerToken",
    };

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );
print("Status Code: ${response.statusCode}");
print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
  try {
    // İki JSON ardışık geldiği için ayırıyoruz
    // Son kısmı parse edeceğiz
    final parts = response.body.split('}{');
    String lastJson;
    if (parts.length > 1) {
      // parçaları tekrar düzgün JSON formatına getir
      lastJson = '{' + parts.last;
    } else {
      lastJson = response.body;
    }

    final jsonResponse = jsonDecode(lastJson);

    if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('status')) {
      print("Status: ${jsonResponse['status']}");
    } else {
      print("Status alanı bulunamadı. Yanıt: $lastJson");
    }
  } catch (e) {
    print("Yanıt JSON olarak çözümlenemedi: ${response.body}");
  }
} else {
  print("Hata: ${response.statusCode} - ${response.body}");
}

  }



}
