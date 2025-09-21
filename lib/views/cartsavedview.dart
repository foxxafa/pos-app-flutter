import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class CartListPage extends StatefulWidget {
  const CartListPage({super.key});

  @override
  State<CartListPage> createState() => _CartListPageState();
}

class _CartListPageState extends State<CartListPage> {
  Map<String, List<Map<String, dynamic>>> groupedCarts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);

    // Get customer data from database first
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'pos_database.db');
    final db = await openDatabase(path);
    final customerRows = await db.query('Customer');
    final allItems = await db.query('cart_items'); // Get cart items directly

    // Group by customer
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in allItems) {
      // Get customer code/name from database
      final customerData = item['customerName']?.toString().trim();

      String displayName;
      if (customerData?.isEmpty ?? true) {
        displayName = 'saved_carts.unknown_customer'.tr();
      } else if (customerData == 'Unknown Customer') {
        displayName = 'saved_carts.unknown_customer'.tr();
      } else {
        // Check if it's already a customer name like "RELMA LTD (L)"
        if (customerData!.contains('(') && customerData.contains(')')) {
          // Already formatted as name, use as is
          displayName = customerData;
        } else {
          // Try to find customer by code to get the name
          final customer = customerRows.firstWhere(
            (c) => c['kod'] == customerData,
            orElse: () => {},
          );

          if (customer.isNotEmpty && customer['unvan'] != null) {
            // Show both name and code: "Customer Name (CODE123)"
            displayName = '${customer['unvan']} ($customerData)';
          } else {
            // If customer not found, just show the code
            displayName = customerData;
          }
        }
      }

      if (!grouped.containsKey(displayName)) {
        grouped[displayName] = [];
      }
      grouped[displayName]!.add(item);
    }

    await db.close();

    setState(() {
      groupedCarts = grouped;
      _isLoading = false;
    });
  }

  double _calculateCartTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (final item in items) {
      final quantity = (item['miktar'] is num)
          ? item['miktar'].toDouble()
          : double.tryParse(item['miktar'].toString()) ?? 0.0;
      final price = (item['birimFiyat'] is num)
          ? item['birimFiyat'].toDouble()
          : double.tryParse(item['birimFiyat'].toString()) ?? 0.0;
      total += quantity * price;
    }
    return total;
  }

  Widget _buildCustomerCard(String customerName, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    final totalAmount = _calculateCartTotal(items);
    final itemCount = items.length;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(4.w),
          childrenPadding: EdgeInsets.only(bottom: 2.h),
          leading: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightPrimaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart,
              color: AppTheme.lightPrimaryColor,
              size: 6.w,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${itemCount} ${'saved_carts.items'.tr()}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '£${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: items.map((item) => _buildCartItem(item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final quantity = (item['miktar'] is num)
        ? item['miktar'].toDouble()
        : double.tryParse(item['miktar'].toString()) ?? 0.0;
    final price = (item['birimFiyat'] is num)
        ? item['birimFiyat'].toDouble()
        : double.tryParse(item['birimFiyat'].toString()) ?? 0.0;
    final total = quantity * price;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.lightPrimaryColor,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['urunAdi'] ?? '-',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      '${'saved_carts.quantity'.tr()}: ${quantity.toInt()}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${'saved_carts.unit_price'.tr()}: £${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'saved_carts.total'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('saved_carts.title'.tr()),
        backgroundColor: AppTheme.lightPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCartItems,
            icon: Icon(Icons.refresh),
            tooltip: 'saved_carts.refresh'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.lightPrimaryColor,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'messages.loading'.tr(),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            )
          : groupedCarts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 20.w,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'saved_carts.no_carts'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'saved_carts.no_carts_hint'.tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCartItems,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: groupedCarts.length,
                    itemBuilder: (context, index) {
                      final customer = groupedCarts.keys.elementAt(index);
                      final items = groupedCarts[customer]!;
                      return _buildCustomerCard(customer, items);
                    },
                  ),
                ),
    );
  }
}