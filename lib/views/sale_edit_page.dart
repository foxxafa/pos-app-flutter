import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sizer/sizer.dart';

class SaleEditPage extends StatefulWidget {
  final String orderNo;
  const SaleEditPage({super.key, required this.orderNo});

  @override
  State<SaleEditPage> createState() => _SaleEditPageState();
}

class _SaleEditPageState extends State<SaleEditPage> {
  Map<String, dynamic> fis = {};
  List<Map<String, dynamic>> satirlar = [];
  bool isLoading = true;

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  Map<int, TextEditingController> miktarControllers = {};
  Map<int, TextEditingController> vatControllers = {};
  Map<int, TextEditingController> iskontoControllers = {};

  final decimalFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  double parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _loadData() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_database.db');
    final db = await openDatabase(path);

    final rows = await db.query('PendingSales');
    for (var row in rows) {
      final rawFis = row['fis'];
      final fisJson = jsonDecode(rawFis.toString());
      if (fisJson['FisNo'] == widget.orderNo) {
        fis = fisJson;
        satirlar = List<Map<String, dynamic>>.from(
          jsonDecode(row['satirlar'].toString()),
        );
        break;
      }
    }

    allProducts = await db.query('Product');

    for (int i = 0; i < satirlar.length; i++) {
      miktarControllers[i] = TextEditingController(text: satirlar[i]['Miktar'].toString());
      vatControllers[i] = TextEditingController(text: satirlar[i]['vat'].toString());
      iskontoControllers[i] = TextEditingController(text: satirlar[i]['Iskonto'].toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  double calculateTotal() {
    double total = 0.0;
    for (var s in satirlar) {
      final miktar = parseSafeDouble(s['Miktar']);
      final vat = parseSafeDouble(s['vat']);
      final iskonto = parseSafeDouble(s['Iskonto']);
      final birimTipi = (s['BirimTipi'] ?? 'Box').toString().toLowerCase();

      double fiyat = 0.0;

      if (parseSafeDouble(s['BirimFiyat']) > 0) {
        fiyat = parseSafeDouble(s['BirimFiyat']);
      } else {
        fiyat = birimTipi == 'unit'
            ? parseSafeDouble(s['AdetFiyati'])
            : parseSafeDouble(s['KutuFiyati']);
      }

      double araToplam = fiyat * miktar;
      double kdvli = araToplam * (1 + vat / 100);
      double indirimli = kdvli * (1 - iskonto / 100);

      s['BirimFiyat'] = fiyat;
      s['ToplamTutar'] = double.parse(indirimli.toStringAsFixed(2));
      total += s['ToplamTutar'];
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Future<void> _saveToDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_database.db');
    final db = await openDatabase(path);

    fis['Toplamtutar'] = calculateTotal();

    await db.update(
      'PendingSales',
      {
        'fis': jsonEncode(fis),
        'satirlar': jsonEncode(satirlar),
      },
      where: 'fis LIKE ?',
      whereArgs: ['%"FisNo":"${widget.orderNo}"%'],
    );
  }

  Future<void> _showProductPicker(BuildContext context) async {
    filteredProducts = List.from(allProducts);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterProducts(String query) {
  final lowerQueryWords = query.toLowerCase().split(RegExp(r'\s+')); // "yoghurt 1kg" → ['yoghurt', '1kg']

  setModalState(() {
    filteredProducts = allProducts.where((p) {
      final combinedFields = [
        p['urunAdi'],
        p['barcode1'],
        p['barcode2'],
        p['barcode3'],
        p['barcode4'],
      ].whereType<String>().map((s) => s.toLowerCase()).join(' '); // tüm alanları tek bir stringte birleştir

      // her kelime combinedFields içinde geçiyor mu kontrol et
      return lowerQueryWords.every((word) => combinedFields.contains(word));
    }).toList();
  });
}


            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!searchFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(searchFocusNode);
              }
            });

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 10,
                left: 10,
                right: 10,
              ),
              child: SizedBox(
                height: 60.h,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Search product by name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: filterProducts,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(child: Text('No products found'))
                          : ListView.builder(
                              itemCount: filteredProducts.length,
                              itemBuilder: (_, index) {
                                final p = filteredProducts[index];
                                return ListTile(
                                  title: Text(p['urunAdi']?.toString() ?? "Product"),
                                  onTap: () {
                                    setState(() {
                                      final index = satirlar.length;
                                      satirlar.add({
                                        "StokKodu": p['stokKodu'],
                                        "UrunAdi": p['urunAdi'],
                                        "Miktar": 1.0,
                                        "BirimTipi": "Box",
                                        "BirimFiyat": parseSafeDouble(p['kutuFiyati']),
                                        "AdetFiyati": parseSafeDouble(p['adetFiyati']),
                                        "KutuFiyati": parseSafeDouble(p['kutuFiyati']),
                                        "vat": parseSafeDouble(p['vat']),
                                        "Iskonto": 0.0,
                                        "ToplamTutar": 0.0,
                                        "Durum": 1,
                                        "Aciklama": "",
                                        "Imsrc": p['imsrc'],
                                      });

                                      miktarControllers[index] =
                                          TextEditingController(text: "1.0");
                                      vatControllers[index] =
                                          TextEditingController(text: parseSafeDouble(p['vat']).toString());
                                      iskontoControllers[index] =
                                          TextEditingController(text: "0.0");

                                      calculateTotal();
                                    });

                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    for (var c in miktarControllers.values) {
      c.dispose();
    }
    for (var c in vatControllers.values) {
      c.dispose();
    }
    for (var c in iskontoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toplam = calculateTotal();

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Invoice: ${widget.orderNo}"),
            actions: [
              IconButton(
                icon: Icon(Icons.save, size: 25.sp),
                onPressed: () async {
                  await _saveToDb();
                  await RecentActivityController.updateActivityTotal(
  fisNo: widget.orderNo,
  newTotal: calculateTotal().toStringAsFixed(2),
);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Record updated")),
                    );
int count = 0;
Navigator.of(context).popUntil((route) {
  return count++ >= 2;
});

                    
                  }
                },
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(
                        "Total: $toplam",
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: satirlar.length,
                        itemBuilder: (context, i) {
                          final item = satirlar[i];

                          return Card(
                            margin: EdgeInsets.all(3.w),
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: const InputDecoration(labelText: 'Product Name'),
                                          controller: TextEditingController(text: item['UrunAdi']),
                                          readOnly: true,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            satirlar.removeAt(i);
                                            miktarControllers.remove(i);
                                            vatControllers.remove(i);
                                            iskontoControllers.remove(i);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  TextField(
                                    controller: TextEditingController(text: item['StokKodu']),
                                    decoration: const InputDecoration(labelText: 'Stock Code'),
                                    readOnly: true,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: miktarControllers[i],
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [decimalFormatter],
                                          decoration: const InputDecoration(labelText: 'Quantity'),
                                          onChanged: (val) {
                                            item['Miktar'] = double.tryParse(val) ?? 0.0;
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: (item['BirimTipi'] == 'Box' || item['BirimTipi'] == 'Unit')
                                              ? item['BirimTipi']
                                              : 'Box',
                                          items: const [
                                            DropdownMenuItem(value: 'Box', child: Text('Box')),
                                            DropdownMenuItem(value: 'Unit', child: Text('Unit')),
                                          ],
                                          onChanged: (selection) {
                                            setState(() {
                                              item['BirimTipi'] = selection ?? 'Box';
                                              item['BirimFiyat'] = selection?.toLowerCase() == 'unit'
                                                  ? parseSafeDouble(item['AdetFiyati'])
                                                  : parseSafeDouble(item['KutuFiyati']);
                                            });
                                          },
                                          decoration: const InputDecoration(labelText: 'Unit Type'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextField(
                                    controller: vatControllers[i],
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [decimalFormatter],
                                    decoration: const InputDecoration(labelText: 'VAT (%)'),
                                    onChanged: (val) {
                                      item['vat'] = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                  TextField(
                                    controller: iskontoControllers[i],
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [decimalFormatter],
                                    decoration: const InputDecoration(labelText: 'Discount (%)'),
                                    onChanged: (val) {
                                      item['Iskonto'] = double.tryParse(val) ?? 0.0;
                                      setState(() {});
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2.w),
                                    child: Text(
                                      'Total Price: ${(item['ToplamTutar'] ?? 0.0).toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.w, left: 4.w, right: 4.w),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Add New Product"),
                        onPressed: () => _showProductPicker(context),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
