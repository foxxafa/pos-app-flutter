import 'package:flutter/material.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/views/expandabletext_widget.dart';
import 'package:pos_app/views/refundlist2_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class RefundActivityView extends StatefulWidget {
  const RefundActivityView({Key? key}) : super(key: key);

  @override
  State<RefundActivityView> createState() => _RefundActivityViewState();
}

class _RefundActivityViewState extends State<RefundActivityView> {
  List<String> _refundActivities = [];

  @override
  void initState() {
    super.initState();
    _loadRefundActivities();
  }

  Future<void> _loadRefundActivities() async {
    final allActivities = await RecentActivityController.loadActivities();
    final customer =
        Provider.of<SalesCustomerProvider>(
          context,
          listen: false,
        ).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _refundActivities = [];
      });
      return;
    }

    final filtered =
        allActivities.where((activity) {
          return activity.contains("Return Receipt") &&
              activity.contains("$customerCode");
        }).toList();

    if (filtered.isNotEmpty) {
      print("First refund activity: ${filtered.first}");
    } else {
      print("No refund activities found.");
    }

    setState(() {
      _refundActivities = filtered;
    });
  }

  // Basit parser, key:value satırlarından map çıkarır
  Map<String, String> parseActivity(String activity) {
    final Map<String, String> data = {};
    final lines = activity.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final splitIndex = line.indexOf(':');
      if (splitIndex == -1) continue;
      final key = line.substring(0, splitIndex).trim();
      final value = line.substring(splitIndex + 1).trim();
      data[key] = value;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("-Refunds-")),
      body: Padding(
  padding: EdgeInsets.all(3.h),
  child: _refundActivities.isEmpty
      ? Center(
          child: Text(
            "No refunds for this customer.",
            style: TextStyle(fontSize: 18.sp),
          ),
        )
      : Column(
          children: [
            Expanded(
              child: DataTable(
                headingRowHeight: 6.h,
                dataRowHeight: 7.h,
                columnSpacing: 6.w, // Daha dar aralık
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _refundActivities.map((activity) {
                  final parsed = parseActivity(activity);
                  return DataRow(
                    cells: [
                      DataCell(Text(parsed['Date'] ?? '')),
                      DataCell(Text(parsed['No'] ?? '')),
                      DataCell(Text(parsed['Total Amount'] ?? '')),
                      DataCell(Text(parsed['Status'] ?? '')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
),

      floatingActionButton: SizedBox(
        width: 20.w, // Genişlik
        height: 20.w, // Yükseklik
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RefundList2View()),
            );
          },
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(Icons.add, size: 10.w),
        ),
      ),
    );
  }
}
