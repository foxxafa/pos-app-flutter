import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/refunds/presentation/screens/refundcart_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart';

class RefundList2View extends StatefulWidget {
  @override
  _RefundList2ViewState createState() => _RefundList2ViewState();
}

class _RefundList2ViewState extends State<RefundList2View> {
  List<Refund> refunds = [];
  List<Refund> selectedItems = [];
  Map<String, List<Refund>> groupedRefunds = {};
  String iadeNedeni = "";
  String _aciklama = '';
  double toplam = 0;
  String _searchQuery = '';
List<String> urunAdlariUnique=[];
  // List<String> _iadeNedenleri = [
  //   'Short Item',
  //   'Misdelivery (Useful)',
  //   'Refused (Useful)',
  //   'Other (Useful)',
  //   'Trial Returned (Useful)',
  //   'Short Dated (Useless)',
  //   'Price Difference',
  //   'Expired (Useless)',
  //   'Damaged (Useless)',
  //   'Faulty Pack (Useless)',
  //   'Others (Useless)',
  //   'Trial Returned (Useless)',
  // ];

  String _selectedIadeNedeni = "";

  DateTime _selectedDate = DateTime.now();
  final fisNo =
      'MBL${DateTime.now().year % 100}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}${(Random().nextInt(900) + 100)}';

  List<ProductModel> _products = [];
  Map<String, int> _quantities = {}; // stokKodu -> miktar
  Map<String, double> _customPrices = {}; // stokKodu -> custom fiyat

  @override
  void initState() {
    super.initState();
    fetchData();
    loadProducts();
  }
Future<void> fetchData() async {
  final refundRepository = Provider.of<RefundRepository>(context, listen: false);
  final musteriProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
  final carikod = musteriProvider.selectedCustomer?.kod ?? '';
  final fetched = await refundRepository.fetchRefunds(carikod);
  print(fetched);
  setState(() {
    refunds = fetched;
   urunAdlariUnique = refunds.map((e) => e.urunAdi).toSet().toList();
print("aaaaaaaaaaaaa $urunAdlariUnique");
    groupedRefunds = _groupRefundsByFisNo(fetched);
  });
}

Map<String, List<Refund>> _groupRefundsByFisNo(List<Refund> items) {
  final Map<String, List<Refund>> grouped = {};
  for (var item in items) {
    grouped.putIfAbsent(item.fisNo, () => []).add(item);
  }
  return grouped;
}

  Future<void> loadProducts() async {
    DatabaseHelper dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

    final result = await db.query('Product', where: 'aktif = ?', whereArgs: [1]);
    setState(() {
      _products = result.map((e) => ProductModel.fromMap(e)).toList();
    });
  }

void printCartContents() {
  print("=== Sepet İçeriği ===");
  _quantities.forEach((stokKodu, miktar) {
    final product = _products.firstWhere(
      (p) => p.stokKodu == stokKodu,
    );
    final urunAdi = product.urunAdi;
    final fiyat = _customPrices[stokKodu] ?? double.tryParse(product.adetFiyati) ?? 0.0;
    final toplamTutar = fiyat * miktar;
    print("Ürün: $urunAdi | Stok: $stokKodu | Miktar: $miktar | Fiyat: ${fiyat.toStringAsFixed(2)} | Toplam: ${toplamTutar.toStringAsFixed(2)}");
  });
  print("=====================");
  print("Toplam Tutar: ${toplam.toStringAsFixed(2)} ");
}

void updateTotal() {
  double newTotal = 0.0;
  _quantities.forEach((stokKodu, miktar) {
    final product = _products.firstWhere(
      (p) => p.stokKodu == stokKodu
    );
    final fiyat = _customPrices[stokKodu] ?? double.tryParse(product.adetFiyati) ?? 0.0;
    newTotal += fiyat * miktar;
  });
  setState(() {
    toplam = newTotal;
  });
}


  void addToCart(String stokKodu, double fiyat) {
    setState(() {
      _quantities[stokKodu] = (_quantities[stokKodu] ?? 0) + 1;
     updateTotal();
    });printCartContents();
  }

  void removeFromCart(String stokKodu, double fiyat) {
    setState(() {
      if ((_quantities[stokKodu] ?? 0) > 0) {
        _quantities[stokKodu] = _quantities[stokKodu]! - 1;
        if (_quantities[stokKodu] == 0) {
          _quantities.remove(stokKodu);
        }
     updateTotal();
      }
    });printCartContents();
  }

  void updateCustomPrice(String stokKodu, String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      setState(() {
        _customPrices[stokKodu] = parsed;
      });
    }
  }

  List<ProductModel> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final words = _searchQuery.toLowerCase().split(' ');
    return _products.where((p) {
      final text = (p.urunAdi + ' ' + p.stokKodu).toLowerCase();
      return words.every((w) => text.contains(w));
    }).toList();
  }

  void sendRefundItems() async {
    final refundRepository = Provider.of<RefundRepository>(context, listen: false);
    final musteriProvider = Provider.of<SalesCustomerProvider>(context, listen: false);
    String kod = musteriProvider.selectedCustomer?.kod ?? "TURAN";
    final selectedItems = _products.where((product) {
      final miktar = _quantities[product.stokKodu] ?? 0;
      return miktar > 0;
    }).map((product) {
      final miktar = _quantities[product.stokKodu]!;
      final fiyat = _customPrices[product.stokKodu] ?? double.tryParse(product.adetFiyati) ?? 0;
      final vat = product.vat;
      return RefundItemModel(
        stokKodu: product.stokKodu,
        urunAdi: product.urunAdi,
        miktar: miktar,
        birimFiyat: fiyat,
        toplamTutar: miktar * fiyat,
        vat: vat,
        birimTipi: product.birim1,
        durum: "1",
        urunBarcode: product.barcode1,
        iskonto: 0,
        aciklama: ""
      );
    }).toList();

    RefundFisModel fisModel = RefundFisModel(
      fisNo: fisNo,
      aciklama: _aciklama,
      iadeNedeni: _selectedIadeNedeni,
      fistarihi: DateFormat('dd.MM.yyyy').format(_selectedDate),
      musteriId: kod,
      toplamtutar: toplam,
      status: 1,
    );

    RefundSendModel refundSendModel = RefundSendModel(fis: fisModel, satirlar: selectedItems);
    if (selectedItems.isNotEmpty) {
      await refundRepository.sendRefund(refundSendModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final musteri = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    return Scaffold(
      appBar: AppBar(title: Text('Refund List')),
      body: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [
            if (musteri != null)
              ListTile(
                title: Text(musteri.unvan ?? ''),
              ),
            Text("Return No: $fisNo"),
            Row(
              children: [
                Text("Date: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}"),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Text("Choose Date"),
                )
              ],
            ),

  //           TextField(
  //             onChanged: (val) => setState(() => _aciklama = val),
  //             decoration: InputDecoration(hintText: "Enter a comment",    border: OutlineInputBorder(), // tüm kenarlarda çerçeve
  //   enabledBorder: OutlineInputBorder(
  //     borderSide: BorderSide(color: Colors.grey, width: 1),
  //   ),
  //   focusedBorder: OutlineInputBorder(
  //     borderSide: BorderSide(color: Colors.blue, width: 2),
  //   ),
  // ),
  //           ),            
            SizedBox(height: 1.h),

//             Divider(),            TextField(
//               decoration: InputDecoration(labelText: "Search Products",    border: OutlineInputBorder(), // tüm kenarlarda çerçeve
//     enabledBorder: OutlineInputBorder(
//       borderSide: BorderSide(color: Colors.grey, width: 1),
//     ),
//     focusedBorder: OutlineInputBorder(
//       borderSide: BorderSide(color: Colors.blue, width: 2),
//     ),
//   ),
//               onChanged: (val) => setState(() => _searchQuery = val),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredProducts.length,
//                 itemBuilder: (_, index) {
//                   final product = filteredProducts[index];
//                   final miktar = _quantities[product.stokKodu] ?? 0;
//                   final fiyat = _customPrices[product.stokKodu] ?? double.tryParse(product.adetFiyati ?? "0") ?? 0.0;
//                   final controller = TextEditingController(text: fiyat.toString());

//                   return ListTile(
//                     leading: FutureBuilder<String?>(
//   future: _getLocalImagePath(product.imsrc),
//   builder: (context, snapshot) {
//     if (snapshot.connectionState != ConnectionState.done) {
//       return SizedBox(
//         width: 20.w,
//         height: 25.w,
//         child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
//       );
//     }
//     if (!snapshot.hasData || snapshot.data == null || !File(snapshot.data!).existsSync()) {
//       return Container(
//         width: 20.w,
//         height: 20.w,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(4),
//           color: Colors.grey[300],
//         ),
//         child: Icon(Icons.shopping_bag, size: 16.w, color: Colors.grey[700]),
//       );
//     }

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(4),
//       child: Image.file(
//         File(snapshot.data!),
//         width: 20.w,
//         height: 20.w,
//         fit: BoxFit.cover,
//       ),
//     );
//   },
// ),
//                     title: Text(product.urunAdi),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextField(
//                           controller: controller,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(labelText: "Fiyat",),
//                           onSubmitted: (val) => updateCustomPrice(product.stokKodu, val),
//                         ),
//                       ],
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.remove),
//                           onPressed: () => removeFromCart(product.stokKodu, fiyat),
//                         ),
//                         Text(miktar.toString()),
//                         IconButton(
//                           icon: Icon(Icons.add),
//                           onPressed: () => addToCart(product.stokKodu, fiyat),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
Divider(),
            SizedBox(
  width: 90.w,
  height: 8.h,
  child: ElevatedButton(
    onPressed: (){
          RefundFisModel fisModel = RefundFisModel(
      fisNo: fisNo,
      aciklama: _aciklama,
      iadeNedeni: _selectedIadeNedeni,
      fistarihi: DateFormat('dd.MM.yyyy').format(_selectedDate),
      musteriId: musteri!.kod!,
      toplamtutar: toplam,
      status: 1,
    );
      Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RefundCartView(refundProductNames: urunAdlariUnique,fisModel:fisModel,refunds: refunds,)),
          );},
          //sendRefundItems
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      textStyle: TextStyle(fontSize: 18.sp),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.w),
      ),
    ),
    child: Text("Choose Products", style: TextStyle(fontSize: 20.sp)),
  ),
),

          ],
        ),
      ),
    );
  }

  // void _showIadeNedeniSecimi() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) {
  //       return Container(
  //         padding: EdgeInsets.all(16),
  //         child: ListView(
  //           children: _iadeNedenleri.map((neden) {
  //             return RadioListTile<String>(
  //               title: Text(neden),
  //               value: neden,
  //               groupValue: _selectedIadeNedeni,
  //               onChanged: (value) {
  //                 setState(() => _selectedIadeNedeni = value ?? "");
  //                 Navigator.pop(context);
  //               },
  //             );
  //           }).toList(),
  //         ),
  //       );
  //     },
  //   );
  // }
}

// NOT: Refund, ProductModel, RefundItemModel, RefundSendModel, RefundFisModel vs. modellerin tanımı ve diğer controller dosyaları projede mevcut olmalı.
