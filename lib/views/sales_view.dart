import 'package:flutter/material.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/controllers/database_helper.dart';
import 'package:pos_app/models/customer_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/cart_provider_refund.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/views/cart_view.dart';
import 'package:pos_app/views/customer_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/views/menu_view.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allSales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  late List<bool> _expandedStates;

  @override
  void initState() {
    super.initState();
    _expandedStates = [];
    _loadSales();
    _searchController.addListener(_filterSales);
  }

  Future<void> _loadSales() async {
    try {
      final sales = await DatabaseHelper().getAll('Customer');
      setState(() {
        _allSales = sales;
        _filteredSales = sales.take(100).toList();
        _expandedStates = List.generate(_filteredSales.length, (_) => false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please download data first.\nGo to MENU>SYNC>INITIAL SETUP.',
          ),
        ),
      );
    }
  }

  void _filterSales() {
    final query = _searchController.text.toLowerCase();
    final filtered =
        _allSales.where((sale) {
          final title = sale['Unvan']?.toString().toLowerCase() ?? '';
          return title.contains(query);
        }).toList();

    setState(() {
      _filteredSales = filtered.take(50).toList();
      _expandedStates = List.generate(_filteredSales.length, (_) => false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetails(Map<String, dynamic> sale) async {
    final selectedCustomer = CustomerModel.fromMap(sale);
    Provider.of<SalesCustomerProvider>(
      context,
      listen: false,
    ).setCustomer(selectedCustomer);

    final controller = CustomerBalanceController();
    final customer = await controller.getCustomerByUnvan(
      selectedCustomer.unvan ?? "TURAN",
    );
    final bakiye = customer?.bakiye ?? "0.0";

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartRefundProvider = Provider.of<RCartProvider>(
      context,
      listen: false,
    );
    await cartProvider.loadCartFromDatabase(selectedCustomer.kod ?? "TURAN");
    await cartRefundProvider.loadCartRefundFromDatabase(
      selectedCustomer.kod ?? "TURAN",
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerView(bakiye: bakiye)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.home, size: 28.sp),
          tooltip: 'Return to Menu',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MenuView()),
              (route) => false,
            );
          },
        ),
        title: Text('CUSTOMERS', style: TextStyle(fontSize: 28.sp)),
      ),
      body: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 22.sp),
              decoration: InputDecoration(
                labelText: 'Search by TITLE',
                labelStyle: TextStyle(fontSize: 20.sp),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.search, size: 8.w),
              ),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child:
                  _filteredSales.isEmpty
                      ? Center(
                        child: Text(
                          'No customer found.',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = _filteredSales[index];
                          final isExpanded =
                              (_expandedStates.length > index)
                                  ? _expandedStates[index]
                                  : false;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                    vertical: 1.h,
                                  ),
                                  title: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey, // Border rengi
                                        width: 1.5, // Border kalınlığı
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // İstersen köşeleri yuvarla
                                    ),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _openDetails(sale),
                                      child: Row(
                                        children: [
                                          // SizedBox(
                                          //   width: 15.w,
                                          //   child: Text(
                                          //     sale['Kod'] ?? '-',
                                          //     style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
                                          //     overflow: TextOverflow.ellipsis,
                                          //   ),
                                          // ),
                                          // SizedBox(width: 2.w),
                                          Expanded(
                                            child: Text(
                                              sale['Unvan'] ?? '-',
                                              style: TextStyle(fontSize: 19.sp),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 28.sp,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_expandedStates.length > index) {
                                          _expandedStates[index] =
                                              !_expandedStates[index];
                                        }
                                      });
                                    },
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 0.5.h,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kod: ${sale['Kod'] ?? "-"}',
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                        SizedBox(height: 0.5.h),

                                        Text(
                                          'Phone: ${sale['Telefon'] ?? "-"}',
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                        SizedBox(height: 0.5.h),
                                        Text(
                                          'Address: ${sale['Adres'] ?? "-"}',
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                        SizedBox(height: 0.5.h),
                                        Text(
                                          'Active: ${sale['Aktif'] == 1 ? "YES" : "NO"}',
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                        SizedBox(height: 1.h),
                                      ],
                                    ),
                                  ),
                              ],
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
