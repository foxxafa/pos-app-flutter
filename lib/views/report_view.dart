import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_app/models/customer_balance.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sizer/sizer.dart';

class ReportView extends StatefulWidget {
  const ReportView({Key? key}) : super(key: key);

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  List<CustomerBalanceModel> _allCustomers = [];
  List<CustomerBalanceModel> _filteredCustomers = [];
  TextEditingController _searchController = TextEditingController();

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
        final kod = customer.kod?.toLowerCase() ?? '';
        final unvan = customer.unvan?.toLowerCase() ?? '';
        return kod.contains(query) || unvan.contains(query);
      }).toList();
    });
  }

  Future<void> loadAllCustomerBalances() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'pos_database.db');

    final db = await openReadOnlyDatabase(path);
    final result = await db.query('CustomerBalance');print("DB CLOSE TIME 9");
    await db.close();

    final customers = await compute(parseCustomerBalanceList, result);
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
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

  TableRow buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.grey),
      children: [
        Padding(
          padding: EdgeInsets.all(1.h),
          child: Text("Code", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(1.h),
          child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(1.h),
          child: Text("Balance", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  TableRow buildDataRow(CustomerBalanceModel customer) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
          child: Text(customer.kod ?? "-"),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
          child: Text(
            customer.unvan ?? "-",
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
          child: Text(customer.bakiye ?? "-"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Report")),
      body: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: _filteredCustomers.isEmpty?
Center(
  child: SizedBox(
    height: 4.h,
    width: 4.h,
    child: const CircularProgressIndicator(),
  ),
)
                  : ListView(
                      children: [
                        Table(
                          columnWidths: {
                            0: FixedColumnWidth(20.w),
                            1: FixedColumnWidth(45.w),
                            2: FixedColumnWidth(25.w),
                          },
                          border: TableBorder.all(width: 0.5, color: Colors.grey),
                          children: [
                            buildHeaderRow(),
                            ..._filteredCustomers.map(buildDataRow).toList(),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
