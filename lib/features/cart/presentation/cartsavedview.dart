import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/services/pdf_service.dart';

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
    DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final customerRows = await db.query('CustomerBalance');

    // ✅ Sadece Place Order yapılmış siparişleri getir (isPlaced=1)
    // isPlaced=0 veya NULL: Henüz Place Order yapılmamış (Saved Carts'ta gösterilmez)
    // isPlaced=1: Place Order yapılmış (Saved Carts'ta görünür - read-only)
    final allItems = await db.query(
      'cart_items',
      where: 'isPlaced = ?',
      whereArgs: [1],
    );

    // Group by fisNo (order number)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in allItems) {
      // Get fisNo and customer info
      final fisNo = item['fisNo']?.toString().trim() ?? 'No Order Number';
      final customerData = item['customerName']?.toString().trim();

      String displayName;
      if (customerData?.isEmpty ?? true) {
        displayName = '$fisNo - ${'saved_carts.unknown_customer'.tr()}';
      } else if (customerData == 'Unknown Customer') {
        displayName = '$fisNo - ${'saved_carts.unknown_customer'.tr()}';
      } else {
        // Check if it's already a customer name like "RELMA LTD (L)"
        if (customerData!.contains('(') && customerData.contains(')')) {
          // Already formatted as name, use as is
          displayName = '$fisNo - $customerData';
        } else {
          // Try to find customer by code to get the name
          final customer = customerRows.firstWhere(
            (c) => c['kod'] == customerData,
            orElse: () => {},
          );

          if (customer.isNotEmpty && customer['unvan'] != null) {
            // Show fisNo + Customer Name (CODE)
            displayName = '$fisNo - ${customer['unvan']} ($customerData)';
          } else {
            // If customer not found, show fisNo + code
            displayName = '$fisNo - $customerData';
          }
        }
      }

      if (!grouped.containsKey(displayName)) {
        grouped[displayName] = [];
      }
      grouped[displayName]!.add(item);
    }

    // Database açık kalacak - App Inspector için

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
      final vat = (item['vat'] is num)
          ? item['vat'].toDouble()
          : double.tryParse(item['vat'].toString()) ?? 0.0;
      final discount = (item['iskonto'] is num)
          ? item['iskonto'].toDouble()
          : double.tryParse(item['iskonto'].toString()) ?? 0.0;

      // Calculate total with discount and VAT
      final discountedPrice = price * (1 - discount / 100);
      total += quantity * discountedPrice * (1 + vat / 100);
    }
    return total;
  }

  void _showPdfOptions(String customerName, List<Map<String, dynamic>> items, String fisNo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Text(
                  'PDF Options',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              // Options in a Row
              Row(
                children: [
                  // View PDF Option
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _generatePdf(customerName, items, fisNo, share: false);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.grey[700],
                              size: 8.w,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'View PDF',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 4.w),

                  // Share PDF Option
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _generatePdf(customerName, items, fisNo, share: true);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share,
                              color: Colors.grey[700],
                              size: 8.w,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Share PDF',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generatePdf(String customerName, List<Map<String, dynamic>> items, String fisNo, {bool share = false}) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.lightPrimaryColor,
                ),
                SizedBox(height: 2.h),
                Text(
                  share ? 'Preparing to share...' : 'Generating PDF...',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      );

      // Extract customer code from items (they all have the same customer)
      final customerCode = items.isNotEmpty
          ? items.first['customerKod']?.toString() ?? ''
          : '';

      // Remove fisNo from customerName (format: "fisNo - customerName")
      String cleanCustomerName = customerName;
      if (customerName.contains(' - ')) {
        final parts = customerName.split(' - ');
        if (parts.length > 1) {
          // Remove first part (fisNo) and join the rest
          cleanCustomerName = parts.sublist(1).join(' - ');
        }
      }

      // Generate PDF
      final pdfData = await PdfService.generateCartPdf(
        customerName: cleanCustomerName,
        items: items,
        fisNo: fisNo,
        customerCode: customerCode.isNotEmpty ? customerCode : null,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (share) {
        // Share PDF
        if (mounted) {
          await PdfService.sharePdf(
            pdfData,
            'Order_${fisNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        }
      } else {
        // Show PDF preview
        if (mounted) {
          await PdfService.previewPdf(
            context,
            pdfData,
            'Order_${fisNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCustomerCard(String customerName, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);
    final totalAmount = _calculateCartTotal(items);
    final itemCount = items.length;
    final fisNo = items.isNotEmpty ? (items.first['fisNo']?.toString() ?? '') : '';

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
          title: Row(
            children: [
              Expanded(
                child: Column(
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
              ),
              IconButton(
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red[700],
                  size: 6.w,
                ),
                onPressed: () => _showPdfOptions(customerName, items, fisNo),
                tooltip: 'PDF Options',
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
    final vat = (item['vat'] is num)
        ? item['vat'].toDouble()
        : double.tryParse(item['vat'].toString()) ?? 0.0;
    final discount = (item['iskonto'] is num)
        ? item['iskonto'].toDouble()
        : double.tryParse(item['iskonto'].toString()) ?? 0.0;

    // Calculate discounted price and total with VAT
    final discountedPrice = price * (1 - discount / 100);
    final total = quantity * discountedPrice * (1 + vat / 100);
    final unitType = item['birimTipi']?.toString() ?? 'Unit';

    // Birim tipine göre fiyat etiketi belirle
    String priceLabel;
    if (unitType.toLowerCase() == 'box') {
      priceLabel = 'Box Price';
    } else {
      priceLabel = 'Unit Price';
    }

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
                // Show discount if applied
                if (discount > 0) ...[
                  // Quantity on first line
                  Text(
                    '${'saved_carts.quantity'.tr()}: ${quantity % 1 == 0 ? quantity.toInt() : quantity} $unitType',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  // Price with discount on second line
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$priceLabel: ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '£${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '£${discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${discount % 1 == 0 ? discount.toInt() : discount.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${'saved_carts.quantity'.tr()}: ${quantity % 1 == 0 ? quantity.toInt() : quantity} $unitType',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: Text(
                          '$priceLabel: £${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
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