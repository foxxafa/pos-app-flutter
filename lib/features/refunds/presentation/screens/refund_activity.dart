import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/refunds/presentation/screens/refundlist2_view.dart';
import 'package:pos_app/features/refunds/presentation/providers/cart_provider_refund.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class RefundActivityView extends StatefulWidget {
  const RefundActivityView({Key? key}) : super(key: key);

  @override
  State<RefundActivityView> createState() => _RefundActivityViewState();
}

class _RefundActivityViewState extends State<RefundActivityView> {
  List<Map<String, dynamic>> _pendingRefunds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllRefunds();
    });
  }

  /// ✅ Load ONLY pending refunds from refund_queue (like Order system loads from PendingSales)
  Future<void> _loadAllRefunds() async {
    setState(() => _isLoading = true);

    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _pendingRefunds = [];
        _isLoading = false;
      });
      return;
    }

    // ✅ ONLY load from refund_queue (pending refunds not yet synced)
    await _loadPendingRefunds();

    setState(() => _isLoading = false);
  }

  /// ✅ Load pending refunds from refund_queue table (like PendingSales for orders)
  Future<void> _loadPendingRefunds() async {
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _pendingRefunds = [];
      });
      return;
    }

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Query refund_queue for this customer (ALL refunds, no duplicate check needed)
    final rows = await db.query('refund_queue');
    final filtered = <Map<String, dynamic>>[];

    for (var row in rows) {
      final dataStr = row['data']?.toString();
      if (dataStr == null) continue;

      try {
        final data = jsonDecode(dataStr);
        final musteriId = data['fis']?['MusteriId'];
        final fisNo = row['fisNo'] ?? data['fis']?['FisNo'];

        if (musteriId == customerCode) {
          filtered.add({
            'id': row['id'],
            'fisNo': fisNo,
            'date': data['fis']?['Fistarihi'],
            'total': data['fis']?['Toplamtutar'],
            'reason': data['fis']?['IadeNedeni'],
            'data': dataStr,
            'isPending': true, // ✅ All refunds in queue are pending
          });
        }
      } catch (e) {
        debugPrint('❌ Error parsing refund: $e');
      }
    }

    setState(() {
      _pendingRefunds = filtered;
    });

    debugPrint('📊 Pending refunds loaded: ${filtered.length}');
    for (var r in filtered) {
      final fisNo = r['fisNo']?.toString();
      final displayFisNo = (fisNo == null || fisNo.isEmpty) ? '[NO FISNO]' : fisNo;
      debugPrint('   - Pending: ID=${r['id']}, FisNo=$displayFisNo (${r['date']}) £${r['total']}');
    }
  }

  /// ✅ NEW: Load a pending refund into cart
  Future<void> _loadRefund(Map<String, dynamic> refund) async {
    debugPrint('📥 _loadRefund called with fisNo: ${refund['fisNo']}');

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Load Refund?', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Refund No: ${refund['fisNo']}', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 0.5.h),
            Text('Total: £${refund['total']}', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 0.5.h),
            Text('Date: ${refund['date']}', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 1.h),
            Text('Do you want to load this refund?', style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    // Parse refund data
    final data = jsonDecode(refund['data']);
    final fis = data['fis'];
    final satirlar = List<Map<String, dynamic>>.from(data['satirlar']);

    if (satirlar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items in this refund'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Load customer info
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final customerKod = fis['MusteriId']?.toString() ?? '';
    String customerName = '';

    if (customerKod.isNotEmpty) {
      final customerRows = await db.query('CustomerBalance', where: 'kod = ?', whereArgs: [customerKod]);
      if (customerRows.isNotEmpty) {
        customerName = customerRows.first['unvan']?.toString() ?? '';
      }
    }

    final provider = Provider.of<RCartProvider>(context, listen: false);

    // Set provider data
    provider.fisNo = '';  // Will be generated in RefundList2View
    provider.customerKod = customerKod;
    provider.customerName = customerName;
    provider.eskiFisNo = refund['fisNo'];
    provider.refundQueueId = refund['id'] as int?;  // ✅ Store queue ID for deletion

    debugPrint('🔄 Load Refund: refundQueueId=${refund['id']}, eskiFisNo=${refund['fisNo']}, customerKod=$customerKod');

    // Clear cart
    await provider.clearCart();

    // Load products from database for fast lookup
    final stokKodlari = satirlar.map((s) => s['StokKodu']?.toString() ?? '').where((k) => k.isNotEmpty).toList();

    final productRows = await db.query(
      'Product',
      where: 'stokKodu IN (${List.filled(stokKodlari.length, '?').join(',')})',
      whereArgs: stokKodlari,
    );

    final productMap = <String, Map<String, dynamic>>{};
    for (var p in productRows) {
      final kod = p['stokKodu']?.toString() ?? '';
      if (kod.isNotEmpty) productMap[kod] = p;
    }

    // Load birimler data for all products to find selectedBirimKey
    final birimlerRows = await db.query(
      'birimler',
      where: 'StokKodu IN (${List.filled(stokKodlari.length, '?').join(',')})',
      whereArgs: stokKodlari,
    );

    // Group birimler by stokKodu
    final birimlerMap = <String, List<Map<String, dynamic>>>{};
    for (var birim in birimlerRows) {
      final stokKodu = birim['StokKodu']?.toString() ?? '';
      if (stokKodu.isNotEmpty) {
        birimlerMap.putIfAbsent(stokKodu, () => []).add(birim);
      }
    }

    // Add items to cart
    for (var s in satirlar) {
      final stokKodu = s['StokKodu']?.toString() ?? '';
      final product = productMap[stokKodu] ?? {};

      final double miktar = (s['Miktar'] is num) ? s['Miktar'].toDouble() : double.tryParse(s['Miktar'].toString()) ?? 0.0;
      final int miktarInt = miktar.round();
      final double birimFiyat = (s['BirimFiyat'] is num) ? s['BirimFiyat'].toDouble() : double.tryParse(s['BirimFiyat'].toString()) ?? 0.0;
      final double iskonto = (s['Iskonto'] is num) ? (s['Iskonto'] as num).toDouble() : double.tryParse(s['Iskonto'].toString()) ?? 0.0;
      final int vat = (s['vat'] is num) ? (s['vat'] as num).round() : int.tryParse(s['vat'].toString()) ?? 18;
      final String birimTipi = s['BirimTipi']?.toString() ?? 'Unit';
      final int durum = (s['Durum'] is num) ? (s['Durum'] as num).toInt() : int.tryParse(s['Durum']?.toString() ?? '1') ?? 1;

      // Find selectedBirimKey by matching birimTipi with birimadi
      String? selectedBirimKey;
      final birimlerList = birimlerMap[stokKodu] ?? [];
      for (var birim in birimlerList) {
        final birimadi = birim['birimadi']?.toString() ?? '';
        if (birimadi.toLowerCase() == birimTipi.toLowerCase()) {
          selectedBirimKey = birim['_key']?.toString();
          break;
        }
      }

      debugPrint('🔍 Load Item: stokKodu=$stokKodu, birimTipi=$birimTipi, selectedBirimKey=$selectedBirimKey');

      provider.addOrUpdateItem(
        stokKodu: stokKodu,
        urunAdi: s['UrunAdi']?.toString() ?? '',
        birimFiyat: birimFiyat,
        urunBarcode: product['barcode1']?.toString() ?? '',
        miktar: miktarInt,
        iskonto: iskonto,
        birimTipi: birimTipi,
        vat: vat,
        durum: durum,
        imsrc: product['imsrc']?.toString(),
        adetFiyati: s['AdetFiyati']?.toString() ?? '',
        kutuFiyati: s['KutuFiyati']?.toString() ?? '',
        selectedBirimKey: selectedBirimKey,  // ✅ Now passing selectedBirimKey
      );
    }

    debugPrint('✅ Load Refund: ${satirlar.length} items loaded into cart');

    // ✅ DELETE old refund from refund_queue (prevent duplicate loads)
    final refundQueueId = refund['id'] as int?;
    if (refundQueueId != null) {
      await db.delete('refund_queue', where: 'id = ?', whereArgs: [refundQueueId]);
      debugPrint('🗑️ Deleted old refund from refund_queue (id=$refundQueueId)');
    }

    // ✅ Remove from activity log (if exists)
    // NOTE: Activity log may not have this refund if it was created before activity tracking
    // This is optional - we keep it for consistency with Order system
    final activityRepository = Provider.of<ActivityRepository>(context, listen: false);
    if (refund['fisNo'] != null && refund['fisNo'].toString().isNotEmpty) {
      try {
        // Activity repository doesn't have removeActivityByRefundNo yet,
        // but we can add it or use generic removal
        debugPrint('🗑️ TODO: Remove activity for refund fisNo=${refund['fisNo']}');
      } catch (e) {
        debugPrint('⚠️ Could not remove activity log: $e');
      }
    }

    // Navigate to refund form
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RefundList2View()));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${satirlar.length} items loaded'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        title: const Text("Pending Refunds"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRefunds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
                      SizedBox(height: 2.h),
                      Text(
                        "No pending refunds for this customer",
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAllRefunds,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _pendingRefunds.length,
                    itemBuilder: (context, index) {
                      final refund = _pendingRefunds[index];
                      final fisNo = refund['fisNo']?.toString() ?? '';
                      final displayFisNo = fisNo.isEmpty ? 'Pending Refund #${refund['id']}' : fisNo;

                      return _buildRefundCard(
                        fisNo: displayFisNo,
                        date: refund['date'] ?? 'N/A',
                        total: refund['total']?.toString() ?? '0.00',
                        status: 'Pending',
                        isPending: true,
                        refundData: refund,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RefundList2View()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, size: 7.w, color: Colors.white),
      ),
    );
  }

  /// ✅ Refund card (mirroring Order card design from invoice_activity.dart)
  Widget _buildRefundCard({
    required String fisNo,
    required String date,
    required String total,
    required String status,
    required bool isPending,
    Map<String, dynamic>? refundData,
  }) {
    final theme = Theme.of(context);
    final totalValue = double.tryParse(total) ?? 0.0;

    debugPrint('🔍 _buildRefundCard: fisNo=$fisNo, isPending=$isPending, refundData=${refundData != null}');

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: refundData != null
            ? () {
                debugPrint('🎯 Card tapped! fisNo=$fisNo');
                _loadRefund(refundData);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Refund number and date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: theme.colorScheme.primary,
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fisNo,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '£${totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
