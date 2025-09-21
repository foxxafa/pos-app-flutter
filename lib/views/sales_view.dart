import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/controllers/customerbalance_controller.dart';
import 'package:pos_app/controllers/database_helper.dart';
import 'package:pos_app/models/customer_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/cart_provider_refund.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';

import 'package:pos_app/views/customer_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:pos_app/core/theme/app_theme.dart';

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
        SnackBar(
          content: Text('customers.sync_data_first'.tr()),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('customers.title'.tr()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MenuView()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: EdgeInsets.all(3.w),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'customers.search_placeholder'.tr(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Customer List
          Expanded(
            child: _filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 20.w,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'customers.no_customers'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'customers.no_customers_subtitle'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 10.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = _filteredSales[index];
                      final isExpanded = (_expandedStates.length > index)
                          ? _expandedStates[index]
                          : false;

                      return Card(
                        margin: EdgeInsets.only(bottom: 1.h),
                        child: Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openDetails(sale),
                                child: Container(
                                  padding: EdgeInsets.all(3.w),
                                  child: Row(
                                    children: [

                                      // Customer Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sale['Unvan'] ?? 'customers.unknown_customer'.tr(),
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 0.5.h),
                                            Row(
                                              children: [
                                                Text(
                                                  sale['Kod'] ?? 'customers.no_code'.tr(),
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(width: 2.w),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 2.w,
                                                    vertical: 0.2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: sale['Aktif'] == 1
                                                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                                                        : AppTheme.errorColor.withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    sale['Aktif'] == 1
                                                        ? 'customers.active'.tr()
                                                        : 'customers.inactive'.tr(),
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: sale['Aktif'] == 1
                                                          ? AppTheme.accentColor
                                                          : AppTheme.errorColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Expand Button
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() {
                                            if (_expandedStates.length >
                                                index) {
                                              _expandedStates[index] =
                                                  !_expandedStates[index];
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            size: 6.w,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Genişletilmiş Detaylar
                            if (isExpanded)
                              Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBackgroundColor,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      Icons.phone,
                                      'customers.phone'.tr(),
                                      sale['Telefon'] ?? 'customers.not_provided'.tr(),
                                    ),
                                    SizedBox(height: 2.h),
                                    _buildDetailRow(
                                      Icons.location_on,
                                      'customers.address'.tr(),
                                      sale['Adres'] ?? 'customers.not_provided'.tr(),
                                    ),
                                    SizedBox(height: 2.h),
                                    _buildDetailRow(
                                      Icons.email,
                                      'customers.email'.tr(),
                                      sale['Email'] ?? 'customers.not_provided'.tr(),
                                    ),
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 4.w,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
