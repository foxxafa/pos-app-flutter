import 'package:flutter/material.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/refunds/presentation/screens/refundlist2_view.dart';
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
    final activityRepository = Provider.of<ActivityRepository>(context, listen: false);
    final allActivities = await activityRepository.loadActivities();
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
      appBar: AppBar(
        title: const Text("Refunds"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _refundActivities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "No refunds for this customer",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(2.h),
              itemCount: _refundActivities.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
              itemBuilder: (context, index) {
                final activity = _refundActivities[index];
                final parsed = parseActivity(activity);
                return _buildRefundCard(context, parsed);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RefundList2View()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Refund'),
      ),
    );
  }

  Widget _buildRefundCard(BuildContext context, Map<String, String> parsed) {
    final status = parsed['Status'] ?? '';
    final isCompleted = status.toLowerCase() == 'completed';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Refund #${parsed['No'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 3.h, thickness: 1),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'Date',
              value: parsed['Date'] ?? 'N/A',
            ),
            SizedBox(height: 1.h),
            _buildInfoRow(
              context,
              icon: Icons.account_balance_wallet,
              label: 'Total Amount',
              value: parsed['Total Amount'] ?? '0.00',
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
