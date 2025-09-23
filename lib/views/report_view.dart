import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/models/customer_balance.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/theme/app_theme.dart';

class ReportView extends StatefulWidget {
  const ReportView({Key? key}) : super(key: key);

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  List<CustomerBalanceModel> _allCustomers = [];
  List<CustomerBalanceModel> _filteredCustomers = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllCustomerBalances();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((customer) {
        final kod = (customer.kod ?? "").toLowerCase();
        final unvan = (customer.unvan ?? "").toLowerCase();
        return kod.contains(query) || unvan.contains(query);
      }).toList();
    });
  }

  Future<void> loadAllCustomerBalances() async {
    setState(() => _isLoading = true);

    String databasesPath = await getDatabasesPath();
    String path = p.join(databasesPath, 'pos_database.db');

    final db = await openReadOnlyDatabase(path);
    final result = await db.query('CustomerBalance');
    await db.close();

    final customers = await compute(parseCustomerBalanceList, result);
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
      _isLoading = false;
    });
  }

  static List<CustomerBalanceModel> parseCustomerBalanceList(List<Map<String, Object?>> result) {
    return result.map((row) {
      return CustomerBalanceModel(
        kod: row['kod'] as String?,
        unvan: row['unvan'] as String?,
        bakiye: row['bakiye'] as String?,
      );
    }).toList();
  }


  Widget _buildCustomerCard(CustomerBalanceModel customer) {
    final theme = Theme.of(context);
    final balance = double.tryParse(customer.bakiye ?? '0') ?? 0.0;
    final isPositive = balance >= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            // Balance indicator circle
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
                size: 4.w,
              ),
            ),
            SizedBox(width: 3.w),

            // Customer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer name and balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          customer.unvan ?? 'customers.unknown_customer'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '£${balance.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),

                  // Customer code
                  Text(
                    customer.kod ?? 'customers.no_code'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('reports.title'.tr()),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'reports.search_placeholder'.tr(),
                prefixIcon: Icon(Icons.search, size: 5.w),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 5.w),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 2.h),
                        Text(
                          'messages.loading'.tr(),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  )
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 20.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'reports.no_customers_found'.tr()
                                  : 'customers.no_customers'.tr(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          return _buildCustomerCard(_filteredCustomers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}