import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StatementScreen extends StatelessWidget {
  const StatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> statementData = [
      {
        'date': '2025-06-01',
        'description': 'Payment Received',
        'total': 250.00,
        'no': 'TXN001'
      },
      {
        'date': '2025-06-02',
        'description': 'Purchase',
        'total': -75.00,
        'no': 'TXN002'
      },
      {
        'date': '2025-06-03',
        'description': 'Credit Note',
        'total': 20.00,
        'no': 'TXN003'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statement',
          style: TextStyle(fontSize: 19.sp),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(1.h),
        child: SizedBox(
          width: 100.w,
          height: 100.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 100.w),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[300]),
                  columnSpacing: 8.w,
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: Colors.black,
                  ),
                  dataTextStyle: TextStyle(fontSize: 13.sp),
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('No')),
                  ],
                  rows: statementData.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['date'])),
                      DataCell(Text(item['description'])),
                      DataCell(Text(item['total'].toStringAsFixed(2))),
                      DataCell(Text(item['no'])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
