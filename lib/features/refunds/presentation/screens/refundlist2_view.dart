import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:pos_app/features/products/domain/entities/product_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/refunds/presentation/screens/refundcart_view.dart';
import 'package:pos_app/features/refunds/presentation/providers/cart_provider_refund.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/utils/fisno_generator.dart';

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

  List<ProductModel> _products = [];
  Map<String, int> _quantities = {}; // stokKodu -> miktar
  Map<String, double> _customPrices = {}; // stokKodu -> custom fiyat

  // ✅ FisNo generated in initState
  String _currentFisNo = '';
  bool _isInitializing = true; // ✅ Track initialization state

  @override
  void initState() {
    super.initState();
    // ✅ Check for Load Refund scenario FIRST (before generating new fisNo)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeRefund();
      if (mounted) {
        setState(() {
          _isInitializing = false; // ✅ Initialization complete
        });
      }
    });
    // ❌ REMOVED: fetchData() - API isteği gereksiz ve 10s database lock'a sebep oluyor
    // Veriler zaten SyncAllRefunds() ile veritabanında var
    // fetchData();

    // ❌ REMOVED: loadProducts() - Ürünler RefundCartView açıldığında yüklenecek
    // RefundList2View sadece fisNo oluşturuyor, ürün seçimi henüz başlamadı
    // loadProducts();
  }

  /// ✅ NEW: Initialize refund - Handle both Load Refund and New Refund scenarios
  Future<void> _initializeRefund() async {
    try {
      final cartProvider = Provider.of<RCartProvider>(context, listen: false);

      // ✅ CRITICAL: Detect Load Refund scenario
      // If cart has items but fisNo is empty, this is a Load Refund case
      if (cartProvider.items.isNotEmpty && cartProvider.fisNo.isEmpty) {
        debugPrint('✅ Load Refund detected! Items: ${cartProvider.items.length}, fisNo: empty');

        // Save old fisNo for cleanup
        final eskiFisNo = cartProvider.eskiFisNo;
        debugPrint('   eskiFisNo: $eskiFisNo');

        // Generate NEW fisNo (CRITICAL: Always generate new fisNo on load)
        await _generateFisNo();

        // Set new fisNo to provider
        cartProvider.fisNo = _currentFisNo;
        debugPrint('   New fisNo generated: $_currentFisNo');

        // ❌ REMOVED: No need to save to database here - cart will save when items are added
        // Database save is expensive (10s lock) and cart is empty at this point anyway
        // await cartProvider.forceSaveToDatabase();
        // debugPrint('   ✅ Cart saved to database with new fisNo');

        // ✅ Delete old refund from queue by ID (more reliable than fisNo which can be empty)
        if (cartProvider.refundQueueId != null) {
          final dbHelper = DatabaseHelper();
          final db = await dbHelper.database;
          await db.delete('refund_queue', where: 'id = ?', whereArgs: [cartProvider.refundQueueId]);
          debugPrint('   ✅ Old refund deleted from queue (ID: ${cartProvider.refundQueueId})');

          // Clear temporary variables
          cartProvider.refundQueueId = null;
          cartProvider.eskiFisNo = '';
        }

        if (mounted) {
          setState(() {});
        }
        return;
      }

      // ✅ Normal case: Generate new fisNo for new refund
      await _generateFisNo();

      // ✅ CRITICAL: Set fisNo to provider (same as Order system)
      cartProvider.fisNo = _currentFisNo;
      debugPrint('✅ New refund initialized with fisNo: $_currentFisNo');

      // ❌ REMOVED: No need to save empty cart to database
      // Cart will auto-save when items are added (debounced)
      // await cartProvider.forceSaveToDatabase();
      // debugPrint('   ✅ Cart saved to database with fisNo');
    } catch (e) {
      debugPrint('⚠️ Error in _initializeRefund: $e');
      // Fallback: Generate fisNo anyway
      await _generateFisNo();

      // Set to provider even in error case
      try {
        final cartProvider = Provider.of<RCartProvider>(context, listen: false);
        if (cartProvider.fisNo.isEmpty) {
          cartProvider.fisNo = _currentFisNo;
        }
      } catch (providerError) {
        debugPrint('⚠️ Could not access provider: $providerError');
      }
    }
  }

  /// Generate unique fisNo for refund using FisNoGenerator
  Future<void> _generateFisNo() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final result = await db.query('Login', limit: 1);
      final int userId = result.isNotEmpty ? (result.first['id'] as int) : 1;

      // Generate fisNo (15 characters: MO + 13 digits)
      final fisNo = FisNoGenerator.generate(userId: userId);
      debugPrint('✅ Refund FisNo generated: $fisNo (UserID: $userId)');

      if (mounted) {
        setState(() {
          _currentFisNo = fisNo;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error generating refund fisNo: $e');
      // Fallback
      if (mounted) {
        setState(() {
          _currentFisNo = 'MO${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 17)}';
        });
      }
    }
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

  // ⚠️ DEPRECATED: This method is not used anymore
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
      fisNo: _currentFisNo,
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
      appBar: AppBar(
        title: Text('Refund List'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Customer Card
                if (musteri != null)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  musteri.unvan ?? '',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 2.h),

                // Return Info Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      children: [
                        // Return Number
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Theme.of(context).primaryColor,
                              size: 20.sp,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Return No:',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _currentFisNo,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h),
                        Divider(height: 1),
                        SizedBox(height: 2.h),

                        // Date Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 2.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Return Date',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
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
                              icon: Icon(Icons.edit_calendar, size: 18.sp),
                              label: Text('Change'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // Choose Products Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isInitializing ? null : () {
                      // ✅ CRITICAL: Set fisNo to provider before navigation (same as Order system)
                      final cartProvider = Provider.of<RCartProvider>(context, listen: false);
                      cartProvider.fisNo = _currentFisNo;
                      cartProvider.customerKod = musteri!.kod!;

                      RefundFisModel fisModel = RefundFisModel(
                        fisNo: _currentFisNo,
                        aciklama: _aciklama,
                        iadeNedeni: _selectedIadeNedeni,
                        fistarihi: DateFormat('dd.MM.yyyy').format(_selectedDate),
                        musteriId: musteri!.kod!,
                        toplamtutar: toplam,
                        status: 1,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RefundCartView(
                            refundProductNames: urunAdlariUnique,
                            fisModel: fisModel,
                            refunds: refunds,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 3.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 22.sp),
                        SizedBox(width: 3.w),
                        Text(
                          "Choose Products",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 2.h),
            ],
          ),
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
