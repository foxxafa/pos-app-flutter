import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/features/reports/presentation/recentactivity_controller.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/transactions/presentation/screens/transaction_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class CollectionActivity extends StatefulWidget {
  const CollectionActivity({Key? key}) : super(key: key);

  @override
  State<CollectionActivity> createState() => _CollectionActivityState();
}

class _CollectionActivityState extends State<CollectionActivity> {
  List<String> _collectionActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollectionActivities();
    });
  }

  Future<void> _loadCollectionActivities() async {
    setState(() => _isLoading = true);

    final allActivities = await RecentActivityController.loadActivities();
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _collectionActivities = [];
        _isLoading = false;
      });
      return;
    }

    final filtered = allActivities.where((activity) {
      return activity.contains("Collect") && activity.contains(customerCode!);
    }).toList();

    setState(() {
      _collectionActivities = filtered;
      _isLoading = false;
    });
  }

  List<CollectionItem> parseCollectionActivities(List<String> activities) {
    List<CollectionItem> collections = [];

    for (var activity in activities) {
      // Parse collection activity format:
      // Collected
      // Code:40499R
      // Amount:1.0
      // Desc:test2
      // Payment:Credit Card

      final lines = activity.split('\n');

      String? amount;
      String? description;
      String? paymentType;

      for (var line in lines) {
        line = line.trim();
        if (line.startsWith('Code:')) {
          // customerCode = line.split(':').last.trim();
        } else if (line.startsWith('Amount:')) {
          amount = line.split(':').last.trim();
        } else if (line.startsWith('Desc:')) {
          description = line.split(':').last.trim();
        } else if (line.startsWith('Payment:')) {
          paymentType = line.split(':').last.trim();
        }
      }

      if (amount != null) {
        collections.add(CollectionItem(
          documentNo: 'MO${DateTime.now().millisecondsSinceEpoch}', // Generate a temp document number
          date: DateTime.now().toString().split(' ')[0], // Today's date
          amount: amount,
          paymentType: paymentType ?? 'Unknown', // Use the payment type from activity log
          description: description ?? '',
        ));
      }
    }

    return collections;
  }

  Widget _buildCollectionCard(CollectionItem collection) {
    final theme = Theme.of(context);
    final amount = double.tryParse(collection.amount.replaceAll('£', '').trim()) ?? 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show collection details in a dialog
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'collection.details'.tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('collection.document_no'.tr(), collection.documentNo),
                  SizedBox(height: 1.h),
                  _buildDetailRow('collection.date'.tr(), collection.date),
                  SizedBox(height: 1.h),
                  _buildDetailRow('collection.amount'.tr(), '£${amount.toStringAsFixed(2)}'),
                  SizedBox(height: 1.h),
                  _buildDetailRow('collection.payment_type'.tr(), collection.paymentType),
                  if (collection.description.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    _buildDetailRow('collection.description'.tr(), collection.description),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'common.close'.tr(),
                    style: TextStyle(color: AppTheme.lightPrimaryColor),
                  ),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payments,
                      color: Colors.green,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.documentNo != 'N/A'
                              ? collection.documentNo
                              : 'collection.no_document'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          collection.date,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '£${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: _getPaymentTypeColor(collection.paymentType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getPaymentTypeText(collection.paymentType),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: _getPaymentTypeColor(collection.paymentType),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (collection.description.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    collection.description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentTypeColor(String paymentType) {
    // All payment types use blue color for consistency
    return Colors.blue;
  }

  String _getPaymentTypeText(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'cash':
      case 'nakit':
        return 'collection.payment_cash'.tr();
      case 'credit card':
      case 'card':
      case 'kredi kartı':
        return 'collection.payment_card'.tr();
      case 'cheque':
      case 'check':
      case 'çek':
        return 'collection.payment_cheque'.tr();
      case 'bank':
      case 'banka':
        return 'collection.payment_bank'.tr();
      default:
        return paymentType;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsedCollections = parseCollectionActivities(_collectionActivities);

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('collection.title'.tr()),
        backgroundColor: AppTheme.lightPrimaryColor,
        foregroundColor: Colors.white,
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
          : parsedCollections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20.w,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'collection.no_collections'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'collection.create_new_hint'.tr(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCollectionActivities,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: parsedCollections.length,
                    itemBuilder: (context, index) {
                      return _buildCollectionCard(parsedCollections[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TransactionPage()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        child: Icon(
          Icons.add,
          size: 7.w,
          color: Colors.white,
        ),
      ),
    );
  }
}

class CollectionItem {
  final String documentNo;
  final String date;
  final String amount;
  final String paymentType;
  final String description;

  CollectionItem({
    required this.documentNo,
    required this.date,
    required this.amount,
    required this.paymentType,
    required this.description,
  });
}