import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:provider/provider.dart';

class StatementScreen extends StatelessWidget {
  const StatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;

    // Sample data - Bu gerçek veri olarak değiştirilecek
    final List<Map<String, dynamic>> statementData = [
      {
        'date': '2025-06-01',
        'description': 'statement.payment_received'.tr(),
        'total': 250.00,
        'no': 'TXN001'
      },
      {
        'date': '2025-06-02',
        'description': 'statement.purchase'.tr(),
        'total': -75.00,
        'no': 'TXN002'
      },
      {
        'date': '2025-06-03',
        'description': 'statement.credit_note'.tr(),
        'total': 20.00,
        'no': 'TXN003'
      },
      {
        'date': '2025-06-04',
        'description': 'statement.purchase'.tr(),
        'total': -125.50,
        'no': 'TXN004'
      },
      {
        'date': '2025-06-05',
        'description': 'statement.payment_received'.tr(),
        'total': 300.00,
        'no': 'TXN005'
      },
    ];

    // Calculate total balance
    double totalBalance = statementData.fold(0.0, (sum, item) => sum + item['total']);

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('customer_menu.statement'.tr()),
      ),
      body: Column(
        children: [
          // Customer Info Card (same style as customer menu)
          if (customer != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(4.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'customer_menu.customer_label'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    customer.unvan ?? 'customers.unknown_customer'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          // Transactions List
          Expanded(
            child: statementData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 20.w,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'statement.no_transactions'.tr(),
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
                    itemCount: statementData.length,
                    itemBuilder: (context, index) {
                      final transaction = statementData[index];
                      final amount = transaction['total'] as double;
                      final isPositive = amount >= 0;
                      final date = DateTime.parse(transaction['date']);
                      final dateFormat = DateFormat('dd.MM.yyyy');

                      return _buildTransactionCard(
                        context,
                        date: dateFormat.format(date),
                        description: transaction['description'],
                        amount: amount,
                        transactionNo: transaction['no'],
                        isPositive: isPositive,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: totalBalance >= 0 ? Colors.green : Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Text(
            '${'statement.total_balance'.tr()}: £${totalBalance.toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context, {
    required String date,
    required String description,
    required double amount,
    required String transactionNo,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            // Amount circle with color indication
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: isPositive ? Colors.green : Colors.red,
                size: 6.w,
              ),
            ),
            SizedBox(width: 4.w),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description and amount row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}£${amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),

                  // Date and transaction number row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        transactionNo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
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