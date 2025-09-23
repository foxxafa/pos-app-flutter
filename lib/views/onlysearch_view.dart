import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:sizer/sizer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product_model.dart';
import '../providers/cartcustomer_provider.dart';
import 'dart:io';

class ProductControlView extends StatefulWidget {
  const ProductControlView({super.key});

  @override
  State<ProductControlView> createState() => _ProductControlViewState();
}

class _ProductControlViewState extends State<ProductControlView> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  final Map<String, bool> _isBoxMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, int> _iskontoMap = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
    
  }

  Future<void> _loadProducts() async {
    final raw = await DatabaseHelper().getAll("Product");
    final products = raw.map((e) => ProductModel.fromMap(e)).toList();
    setState(() {
      _allProducts = products;
      _filteredProducts = products.take(1000).toList();

      for (var product in products) {
        final key = product.stokKodu;
        _isBoxMap[key] = false;
        _quantityMap[key] = 0;
        _iskontoMap[key] = 0;
      }
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    final filtered =
        _allProducts.where((product) {
          final name = product.urunAdi.toLowerCase();
          final barcodes = [
            product.barcode1,
            product.barcode2,
            product.barcode3,
            product.barcode4,
          ].map((b) => b.toLowerCase());

          final matchesName = name.contains(query);
          final matchesBarcode = barcodes.any((b) => b.contains(query));
          return matchesName || matchesBarcode;
        }).toList();

    setState(() {
      _filteredProducts = filtered.take(50).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _onBarcodeScanned(String barcode) {
    _searchController.text = barcode;
    _filterProducts();
    Navigator.of(context).pop(); // Kamera sayfasını kapat
  }

  Future<void> _openBarcodeScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(onScanned: _onBarcodeScanned),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer =
        Provider.of<SalesCustomerProvider>(context).selectedCustomer;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Product Control", style: TextStyle(fontSize: 20.sp)),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, size: 6.w),
            tooltip: 'Scan Barcode',
            onPressed: _openBarcodeScanner,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer == null)
              const Text("No customer selected.")
            else
              Text("${customer.unvan}", style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 3.h),
            TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 18.sp),
              decoration: InputDecoration(
                labelText: 'Search by NAME or BARCODE',
                labelStyle: TextStyle(fontSize: 16.sp),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.search, size: 6.w),
                suffixIcon:
                    _searchController.text.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        ),
              ),
              onChanged: (_) => _filterProducts(),
            ),
            SizedBox(height: 2.h),
            _filteredProducts.isEmpty
                ? const Text("Press clear data + fully sync to get data.")
                : Expanded(
                  child: ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];

                      // sadece ListView.builder içindeki Card widget'ını aşağıdaki gibi değiştir:

return InkWell(
  onDoubleTap: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.urunAdi),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            product.imsrc == null
                ? Icon(Icons.shopping_bag, size: 40.w)
                : FutureBuilder<String?>(
                    future: () async {
                      try {
  final imsrc = product.imsrc;
  if (imsrc == null || imsrc.isEmpty) return null;

  final uri = Uri.parse(imsrc);
  final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  if (fileName == null) return null;

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$fileName';

  final file = File(filePath);
  return await file.exists() ? filePath : null;
} catch (e) {
  return null;
}

                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState !=
                          ConnectionState.done) {
                        return SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Icon(Icons.shopping_bag, size: 40.w);
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(snapshot.data!),
                          width: 40.w,
                          height: 40.w,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
            SizedBox(height: 2.h),
            // Text("Barcodes: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}"),
            Text("Unit Price: ${product.adetFiyati}"),
            Text("Box Price: ${product.kutuFiyati}"),
            // Text("Active: ${product.aktif == 1 ? 'YES' : 'NO'}"),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  },
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2.w),
    ),
    margin: EdgeInsets.symmetric(vertical: 1.h),
    child: Padding(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          
        
              product.imsrc == null
                  ? Icon(Icons.shopping_bag, size: 30.w) // büyüttüm
                  : FutureBuilder<String?>(
                      future: () async {
                        try {
  final imsrc = product.imsrc;
  if (imsrc == null || imsrc.isEmpty) return null;

  final uri = Uri.parse(imsrc);
  final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  if (fileName == null) return null;

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$fileName';

  final file = File(filePath);
  return await file.exists() ? filePath : null;
} catch (e) {
  return null;
}

                      }(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState !=
                            ConnectionState.done) {
                          return SizedBox(
                            width: 12.w,
                            height: 12.w,
                            child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Icon(
                            Icons.shopping_bag,
                            size: 20.w, // büyüttüm
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                          child: Image.file(
                            File(snapshot.data!),
                            width: 30.w,  // büyüttüm
                            height: 30.w, // büyüttüm
                            fit: BoxFit.contain, // tam görünmesi için contain
                          ),
                        );
                      },
                    ),

              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.urunAdi,
                      style: TextStyle(
                        fontSize: 20.sp, // büyüttüm
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    // Text(
                    //   "Barcodes: ${[product.barcode1, product.barcode2, product.barcode3, product.barcode4].where((b) => b != null && b.trim().isNotEmpty).join(', ')}",
                    //   style: TextStyle(fontSize: 13.sp), // büyüttüm
                    // ),
                    Text(
                      "Unit Price: ${product.adetFiyati}",
                      style: TextStyle(fontSize: 20.sp), // büyüttüm
                    ),
                    Text(
                      "Box Price: ${product.kutuFiyati}",
                      style: TextStyle(fontSize: 20.sp), // büyüttüm
                    ),
                    // Text(
                    //   "Active: ${product.aktif == 1 ? 'YES' : 'NO'}",
                    //   style: TextStyle(fontSize: 13.sp), // büyüttüm
                    // ),
                  ],
                ),
              ),
            ],
          ),
          
        ],
      ),
    ),
  ),
);

                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String barcode) onScanned;

  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isScanning = true;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _isScanning = false;
      widget.onScanned(rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: MobileScanner(controller: cameraController, onDetect: _onDetect),
    );
  }
}


