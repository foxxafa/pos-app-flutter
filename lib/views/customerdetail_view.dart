import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/models/customer_balance.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/theme/app_theme.dart';

class CustomerDetailView extends StatelessWidget {
  const CustomerDetailView({Key? key}) : super(key: key);

  Future<CustomerBalanceModel?> loadCustomerDetail(String customerCode) async {

    DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final result = await db.query(
      'CustomerBalance',
      where: 'kod = ?',
      whereArgs: [customerCode],
    );
    // Database açık kalacak - App Inspector için

    if (result.isNotEmpty) {
      return CustomerBalanceModel(
        unvan: result[0]['unvan'] as String?,
        vergiNo: result[0]['vergiNo'] as String?,
        vergiDairesi: result[0]['vergiDairesi'] as String?,
        adres: result[0]['adres'] as String?,
        telefon: result[0]['telefon'] as String?,
        email: result[0]['email'] as String?,
        kod: result[0]['kod'] as String?,
        postcode: result[0]['postcode'] as String?,
        city: result[0]['city'] as String?,
        contact: result[0]['contact'] as String?,
        mobile: result[0]['mobile'] as String?,
        bakiye: result[0]['bakiye'] as String?,
      );
    } else {
      return null;
    }
  }

  Future<void> launchGoogleMapsWithUKPostcode(String postcode) async {
    final query = Uri.encodeComponent('$postcode, United Kingdom');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Map could not be opened: $e');
    }
  }

  Future<void> launchGoogleMapsQuery(String queryText) async {
    final query = Uri.encodeComponent(queryText);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Map could not be opened: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }

  Future<void> _sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value, {VoidCallback? onTap, IconData? icon}) {
    final theme = Theme.of(context);
    final hasValue = value != null && value.isNotEmpty && value != '-';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: hasValue ? onTap : null,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 4.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        hasValue ? value : 'customers.not_provided'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                            ? (onTap != null ? theme.colorScheme.primary : null)
                            : Colors.grey[400],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasValue && onTap != null) ...[
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 4.w,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerCode = Provider.of<SalesCustomerProvider>(context, listen: false)
        .selectedCustomer!
        .kod;

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('customer_menu.customer_detail'.tr()),
      ),
      body: FutureBuilder<CustomerBalanceModel?>(
        future: loadCustomerDetail(customerCode ?? "TURAN"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
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
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 20.w,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Customer not found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final customer = snapshot.data!;
          return Column(
            children: [
              // Customer Info Card (same style as customer menu)
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(4.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
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
                      'Company Name',
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

              // Details List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  children: [
                    _buildDetailRow(
                      context,
                      'Customer Code',
                      customer.kod,
                      icon: Icons.badge,
                      onTap: customer.kod != null
                          ? () {
                              Clipboard.setData(ClipboardData(text: customer.kod!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Customer code copied to clipboard')),
                              );
                            }
                          : null,
                    ),
                    _buildDetailRow(
                      context,
                      'customers.phone'.tr(),
                      customer.telefon,
                      icon: Icons.phone,
                      onTap: customer.telefon != null
                          ? () => _makePhoneCall(customer.telefon!)
                          : null,
                    ),
                    _buildDetailRow(
                      context,
                      'Mobile',
                      customer.mobile,
                      icon: Icons.smartphone,
                      onTap: customer.mobile != null
                          ? () => _makePhoneCall(customer.mobile!)
                          : null,
                    ),
                    _buildDetailRow(
                      context,
                      'customers.email'.tr(),
                      customer.email,
                      icon: Icons.email,
                      onTap: customer.email != null
                          ? () => _sendEmail(customer.email!)
                          : null,
                    ),
                    _buildDetailRow(
                      context,
                      'customers.address'.tr(),
                      customer.adres,
                      icon: Icons.location_on,
                      onTap: customer.adres != null
                          ? () => launchGoogleMapsQuery(customer.adres!)
                          : null,
                    ),
                    _buildDetailRow(
                      context,
                      'Postcode',
                      customer.postcode,
                      icon: Icons.map,
                      onTap: customer.postcode != null
                          ? () => launchGoogleMapsWithUKPostcode(customer.postcode!)
                          : null,
                    ),
                    _buildDetailRow(
                      context,
                      'City',
                      customer.city,
                      icon: Icons.location_city,
                    ),
                    _buildDetailRow(
                      context,
                      'Contact Person',
                      customer.contact,
                      icon: Icons.person,
                    ),
                    _buildDetailRow(
                      context,
                      'Tax Number',
                      customer.vergiNo,
                      icon: Icons.receipt_long,
                    ),
                    _buildDetailRow(
                      context,
                      'Tax Office',
                      customer.vergiDairesi,
                      icon: Icons.account_balance,
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<CustomerBalanceModel?>(
        future: loadCustomerDetail(customerCode ?? "TURAN"),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final customer = snapshot.data!;
            final balance = customer.bakiye ?? '0.00';
            final balanceValue = double.tryParse(balance) ?? 0.0;

            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Text(
                  '${'customer_menu.balance_label'.tr()} £${balanceValue.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}