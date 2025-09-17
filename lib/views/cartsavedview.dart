import 'package:flutter/material.dart';
import 'package:pos_app/controllers/cartdatabase_helper.dart';

class CartListPage extends StatefulWidget {
  const CartListPage({super.key});

  @override
  State<CartListPage> createState() => _CartListPageState();
}

class _CartListPageState extends State<CartListPage> {
  Map<String, List<Map<String, dynamic>>> groupedCarts = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final dbHelper = CartDatabaseHelper();
    final allItems = await dbHelper.getAllCartItems();

    // Müşteriye göre gruplama
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in allItems) {
      final customer = item['customerName'] ?? 'Bilinmiyor';
      if (!grouped.containsKey(customer)) {
        grouped[customer] = [];
      }
      grouped[customer]!.add(item);
    }

    setState(() {
      groupedCarts = grouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tüm Kartlar")),
      body: groupedCarts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: groupedCarts.length,
              itemBuilder: (context, index) {
                final customer = groupedCarts.keys.elementAt(index);
                final items = groupedCarts[customer]!;

                return ExpansionTile(
                  title: Text(customer, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: items.map((item) {
                    return ListTile(
                      title: Text(item['urunAdi'] ?? '-'),
                      subtitle: Text("Miktar: ${item['miktar']} | Fiyat: ${item['birimFiyat']}"),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
