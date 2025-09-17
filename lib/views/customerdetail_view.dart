import 'package:flutter/material.dart';
import 'package:pos_app/models/customer_balance.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailView extends StatelessWidget {
  const CustomerDetailView({Key? key}) : super(key: key);

  Future<CustomerBalanceModel?> loadCustomerDetail(String customerCode) async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'pos_database.db');

    final db = await openDatabase(path);

    final result = await db.query(
      'CustomerBalance',
      where: 'kod = ?',
      whereArgs: [customerCode],
    );
print("DB CLOSE TIME 7");
    await db.close();

    if (result.isNotEmpty) {
      return CustomerBalanceModel(
        unvan: result[0]['unvan'] as String?,
        vergiNo: result[0]['vergiNo'] as String?,
        vergiDairesi: result[0]['vergiDairesi'] as String?,
        adres: result[0]['adres'] as String?,
        telefon: result[0]['telefon'] as String?,
        email: result[0]['email'] as String?,
        kod: result[0]['kod'] as String?,
        postcode: result[0]['postcode'] as String?,
        city: result[0]['city'] as String?,
        contact: result[0]['contact'] as String?,
        mobile: result[0]['mobile'] as String?,
        bakiye: result[0]['bakiye'] as String?,
      );
    } else {
      return null;
    }
  }

Future<void> launchGoogleMapsWithUKPostcode(String postcode) async {
  final query = Uri.encodeComponent('$postcode, United Kingdom');
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Harita açılamadı: $e');
  }
}

Future<void> launchGoogleMapsQuery(String queryText) async {
  final query = Uri.encodeComponent(queryText);
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Harita açılamadı: $e');
  }
}





  Widget buildDetailRow(String label, String? value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value ?? "-",
                maxLines: 3,
                style: onTap != null
                    ? const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerCode =
        Provider.of<SalesCustomerProvider>(context, listen: false)
            .selectedCustomer!
            .kod;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Detail"),
      ),
      body: FutureBuilder<CustomerBalanceModel?>(
        future: loadCustomerDetail(customerCode ?? "TURAN"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Müşteri bulunamadı"));
          }

          final customer = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildDetailRow("Unvan", customer.unvan),
                buildDetailRow("Kod", customer.kod),
                buildDetailRow("Vergi No", customer.vergiNo),
                buildDetailRow("Vergi Dairesi", customer.vergiDairesi),
buildDetailRow(
  "Adres",
  customer.adres,
  onTap: customer.adres != null
      ? () => launchGoogleMapsQuery(customer.adres!)
      : null,
),

buildDetailRow(
  "Posta Kodu",
  customer.postcode,
  onTap: customer.postcode != null
      ? () => launchGoogleMapsWithUKPostcode(customer.postcode!)
      : null,
),

                buildDetailRow("Şehir", customer.city),
                buildDetailRow("Telefon", customer.telefon),
                buildDetailRow("Mobil", customer.mobile),
                buildDetailRow("Email", customer.email),
                buildDetailRow("İlgili Kişi", customer.contact),
                buildDetailRow("Bakiye", customer.bakiye),
              ],
            ),
          );
        },
      ),
    );
  }
}
