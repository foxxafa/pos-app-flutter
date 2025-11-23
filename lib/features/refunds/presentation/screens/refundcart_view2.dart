import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';
import 'package:pos_app/features/refunds/presentation/providers/cart_provider_refund.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/customer/presentation/customer_view.dart';
import 'package:pos_app/features/products/domain/entities/birim_model.dart';
import 'package:pos_app/features/products/domain/repositories/unit_repository.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class RefundCartView2 extends StatefulWidget {
  final RefundFisModel fisModel;

  const RefundCartView2({
    super.key,
    required this.fisModel,
  });

  @override
  State<RefundCartView2> createState() => _RefundCartView2State();
}

class _RefundCartView2State extends State<RefundCartView2> {
  // --- State Variables ---
  Map<String, Future<String?>> _imageFutures = {};
  Timer? _imageDownloadTimer;
  bool _isSubmitting = false;

  final List<String> _returnReasons = [
    'Expired (Useless)',
    'Refused (Useful)',
    'Damaged (Useless)',
    'Faulty Pack (Useless)',
    'Short Item',
    'Misdelivery (Useful)',
    'Other (Useful)',
    'Trial Returned (Useful)',
    'Short Dated (Useless)',
    'Price Difference',
    'Others (Useless)',
    'Trial Returned (Useless)',
  ];

  // --- Lifecycle Methods ---
  @override
  void dispose() {
    _imageDownloadTimer?.cancel();
    _imageFutures.clear();
    super.dispose();
  }

  // --- Image Handling ---
  Future<String?> _loadImage(String? imsrc) async {
    try {
      if (imsrc == null || imsrc.isEmpty) return null;
      final uri = Uri.parse(imsrc);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (fileName.isEmpty) return null;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      return await file.exists() ? filePath : null;
    } catch (_) {
      return null;
    }
  }

  void _generateImageFutures(List<CartItem> items) {
    for (final item in items) {
      final stokKodu = item.stokKodu;
      if (!_imageFutures.containsKey(stokKodu)) {
        _imageFutures[stokKodu] = _loadImage(item.imsrc);
      }
    }
  }

  // --- Return Reason Dialog ---
  void _showReturnReasonDialog(BuildContext context, String stokKodu, RCartProvider cartProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.h)),
      ),
      constraints: BoxConstraints(maxHeight: 28.h),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: ListView.builder(
            padding: EdgeInsets.only(top: 1.h, bottom: 2.h),
            itemCount: _returnReasons.length,
            itemBuilder: (context, index) {
              final reason = _returnReasons[index];
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(reason, style: TextStyle(fontSize: 15.sp)),
                value: reason,
                groupValue: cartProvider.items[stokKodu]?.aciklama,
                onChanged: (value) {
                  if (value != null) {
                    cartProvider.updateAciklama(stokKodu, value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  // --- Data Conversion ---
  List<RefundItemModel> _convertCartToRefundItems(RCartProvider cartProvider) {
    return cartProvider.items.values.map((cartItem) {
      return RefundItemModel(
        stokKodu: cartItem.stokKodu,
        urunAdi: cartItem.urunAdi,
        miktar: cartItem.miktar,
        birimFiyat: cartItem.birimFiyat,
        toplamTutar: cartItem.indirimliTutar,
        vat: cartItem.vat,
        birimTipi: cartItem.birimTipi,
        durum: cartItem.durum.toString(),
        urunBarcode: cartItem.urunBarcode,
        iskonto: cartItem.iskonto,
        aciklama: cartItem.aciklama,
      );
    }).toList();
  }

  double _calculateTotalAmount(List<RefundItemModel> refundList) {
    return refundList.fold(0.0, (sum, item) => sum + item.toplamTutar);
  }

  // --- Submit Refund ---
  Future<void> _submitRefund(BuildContext context) async {
    final cartProvider = Provider.of<RCartProvider>(context, listen: false);
    final cartItems = cartProvider.items.values.toList();

    // Validate all items have return reasons
    final itemsWithoutReason = cartItems.where((item) => item.aciklama.isEmpty).toList();
    if (itemsWithoutReason.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select return reason for all items'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final refundRepository = Provider.of<RefundRepository>(context, listen: false);
      final refundItems = _convertCartToRefundItems(cartProvider);
      final totalAmount = _calculateTotalAmount(refundItems);

      // ✅ CRITICAL FIX: Use fisNo from provider, not from widget.fisModel
      // Provider has the latest fisNo, widget.fisModel may have old/empty fisNo
      final actualFisNo = cartProvider.fisNo.isNotEmpty ? cartProvider.fisNo : widget.fisModel.fisNo;

      // ✅ Create NEW instance (fisNo is final, cannot mutate)
      RefundFisModel fisModelCopy = RefundFisModel(
        fisNo: actualFisNo,
        fistarihi: widget.fisModel.fistarihi,
        musteriId: widget.fisModel.musteriId,
        toplamtutar: totalAmount,
        aciklama: widget.fisModel.aciklama,
        status: widget.fisModel.status,
        iadeNedeni: widget.fisModel.iadeNedeni,
      );

      debugPrint('📦 Submitting refund with fisNo: $actualFisNo (from provider: ${cartProvider.fisNo})');

      RefundSendModel refundSendModel = RefundSendModel(
        fis: fisModelCopy,
        satirlar: refundItems,
      );

      // ✅ İnternet olsa bile önce offline kaydet, sync butonuna basınca gönder
      final saved = await refundRepository.saveRefundOffline(refundSendModel);

      if (!saved) {
        // Duplicate fisNo - this refund was already submitted
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This return was already submitted (FisNo: ${fisModelCopy.fisNo})'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return; // Don't proceed with navigation
      }

      print("📥 İade offline kaydedildi, sync ile gönderilecek.");

      // Log activity
      final activityRepository = Provider.of<ActivityRepository>(context, listen: false);
      final selectedCustomer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
      final customerCode = selectedCustomer?.kod ?? '';
      final now = DateTime.now();
      final formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      await activityRepository.addActivity(
        "Return Receipt\n"
        "Customer: $customerCode\n"
        "No: ${fisModelCopy.fisNo}\n"
        "Date: $formattedDate\n"
        "Total Amount: ${totalAmount.toStringAsFixed(2)}\n"
        "Status: Completed",
      );

      // Clear cart
      await cartProvider.clearCart();

      // Get customer balance
      final customerRepository = Provider.of<CustomerRepository>(context, listen: false);
      final customer = await customerRepository.getCustomerByUnvan(selectedCustomer?.kod ?? "TURAN");
      String bakiye = customer?['bakiye']?.toString() ?? "0.0";

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to customer view
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CustomerView(bakiye: bakiye)),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting return: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<RCartProvider>(context);
    final cartItems = cartProvider.items.values.toList();

    _generateImageFutures(cartItems);

    // ✅ Büyük/küçük harf farketmeden say (UNIT, Unit, unit hepsi)
    final unitCount = cartItems
        .where((item) => item.birimTipi.toUpperCase() == 'UNIT')
        .fold<int>(0, (prev, item) => prev + item.miktar);
    final boxCount = cartItems
        .where((item) => item.birimTipi.toUpperCase() == 'BOX')
        .fold<int>(0, (prev, item) => prev + item.miktar);
    final totalCount = unitCount + boxCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text('Return Cart Details', style: TextStyle(fontSize: 20.sp)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: cartItems.isEmpty ? null : () => _showClearCartDialog(context, cartProvider),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(3.w),
        child: cartItems.isEmpty
            ? _buildEmptyCart()
            : Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return RefundCartItemCard(
                    key: ValueKey(item.stokKodu),
                    item: item,
                    imageFuture: _imageFutures[item.stokKodu],
                    onRemove: () => cartProvider.removeItem(item.stokKodu),
                    onQuantityChange: (increment) => _handleQuantityChange(context, item, increment),
                    onReturnReasonTap: () => _showReturnReasonDialog(context, item.stokKodu, cartProvider),
                  );
                },
                separatorBuilder: (context, index) => Divider(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  thickness: 1,
                  height: 1,
                ),
              ),
            ),
            const Divider(),
            _buildSummarySection(unitCount, boxCount, totalCount, cartProvider),
            SizedBox(height: 2.h),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'Return cart is empty',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(int unitCount, int boxCount, int totalCount, RCartProvider cartProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Units', unitCount),
              _buildSummaryItem('Boxes', boxCount),
              _buildSummaryItem('Total Items', totalCount),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                cartProvider.toplamTutar.toStringAsFixed(2),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value) {
    return Text(
      '$label: $value',
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _submitRefund(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 3.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(
          'Submit Return',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, RCartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Cart'),
        content: Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await cartProvider.clearCart();
              _imageFutures.clear();
              setState(() {});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Return cart cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _handleQuantityChange(BuildContext context, CartItem item, bool increment) {
    final cartProvider = Provider.of<RCartProvider>(context, listen: false);
    final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

    if (!increment && item.miktar <= 1) {
      cartProvider.removeItem(item.stokKodu);
      return;
    }

    cartProvider.customerName = customerProvider.selectedCustomer?.kod ?? '';
    cartProvider.addOrUpdateItem(
      urunAdi: item.urunAdi,
      stokKodu: item.stokKodu,
      birimFiyat: item.birimFiyat,
      urunBarcode: item.urunBarcode,
      adetFiyati: item.adetFiyati,
      kutuFiyati: item.kutuFiyati,
      miktar: increment ? 1 : -1,
      iskonto: item.iskonto,
      birimTipi: item.birimTipi,
      durum: item.durum,
      vat: item.vat,
      imsrc: item.imsrc,
    );
  }
}


// --- WIDGETS ---

class RefundCartItemCard extends StatefulWidget {
  final CartItem item;
  final Future<String?>? imageFuture;
  final VoidCallback onRemove;
  final Function(bool increment) onQuantityChange;
  final VoidCallback onReturnReasonTap;

  const RefundCartItemCard({
    super.key,
    required this.item,
    this.imageFuture,
    required this.onRemove,
    required this.onQuantityChange,
    required this.onReturnReasonTap,
  });

  @override
  State<RefundCartItemCard> createState() => _RefundCartItemCardState();
}

class _RefundCartItemCardState extends State<RefundCartItemCard> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  String _oldQuantityValue = '';
  String _oldPriceValue = '';

  // ✅ Dinamik birim yönetimi
  List<BirimModel> _birimler = [];
  BirimModel? _selectedBirim;
  bool _birimlersLoading = true;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.miktar.toString());
    _priceController = TextEditingController(text: widget.item.birimFiyat.toStringAsFixed(2));
    _quantityFocusNode.addListener(_onQuantityFocusChange);
    _priceFocusNode.addListener(_onPriceFocusChange);

    // ✅ Ürün birimlerini yükle
    _loadBirimlerForItem();
  }

  /// Ürün için birimleri veritabanından yükler (fiyat7 kullanarak)
  Future<void> _loadBirimlerForItem() async {
    try {
      setState(() => _birimlersLoading = true);

      final unitRepository = Provider.of<UnitRepository>(context, listen: false);
      final birimler = await unitRepository.getBirimlerByStokKodu(widget.item.stokKodu);

      if (!mounted) return;

      setState(() {
        _birimler = birimler;
        _birimlersLoading = false;

        // ✅ Mevcut seçili birimi bul (CartItem'daki selectedBirimKey kullanarak)
        if (widget.item.selectedBirimKey != null && _birimler.isNotEmpty) {
          _selectedBirim = _birimler.firstWhere(
            (b) => b.key == widget.item.selectedBirimKey,
            orElse: () => _birimler.first,
          );
        } else if (_birimler.isNotEmpty) {
          // selectedBirimKey yoksa ilk birimi seç (default)
          _selectedBirim = _birimler.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _birimlersLoading = false;
        _birimler = [];
      });

      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Birimler yüklenemedi: $e'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _quantityFocusNode.removeListener(_onQuantityFocusChange);
    _priceFocusNode.removeListener(_onPriceFocusChange);
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onQuantityFocusChange() {
    if (_quantityFocusNode.hasFocus) {
      _oldQuantityValue = _quantityController.text;
      _quantityController.clear();
    } else {
      if (_quantityController.text.isEmpty) {
        if (mounted) {
          setState(() {
            _quantityController.text = _oldQuantityValue;
          });
        }
      }
      _updateQuantityFromTextField(_quantityController.text);
    }
  }

  void _onPriceFocusChange() {
    if (_priceFocusNode.hasFocus) {
      _oldPriceValue = _priceController.text;
      _priceController.clear();
    } else {
      if (_priceController.text.isEmpty && _oldPriceValue.isNotEmpty) {
        if (mounted) {
          setState(() {
            _priceController.text = _oldPriceValue;
          });
        }
      } else if (_priceController.text.isNotEmpty) {
        // Format and update price
        final value = _priceController.text.replaceAll(',', '.');
        final parsed = double.tryParse(value);
        if (parsed != null && mounted) {
          setState(() {
            _priceController.text = parsed.toStringAsFixed(2);
          });
          _updatePriceFromTextField(parsed);
        }
      }
    }
  }

  void _updateQuantityFromTextField(String value) {
    final newQuantity = int.tryParse(value) ?? 0;
    final currentQuantity = widget.item.miktar;
    final difference = newQuantity - currentQuantity;

    if (difference == 0) return;

    if (difference > 0) {
      for (int i = 0; i < difference; i++) {
        widget.onQuantityChange(true);
      }
    } else {
      for (int i = 0; i < difference.abs(); i++) {
        widget.onQuantityChange(false);
      }
    }
  }

  void _updatePriceFromTextField(double newPrice) {
    // Call parent's onQuantityChange with 0 to update price without changing quantity
    // We need to access the provider directly
    final cartProvider = Provider.of<RCartProvider>(context, listen: false);
    final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

    // Check if item still exists in cart before updating
    if (!cartProvider.items.containsKey(widget.item.stokKodu)) {
      return; // Item was removed, don't update
    }

    // ✅ Orijinal %70'lik fiyatı hesapla (refund kuralı)
    // Kullanıcı fiyatı değiştirdiyse yeni fiyat kullanılır
    // Ama default olarak %70'lik fiyat korunmalı
    final originalPrice70 = (widget.item.birimFiyat / 0.7); // %70'lik fiyattan orijinali hesapla
    final expectedPrice70 = originalPrice70 * 0.7;

    // Eğer kullanıcı default %70'lik fiyattan farklı bir fiyat girdiyse güncelle
    final finalPrice = (newPrice != expectedPrice70) ? newPrice : expectedPrice70;

    cartProvider.customerName = customerProvider.selectedCustomer?.kod ?? '';
    cartProvider.addOrUpdateItem(
      urunAdi: widget.item.urunAdi,
      stokKodu: widget.item.stokKodu,
      birimFiyat: finalPrice,
      urunBarcode: widget.item.urunBarcode,
      adetFiyati: widget.item.adetFiyati,
      kutuFiyati: widget.item.kutuFiyati,
      miktar: 0, // Don't change quantity
      iskonto: widget.item.iskonto,
      birimTipi: widget.item.birimTipi,
      durum: widget.item.durum,
      vat: widget.item.vat,
      imsrc: widget.item.imsrc,
    );
  }

  /// Birim değiştirildiğinde tetiklenir (Dinamik birimler sistemi)
  void _onBirimChanged(BirimModel? newBirim) {
    if (newBirim == null) return;

    final item = widget.item;
    final cartProvider = Provider.of<RCartProvider>(context, listen: false);
    final customerProvider = Provider.of<SalesCustomerProvider>(context, listen: false);

    // ✅ Yeni birimin fiyatını fiyat7'den al
    final originalFiyat = newBirim.fiyat7 ?? 0.0;

    print('🔄 REFUND BIRIM DEĞİŞİMİ:');
    print('  Eski birim: ${item.birimTipi}');
    print('  Eski fiyat: ${item.birimFiyat}');
    print('  Yeni birim: ${newBirim.birimkod}');
    print('  Orijinal fiyat (fiyat7): $originalFiyat');

    // Fiyat kontrolü - eğer 0 veya null ise hata göster
    if (originalFiyat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${newBirim.birimadi} fiyatı bulunamadı ($originalFiyat).'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ REFUND KURALI: %70 indirimli fiyat kullan
    final discountedFiyat = originalFiyat * 0.7;
    print('  %70 indirimli fiyat: $discountedFiyat');

    // ✅ Seçili birimi güncelle
    setState(() {
      _selectedBirim = newBirim;
    });

    // ✅ Yeni birimTipi = birimkod (BOX, UNIT, KG vs. - UPPERCASE)
    final newBirimTipi = (newBirim.birimkod ?? newBirim.birimadi ?? 'UNIT').toUpperCase();

    print('  Final birimTipi: $newBirimTipi');

    // ✅ Provider'ı güncelle (miktar=0 olarak gönder - miktar değişmesin)
    cartProvider.customerName = customerProvider.selectedCustomer?.kod ?? '';
    cartProvider.addOrUpdateItem(
      urunAdi: item.urunAdi,
      stokKodu: item.stokKodu,
      birimFiyat: discountedFiyat, // ✅ %70 indirimli fiyat
      urunBarcode: item.urunBarcode,
      adetFiyati: item.adetFiyati,
      kutuFiyati: item.kutuFiyati,
      miktar: 0, // ⚠️ 0 = miktarı değiştirme, sadece birim ve fiyatı güncelle
      iskonto: item.iskonto,
      birimTipi: newBirimTipi,
      durum: item.durum,
      vat: item.vat,
      imsrc: item.imsrc,
      selectedBirimKey: newBirim.key, // ✅ FIX: Seçili birimi kaydet
    );

    // ✅ Fiyat controller'ını güncelle (%70 indirimli fiyatla)
    _priceController.text = discountedFiyat.toStringAsFixed(2);

    print('  ✅ Item güncellendi: ${item.stokKodu}, birim=$newBirimTipi, fiyat=$discountedFiyat');
  }

  @override
  void didUpdateWidget(RefundCartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update quantity controller if focus is not on quantity field
    if (!_quantityFocusNode.hasFocus && oldWidget.item.miktar != widget.item.miktar) {
      _quantityController.text = widget.item.miktar.toString();
    }
    // Only update price controller if focus is not on price field
    if (!_priceFocusNode.hasFocus && oldWidget.item.birimFiyat != widget.item.birimFiyat) {
      _priceController.text = widget.item.birimFiyat.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync quantity controller with widget.item.miktar if not focused
    if (!_quantityFocusNode.hasFocus && _quantityController.text != widget.item.miktar.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_quantityFocusNode.hasFocus) {
          _quantityController.text = widget.item.miktar.toString();
        }
      });
    }

    // Sync price controller with widget.item.birimFiyat if not focused
    if (!_priceFocusNode.hasFocus && _priceController.text != widget.item.birimFiyat.toStringAsFixed(2)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_priceFocusNode.hasFocus) {
          _priceController.text = widget.item.birimFiyat.toStringAsFixed(2);
        }
      });
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildImage(context),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 1.h),
                _buildReturnReasonSection(context),
                SizedBox(height: 1.h),
                _buildBottomSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageDialog(context),
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        child: widget.item.imsrc == null
            ? Icon(Icons.shopping_bag, size: 15.w, color: Colors.grey)
            : FutureBuilder<String?>(
          future: widget.imageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (snapshot.hasData && snapshot.data != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(Icons.broken_image, size: 15.w, color: Colors.grey),
                ),
              );
            }
            return Icon(Icons.shopping_bag, size: 15.w, color: Colors.grey);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.item.urunAdi,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: widget.onRemove,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          iconSize: 2.2.h,
        ),
      ],
    );
  }

  Widget _buildReturnReasonSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: InkWell(
            onTap: widget.onReturnReasonTap,
            child: Container(
              height: 8.w,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.item.aciklama.isEmpty ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment,
                    size: 18.sp,
                    color: widget.item.aciklama.isEmpty ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      widget.item.aciklama.isEmpty ? 'Select return reason' : widget.item.aciklama,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: widget.item.aciklama.isEmpty ? Colors.grey : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          flex: 3,
          child: Container(
            height: 8.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _priceController,
              focusNode: _priceFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed != null) {
                  _updatePriceFromTextField(parsed);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ Birim seçici (Dropdown veya statik Text)
        Flexible(
          flex: 2,
          child: _buildUnitSelector(context),
        ),
        SizedBox(width: 3.w),
        _buildQuantityControl(context),
      ],
    );
  }

  /// ✅ Dinamik birim seçimi için Dropdown widget'ı (fiyat7 ile)
  Widget _buildUnitSelector(BuildContext context) {
    // ✅ Birimler yüklenirken loading göster
    if (_birimlersLoading) {
      return Container(
        height: 8.w,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // ✅ Birim bulunamadıysa veya tek birim varsa statik Text göster
    if (_birimler.isEmpty || _birimler.length == 1) {
      return Container(
        height: 8.w,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _selectedBirim?.birimadi ?? widget.item.birimTipi,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // ✅ Birden fazla birim varsa Dropdown göster (DropdownButton kullan - daha temiz görünüm)
    return SizedBox(
      height: 8.w,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<BirimModel>(
          value: _selectedBirim,
          isDense: true,
          underline: Container(), // Alt çizgiyi kaldır
          style: TextStyle(
            fontSize: 13.sp, // ✅ Font boyutunu küçült
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          items: _birimler.map((birim) {
            return DropdownMenuItem<BirimModel>(
              value: birim,
              child: Text(birim.birimadi ?? ''),
            );
          }).toList(),
          onChanged: _onBirimChanged,
        ),
      ),
    );
  }

  Widget _buildQuantityControl(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            icon: Icon(Icons.remove, size: 6.w, color: Theme.of(context).colorScheme.error),
            onPressed: () => widget.onQuantityChange(false),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(width: 1.w),
        Container(
          width: 12.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: TextField(
              controller: _quantityController,
              focusNode: _quantityFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              maxLines: 1,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                isDense: true,
              ),
              onSubmitted: (value) => _updateQuantityFromTextField(value),
            ),
          ),
        ),
        SizedBox(width: 1.w),
        Container(
          width: 12.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            icon: Icon(Icons.add, size: 6.w, color: Theme.of(context).colorScheme.primary),
            onPressed: () => widget.onQuantityChange(true),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.item.urunAdi),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.imsrc != null)
              FutureBuilder<String?>(
                future: widget.imageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(width: 40.w, height: 40.w, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(snapshot.data!), width: 40.w, height: 40.w, fit: BoxFit.contain),
                    );
                  }
                  return Icon(Icons.shopping_bag, size: 40.w);
                },
              )
            else
              Icon(Icons.shopping_bag, size: 40.w),
            SizedBox(height: 2.h),
            Text('Unit Price: ${widget.item.adetFiyati}'),
            Text('Box Price: ${widget.item.kutuFiyati}'),
            Text('Discount: ${widget.item.iskonto}%'),
            Text('Return Reason: ${widget.item.aciklama.isEmpty ? 'Not selected' : widget.item.aciklama}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}