import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/orders/presentation/providers/orderinfo_provider.dart';
import 'package:pos_app/features/cart/presentation/cart_view.dart';
import 'package:pos_app/core/utils/fisno_generator.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/theme/app_theme.dart';

class Invoice2Activity extends StatefulWidget {
  const Invoice2Activity({Key? key}) : super(key: key);

  @override
  State<Invoice2Activity> createState() => _Invoice2ActivityState();
}

class _Invoice2ActivityState extends State<Invoice2Activity> {
  String orderNo = '';  // ✅ Boş string ile başlat, initState'de doldurulacak
  String comment = "";
  String? selectedPaymentMethod;
  DateTime selectedPaymentDate = DateTime.now();
  DateTime selectedDeliveryDate = DateTime.now();
  List<String> _refundProductNames=[];
  List<Refund> refunds = [];
  bool _fisNoGenerated = false;  // FisNo'nun oluşturulup oluşturulmadığını takip eder


  final List<String> paymentMethods = [
    "Cash on Delivery",
    "Cheque",
    "Paid",
    "Balance",
    "Partial",
    "Bank",
    "No Payment",
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Sayfa ilk açıldığında FisNo'yu oluştur (sadece 1 kez)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_fisNoGenerated) {
        await _generateFisNo();
        _fisNoGenerated = true;
      }
    });
  }

  /// FisNo üretir ve OrderInfoProvider'a kaydeder
  Future<void> _generateFisNo() async {
    try {
      // Login tablosundan kullanıcı ID'sini al
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.query('Login', limit: 1);
      final int userId = result.isNotEmpty ? (result.first['id'] as int) : 1;

      // FisNo üret
      orderNo = FisNoGenerator.generate(userId: userId);

      // Provider'a kaydet
      if (mounted) {
        final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);
        orderInfoProvider.orderNo = orderNo;
        setState(() {}); // UI'ı güncelle
      }

      print('✅ FisNo başarıyla oluşturuldu: $orderNo (UserID: $userId)');
    } catch (e) {
      print('⚠️ FisNo oluşturma hatası: $e');
      // Fallback: Basit timestamp kullan
      orderNo = 'MO${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      if (mounted) {
        final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);
        orderInfoProvider.orderNo = orderNo;
        setState(() {});
      }
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
      final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedPaymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedPaymentDate = picked);
String formattedDate = DateFormat('dd.MM.yyyy').format(selectedPaymentDate);
orderInfoProvider.paymentDate=formattedDate;
    }
  }

   _loadRefunds(String cariKod) async {
    final refundRepository = Provider.of<RefundRepository>(context, listen: false);

    refunds = await refundRepository.fetchRefunds(cariKod);

    // refund urunAdi'larını sayfa içinde al
      _refundProductNames =
          refunds
              .map((r) => r.urunAdi)
              .toSet()
              .toList(); // Tekilleştir
print("bunlarrr $_refundProductNames");
  }
  
  Future<void> _selectDeliveryDate(BuildContext context) async {      final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDeliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDeliveryDate = picked);
      String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDeliveryDate);
  orderInfoProvider.deliveryDate=formattedDate;
    }
  }

  void _showPaymentBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 4.w,
            right: 4.w,
            top: 3.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              SizedBox(height: 3.h),

              Text(
                'order.select_payment_method'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3.h),

              ...paymentMethods.map((method) {
                final isSelected = selectedPaymentMethod == method;
                return Container(
                  margin: EdgeInsets.only(bottom: 1.h),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);
                        orderInfoProvider.paymentType = method;
                        setState(() => selectedPaymentMethod = method);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.05)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSelected ? Icons.check : Icons.payment,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 4.w,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                method,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: 4.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    final dateFormat = DateFormat('dd.MM.yyyy');

    // ❌ ARTIK BURADA FİSNO ÜRETMİYORUZ!
    // FisNo initState'de oluşturuldu ve orderNo değişkeninde saklanıyor

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('order.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Order Number Card
            _buildInfoCard(
              title: 'order.order_no'.tr(),
              content: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: orderNo.isEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Generating...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        orderNo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
              ),
              isCompact: true,
            ),

            SizedBox(height: 0.8.h),

            // Comment Card
            _buildInfoCard(
              title: 'order.comment'.tr(),
              content: TextField(
                maxLines: 5,
                onChanged: (val) => comment = val,
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                },
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'order.enter_comment'.tr(),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(2.w),
                  isDense: true,
                ),
              ),
            ),

            SizedBox(height: 0.8.h),

            // Payment Method Card
            _buildActionCard(
              icon: Icons.payment_outlined,
              title: 'order.choose_payment_type'.tr(),
              subtitle: selectedPaymentMethod != null
                  ? "${'order.selected_payment'.tr()} $selectedPaymentMethod"
                  : null,
              onTap: _showPaymentBottomSheet,
            ),

            SizedBox(height: 0.8.h),

            // Payment Date Card
            _buildActionCard(
              icon: Icons.calendar_today_outlined,
              title: 'order.date'.tr(),
              subtitle: dateFormat.format(selectedPaymentDate),
              onTap: () => _selectPaymentDate(context),
            ),

            SizedBox(height: 0.8.h),

            // Delivery Date Card
            _buildActionCard(
              icon: Icons.local_shipping_outlined,
              title: 'order.delivery_date'.tr(),
              subtitle: dateFormat.format(selectedDeliveryDate),
              onTap: () => _selectDeliveryDate(context),
            ),

            SizedBox(height: 1.5.h),

            // Select Products Button
            Card(
              child: SizedBox(
                width: double.infinity,
                height: 64.0,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Hemen sayfaya geç, refunds arka planda yüklenecek
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartView(
                          refundProductNames: _refundProductNames,
                          refunds: refunds,
                        ),
                      ),
                    );
                    // Arka planda refunds yükle (gelecekte kullanmak için)
                    _loadRefunds(customer!.kod!);
                  },
                  icon: Icon(Icons.shopping_cart_outlined, size: 24),
                  label: Text(
                    'order.select_products'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content, bool isCompact = false}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isCompact ? 1.h : 2.h),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 4.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ❌ ESKİ generateFisNo FONKSİYONU SİLİNDİ
// ✅ Artık FisNoGenerator.generate() kullanılıyor