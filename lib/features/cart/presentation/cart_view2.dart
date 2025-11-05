import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';
import 'package:pos_app/core/sync/sync_service.dart';
import 'package:pos_app/features/orders/domain/entities/order_model.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/orders/presentation/providers/orderinfo_provider.dart';
import 'package:pos_app/features/customer/presentation/customer_view.dart';
import 'package:pos_app/features/products/domain/entities/birim_model.dart';
import 'package:pos_app/features/products/domain/repositories/unit_repository.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart';

// --- CONSTANTS ---
const String _unitType = 'Unit';
const String _boxType = 'Box';

class CartView2 extends StatefulWidget {
  const CartView2({super.key});

  @override
  State<CartView2> createState() => _CartView2State();
}

class _CartView2State extends State<CartView2> {
  // Image cache sistemi
  final Map<String, Future<String?>> _imageFutures = {};
  Timer? _imageDownloadTimer;
  late CartProvider _cartProvider;

  /// Double-click protection for Place Order button
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    // _cartProvider'ı burada başlatmıyoruz, çünkü context'e ihtiyacı var.
    // didChangeDependencies'de başlatacağız.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider'ı burada alıyoruz ve değişiklikleri dinliyoruz.
    _cartProvider = Provider.of<CartProvider>(context);
    final cartItems = _cartProvider.items.values.toList();

    // Cache sistemi ve eksik resimleri indir
    // Bu, build içinde çağrılmak yerine burada çağrılarak
    // gereksiz yere tetiklenmesi önlenir.
    _generateImageFutures(cartItems);
    _downloadMissingImages(cartItems);
  }

  @override
  void dispose() {
    // Artık controller'ları burada dispose etmemize gerek yok.
    // Sadece timer'ı iptal ediyoruz.
    _imageDownloadTimer?.cancel();
    super.dispose();
  }

  // --- Image Loading Logic ---

  Future<String?> _loadImage(String? imsrc) async {
    try {
      if (imsrc == null || imsrc.isEmpty) {
        return null;
      }

      final uri = Uri.parse(imsrc);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

      if (fileName.isEmpty) {
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      // Hata durumunda null dön
      return null;
    }
  }

  void _generateImageFutures(List<CartItem> items, {bool forceUpdate = false}) {
    for (final item in items) {
      final stokKodu = item.stokKodu;
      if (!_imageFutures.containsKey(stokKodu) || forceUpdate) {
        if (mounted) {
          setState(() {
            _imageFutures[stokKodu] = _loadImage(item.imsrc);
          });
        }
      }
    }
  }

  void _downloadMissingImages(List<CartItem> items) {
    _imageDownloadTimer?.cancel();
    _imageDownloadTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        SyncService.downloadCartItemImages(items, onImagesDownloaded: () {
          if (mounted) {
            // İndirme tamamlandığında future'ları güncelle
            _generateImageFutures(items, forceUpdate: true);
          }
        });
      }
    });
  }

  // --- Order Placement Logic ---

  /// Siparişi veritabanına kaydeder ve gerekli işlemleri yapar.
  Future<void> _placeOrder() async {
    // Double-click koruması
    if (_isSubmittingOrder) return;
    setState(() => _isSubmittingOrder = true);

    // Gerekli provider'ları ve veritabanını al
    // (context'in mounted olup olmadığını kontrol etmeye gerek yok, buradaysak mounted'dır)
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider =
    Provider.of<SalesCustomerProvider>(context, listen: false);
    final orderInfoProvider =
    Provider.of<OrderInfoProvider>(context, listen: false);
    final activityRepository =
    Provider.of<ActivityRepository>(context, listen: false);
    final customerRepository =
    Provider.of<CustomerRepository>(context, listen: false);
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    try {
      final customer = customerProvider.selectedCustomer;

      // --- Guard Clauses (Kontroller) ---
      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer first.')),
        );
        return; // İşlemi durdur
      }

      if (cartProvider.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty!')),
        );
        return; // İşlemi durdur
      }

      // --- Sipariş Oluşturma ---

      // Müşteri bilgilerini sepete ata
      cartProvider.customerName =
          customer.unvan ?? customer.kod ?? 'N/A';
      cartProvider.customerKod = customer.kod ?? 'N/A';

      final fisNo = orderInfoProvider.orderNo;

      final fisModel = FisModel(
        fisNo: fisNo,
        fistarihi: orderInfoProvider.paymentDate,
        musteriId: customer.kod!,
        toplamtutar: cartProvider.toplamTutar,
        odemeTuru: orderInfoProvider.paymentType,
        nakitOdeme: 0,
        kartOdeme: 0,
        status: "1",
        deliveryDate: orderInfoProvider.deliveryDate,
        comment: orderInfoProvider.comment,
      );

      // FisNo ve customerKod'u cart provider'a set et (cart_items'a kaydedilmek için)
      cartProvider.fisNo = fisNo;
      cartProvider.customerKod = customer.kod!;

      final fisJson = fisModel.toJson();
      final satirlarJson =
      cartProvider.items.values.map((item) => item.toJson()).toList();

      // Siparişi HER ZAMAN PendingSales'e kaydet
      await db.insert('PendingSales', {
        'fis': jsonEncode(fisJson),
        'satirlar': jsonEncode(satirlarJson),
      });

      // Aktivite logu oluştur
      final cartString = cartProvider.items.values
          .map((item) => item.toFormattedString())
          .join('\n----------------------\n');
      await activityRepository.addActivity(
        "Order placed\n${fisModel.toFormattedString()}\Satırlar:\n$cartString",
      );

      // Bu fisNo'ya ait cart_items kayıtlarını isPlaced=1 olarak işaretle
      await db.update(
        'cart_items',
        {'isPlaced': 1},
        where: 'fisNo = ?',
        whereArgs: [fisNo],
      );

      // Sepeti SADECE hafızadan (memory) temizle
      cartProvider.clearCartMemoryOnly();

      // Bir sonraki sipariş için YENİ fisNo oluştur
      await orderInfoProvider.generateNewOrderNo();

      // ✅ KRITIK: CartProvider'ı yeni fisNo ile senkronize et
      cartProvider.fisNo = orderInfoProvider.orderNo;

      // --- İşlem Sonrası ve Navigasyon ---

      // Bakiye bilgisini al (hata olsa bile devam et)
      String bakiye = "0.0";
      try {
        final customerData =
        await customerRepository.getCustomerByUnvan(customer.kod ?? "TURAN");
        bakiye = customerData?['bakiye']?.toString() ?? "0.0";
      } catch (e) {
        // Bakiye alınamazsa logla, ama işlemi durdurma
      }

      // Widget hala mounted ise UI işlemleri yap
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SizedBox(
            height: 10.h,
            child: Center(
              child: Text(
                'Order saved to Pending.',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );

      // Ana müşteri görünümüne dön
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CustomerView(bakiye: bakiye),
        ),
            (route) => false,
      );
    } catch (e) {
      // Genel hata yakalama
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e')),
        );
      }
    } finally {
      // Hata olsa da, başarılı olsa da butonu tekrar aktif et
      if (mounted) {
        setState(() => _isSubmittingOrder = false);
      }
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    // ✅ MİMARİ DÜZELTME: Provider'ı aktif olarak dinle
    // clearCart() çağrıldığında widget yeniden build edilsin
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items.values.toList().reversed.toList();

    final unitCount = cartItems
        .where((item) => item.birimTipi == _unitType)
        .fold<int>(0, (prev, item) => prev + item.miktar);

    final boxCount = cartItems
        .where((item) => item.birimTipi == _boxType)
        .fold<int>(0, (prev, item) => prev + item.miktar);

    final totalCount = unitCount + boxCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Cart Details", style: TextStyle(fontSize: 20.sp)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              if (cartProvider.items.isNotEmpty) {
                _showClearCartDialog(context, cartProvider);
              }
            },
            tooltip: 'Clear All Items',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(3.w),
        child: cartItems.isEmpty
            ? Center(
          child: Text(
            "Your cart is empty.",
            style: TextStyle(fontSize: 16.sp),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  // Her item için kendi state'ini yöneten bir kart oluştur
                  return _CartItemCard(
                    key: ValueKey(
                        '${item.stokKodu}_${item.birimTipi}'), // Benzersiz key
                    item: item,
                    imageFuture: _imageFutures[item.stokKodu],
                  );
                },
              ),
            ),
            const Divider(),
            _buildTotalsSection(
                context, unitCount, boxCount, totalCount, cartProvider),
            _buildPlaceOrderButton(context),
            SizedBox(height: 0.5.h),
            const Divider(),
          ],
        ),
      ),
    );
  }

  /// Sepeti temizle onay dialog'unu gösterir.
  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Cart"),
        content: const Text(
          "Are you sure you want to remove all items?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Loading göstergesi ekle
                Navigator.pop(ctx); // Dialog'u hemen kapat

                // Provider'ı temizle (DB ve memory)
                await cartProvider.clearCart();

                // UI state'ini (image cache) de temizle
                if (mounted) {
                  setState(() {
                    _imageFutures.clear();
                  });
                }

                // ✅ Kısa bir gecikme - Provider'ın notifyListeners'ın tamamlanmasını bekle
                await Future.delayed(const Duration(milliseconds: 100));

                // context mounted kontrolü
                if (!mounted || !context.mounted) return;

                // SnackBar göster
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cart cleared successfully.'),
                    duration: Duration(seconds: 2),
                  ),
                );

                // ✅ CartView'e geri dön
                Navigator.pop(context);
              } catch (e) {
                // Hata durumunda kullanıcıya bilgi ver
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing cart: $e')),
                  );
                }
              }
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  /// Sepet toplamlarını gösteren bölümü oluşturur.
  Widget _buildTotalsSection(
      BuildContext context,
      int unitCount,
      int boxCount,
      int totalCount,
      CartProvider cartProvider,
      ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Units: $unitCount',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
              ),
              Text(
                'Boxes: $boxCount',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
              ),
              Text(
                'Total Items: $totalCount',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildTotalRow("Total:",
              cartProvider.indirimsizToplamTutar.toStringAsFixed(2)),
          _buildTotalRow(
              "Total VAT:", cartProvider.toplamKdvTutari.toStringAsFixed(2)),
          _buildTotalRow("Discount",
              "- ${cartProvider.toplamIndirimTutari.toStringAsFixed(2)}"),
          _buildTotalRow(
              "Grand Total:", cartProvider.toplamTutar.toStringAsFixed(2)),
        ],
      ),
    );
  }

  /// Toplamlar bölümü için tek bir satır oluşturur.
  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// "Place Order" butonunu oluşturur.
  Widget _buildPlaceOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // _isSubmittingOrder true ise butonu disable et
        onPressed: _isSubmittingOrder ? null : _placeOrder,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          child: _isSubmittingOrder
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            "Place Order",
            style: TextStyle(fontSize: 18.sp),
          ),
        ),
      ),
    );
  }
}

// --- CART ITEM CARD WIDGET ---

/// Sepetteki tek bir ürünü temsil eden, kendi state'ini yöneten widget.
class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final Future<String?>? imageFuture;

  const _CartItemCard({
    super.key,
    required this.item,
    this.imageFuture,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  // Bu widget'a ait controller'lar ve focus node'lar
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _quantityController;
  late FocusNode _priceFocusNode;
  late FocusNode _discountFocusNode;
  late FocusNode _quantityFocusNode;

  // Focus değişikliklerinde eski değerleri saklamak için
  String _oldPriceValue = '';
  String _oldDiscountValue = '';
  String _oldQuantityValue = '';

  // ✅ Dinamik birim yönetimi
  List<BirimModel> _birimler = [];
  BirimModel? _selectedBirim;
  bool _birimlersLoading = true;

  @override
  void initState() {
    super.initState();

    // Controller'ları başlat
    _priceController = TextEditingController();
    _discountController = TextEditingController();
    _quantityController = TextEditingController();

    // Focus node'ları başlat
    _priceFocusNode = FocusNode();
    _discountFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();

    // Controller'ların text değerlerini widget'taki item'a göre ayarla
    _updateTextControllers(widget.item);

    // Focus listener'ları ekle
    _priceFocusNode.addListener(_onPriceFocusChange);
    _discountFocusNode.addListener(_onDiscountFocusChange);
    _quantityFocusNode.addListener(_onQuantityFocusChange);

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
        if (widget.item.selectedBirimKey != null) {
          _selectedBirim = _birimler.firstWhere(
            (b) => b.key == widget.item.selectedBirimKey,
            orElse: () => _birimler.isNotEmpty ? _birimler.first : BirimModel(key: '', birimadi: '', fiyat7: 0),
          );
        } else if (_birimler.isNotEmpty) {
          // Eğer selectedBirimKey yoksa, mevcut birimTipi'ne göre seç
          _selectedBirim = _birimler.firstWhere(
            (b) {
              final birimAdi = b.birimadi?.toLowerCase() ?? '';
              if (widget.item.birimTipi == 'Box') {
                return birimAdi.contains('box') || birimAdi.contains('koli') || birimAdi.contains('kutu');
              } else {
                return birimAdi.contains('unit') || birimAdi.contains('adet') || birimAdi.contains('pcs');
              }
            },
            orElse: () => _birimler.first,
          );
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
    // Listener'ları kaldır
    _priceFocusNode.removeListener(_onPriceFocusChange);
    _discountFocusNode.removeListener(_onDiscountFocusChange);
    _quantityFocusNode.removeListener(_onQuantityFocusChange);

    // Controller'ları dispose et
    _priceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();

    // Focus node'ları dispose et
    _priceFocusNode.dispose();
    _discountFocusNode.dispose();
    _quantityFocusNode.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(_CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provider'dan gelen veri değiştiyse (örn: miktar +/- butonları)
    // ve kullanıcı o anda o alanı düzenlemiyorsa, controller'ları güncelle.
    // Miktar, fiyat veya indirim değişikliklerini kontrol et
    if (widget.item.miktar != oldWidget.item.miktar ||
        widget.item.birimFiyat != oldWidget.item.birimFiyat ||
        widget.item.iskonto != oldWidget.item.iskonto) {
      _updateTextControllers(widget.item);
    }
  }

  /// Controller'ların metinlerini güncelleyen yardımcı metod.
  void _updateTextControllers(CartItem item) {
    // ✅ Fiyat controller'ı indirimli fiyatı gösterir (KDV'siz).
    // item.indirimliTutar KDV DAHİL tutar olduğu için direkt kullanamayız!
    // Doğru hesaplama: item.birimFiyat * (1 - item.iskonto / 100)
    final singleItemDiscountedPrice = item.birimFiyat * (1 - item.iskonto / 100);

    // ✅ MİMARİ İYİLEŞTİRME: Focus kontrolü ile güncelleme
    // Kullanıcı o alanı düzenlerken güncelleme yapma
    if (!_priceFocusNode.hasFocus) {
      final newPriceText = singleItemDiscountedPrice.toStringAsFixed(2);
      if (_priceController.text != newPriceText) {
        _priceController.text = newPriceText;
        _oldPriceValue = newPriceText;
      }
    }

    // İndirim controller'ı
    if (!_discountFocusNode.hasFocus) {
      final newDiscountText = item.iskonto > 0 ? item.iskonto.toString() : '';
      if (_discountController.text != newDiscountText) {
        _discountController.text = newDiscountText;
        _oldDiscountValue = newDiscountText;
      }
    }

    // ✅ Miktar controller'ı - Her zaman güncelle (optimistic update'te zaten güncelledik)
    // Ama provider'dan gelen değer farklıysa, provider'ı önceliklendir
    if (!_quantityFocusNode.hasFocus) {
      final newQuantityText = item.miktar.toString();
      if (_quantityController.text != newQuantityText) {
        _quantityController.text = newQuantityText;
        _oldQuantityValue = newQuantityText;
      }
    }
  }

  // --- Focus Listeners ---

  void _onPriceFocusChange() {
    if (_priceFocusNode.hasFocus) {
      // Focus kazanıldığında eski değeri sakla ve temizle
      _oldPriceValue = _priceController.text;
      _priceController.clear();
    } else {
      // Focus kaybedildiğinde, alan boşsa eski değeri geri yükle
      if (_priceController.text.isEmpty && _oldPriceValue.isNotEmpty) {
        _priceController.text = _oldPriceValue;
      }
      // Değer değiştiyse (boş değilse) formatla
      _formatPriceField();
    }
  }

  void _onDiscountFocusChange() {
    if (_discountFocusNode.hasFocus) {
      _oldDiscountValue = _discountController.text;
      _discountController.clear();
    } else {
      if (_discountController.text.isEmpty && _oldDiscountValue.isNotEmpty) {
        _discountController.text = _oldDiscountValue;
      }
    }
  }

  void _onQuantityFocusChange() {
    if (_quantityFocusNode.hasFocus) {
      _oldQuantityValue = _quantityController.text;
      _quantityController.clear();
    } else {
      if (_quantityController.text.isEmpty && _oldQuantityValue.isNotEmpty) {
        _quantityController.text = _oldQuantityValue;
      }
      // Miktar alanı submit edilmeden focus kaybederse,
      // onSubmitted'daki logic'i burada da tetikle
      _onQuantitySubmitted(_quantityController.text);
    }
  }

  // --- Event Handlers (onChanged, onSubmitted) ---

  /// Fiyat alanı manuel olarak değiştirildiğinde tetiklenir.
  void _onPriceChanged(String value) {
    final cleanValue = value.replaceAll(',', '.');
    final yeniFiyat = double.tryParse(cleanValue);

    if (yeniFiyat != null && yeniFiyat >= 0) {
      // Orijinal (indirimsiz) fiyatı al
      final orjinalFiyat = widget.item.birimFiyat;

      // İndirim yüzdesini hesapla (ondalıklı olarak 2 basamak)
      final indirimOrani = (orjinalFiyat > 0 && yeniFiyat < orjinalFiyat)
          ? double.parse((((orjinalFiyat - yeniFiyat) / orjinalFiyat * 100)).toStringAsFixed(2))
          : 0.0;

      // İndirim controller'ını güncelle - sadece focus değilse
      if (!_discountFocusNode.hasFocus) {
        _discountController.text = indirimOrani > 0 ? indirimOrani.toString() : '';
      }

      // Provider'ı güncelle (HER ZAMAN orjinal fiyat ve yeni indirim oranı ile)
      _updateProviderItem(iskonto: indirimOrani);
    }
  }

  /// Fiyat alanı submit edildiğinde veya focus kaybedildiğinde formatlar.
  void _formatPriceField() {
    final value = _priceController.text;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) {
      final formattedValue = parsed.toStringAsFixed(2);
      if (_priceController.text != formattedValue) {
        _priceController.text = formattedValue;
        _priceController.selection = TextSelection.fromPosition(
          TextPosition(offset: formattedValue.length),
        );
      }
    }
    _priceFocusNode.unfocus();
  }

  /// İndirim alanı manuel olarak değiştirildiğinde tetiklenir.
  void _onDiscountChanged(String value) {
    // Eğer kullanıcı alanı boşaltmak istiyorsa, indirimi sıfırla
    if (value.isEmpty) {
      // Fiyatı orjinal fiyata döndür
      _priceController.text = widget.item.birimFiyat.toStringAsFixed(2);
      // Provider'ı 0 indirim ile güncelle
      _updateProviderItem(iskonto: 0.0);
      return;
    }

    // İndirim yüzdesini al ve sınırla (ondalıklı olarak)
    double discountPercent = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    discountPercent = discountPercent.clamp(0.0, 100.0);

    // Orjinal fiyat HER ZAMAN item'ın kendi birim fiyatıdır.
    final originalPrice = widget.item.birimFiyat;

    // İndirim miktarını hesapla
    final discountAmount = (originalPrice * discountPercent) / 100;

    // İndirimli fiyatı hesapla
    final discountedPrice = originalPrice - discountAmount;

    // Fiyat controller'ını güncelle
    _priceController.text = discountedPrice.toStringAsFixed(2);

    // Provider'ı güncelle
    _updateProviderItem(iskonto: discountPercent);
  }

  /// Miktar alanı manuel olarak submit edildiğinde tetiklenir.
  void _onQuantitySubmitted(String value) {
    final newMiktar = int.tryParse(value) ?? 0;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (newMiktar <= 0) {
      cartProvider.removeItem(widget.item.stokKodu, widget.item.birimTipi);
    } else {
      final difference = newMiktar - widget.item.miktar;
      if (difference != 0) {
        _updateProviderItem(miktar: difference);
      }
    }
    _quantityFocusNode.unfocus();
  }

  /// Miktarı 1 artırır.
  void _incrementQuantity() {
    // ✅ MİMARİ: Focus kontrolünü kaldır, butona basınca TextField focus kaybetsin
    _quantityFocusNode.unfocus();

    // ✅ Optimistic UI Update: Controller'ı hemen güncelle (kullanıcı deneyimi)
    final newMiktar = widget.item.miktar + 1;
    _quantityController.text = newMiktar.toString();

    // Provider'ı güncelle
    _updateProviderItem(miktar: 1);
  }

  /// Miktarı 1 azaltır veya 0 ise siler.
  void _decrementQuantity() {
    // ✅ MİMARİ: Focus kontrolünü kaldır, butona basınca TextField focus kaybetsin
    _quantityFocusNode.unfocus();

    int newMiktar = widget.item.miktar - 1;
    if (newMiktar <= 0) {
      // ✅ Optimistic UI Update: Controller'ı hemen güncelle
      _quantityController.text = '0';

      Provider.of<CartProvider>(context, listen: false)
          .removeItem(widget.item.stokKodu, widget.item.birimTipi);
    } else {
      // ✅ Optimistic UI Update: Controller'ı hemen güncelle
      _quantityController.text = newMiktar.toString();

      _updateProviderItem(miktar: -1);
    }
  }

  /// Birim değiştirildiğinde tetiklenir (Dinamik birimler sistemi)
  void _onBirimChanged(BirimModel? newBirim) {
    if (newBirim == null) return;

    final item = widget.item;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // ✅ Yeni birimin fiyatını fiyat7'den al
    final fiyat = newBirim.fiyat7 ?? 0.0;

    // Fiyat kontrolü - eğer 0 veya null ise hata göster
    if (fiyat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${newBirim.birimadi} fiyatı bulunamadı ($fiyat).'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Seçili birimi güncelle
    setState(() {
      _selectedBirim = newBirim;
    });

    // ✅ Birim tipini belirle (Box/Unit - UI gösterimi için)
    final birimAdi = newBirim.birimadi?.toLowerCase() ?? '';
    final isBox = birimAdi.contains('box') || birimAdi.contains('koli') || birimAdi.contains('kutu');
    final newBirimTipi = isBox ? 'Box' : 'Unit';

    // ✅ KRITIK: Eski birimi silip yeni birimle ekle (birim değişiminde)
    if (newBirimTipi != item.birimTipi) {
      // Eski item'ın miktarını al
      final oldMiktar = item.miktar;

      // Eski item'ı sil (eski birim tipiyle)
      final oldCartKey = '${item.stokKodu}_${item.birimTipi}';
      cartProvider.removeItem(oldCartKey);

      // Yeni item'ı ekle (yeni birim tipiyle, eski miktarla)
      _updateProviderItem(
        birimFiyat: fiyat,
        birimTipi: newBirimTipi,
        selectedBirimKey: newBirim.key,
        miktar: oldMiktar, // ✅ Eski miktarı koru
        iskonto: item.iskonto,
      );
    } else {
      // Aynı birim seçildiyse sadece fiyatı güncelle
      _updateProviderItem(
        birimFiyat: fiyat,
        birimTipi: newBirimTipi,
        selectedBirimKey: newBirim.key,
        miktar: 0, // 0 = miktarı değiştirme
        iskonto: item.iskonto,
      );
    }
  }

  /// Provider'daki item'ı güncellemek için merkezi metod.
  /// `miktar` 0 ise mevcut miktarı korur (veya artırır/azaltır),
  /// `iskonto` null ise mevcut indirimi korur.
  void _updateProviderItem({
    int miktar = 0,
    double? iskonto,
    double? birimFiyat,
    String? birimTipi,
    String? selectedBirimKey,
  }) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider =
    Provider.of<SalesCustomerProvider>(context, listen: false);

    cartProvider.customerKod = customerProvider.selectedCustomer!.kod!;
    cartProvider.customerName = customerProvider.selectedCustomer!.unvan ??
        customerProvider.selectedCustomer!.kod!;

    cartProvider.addOrUpdateItem(
      stokKodu: widget.item.stokKodu,
      urunAdi: widget.item.urunAdi,
      birimFiyat: birimFiyat ??
          widget.item
              .birimFiyat, // Yeni fiyat yoksa eskisini kullan (orijinal)
      urunBarcode: widget.item.urunBarcode,
      miktar: miktar,
      iskonto: iskonto ?? widget.item.iskonto, // Yeni indirim yoksa eskisini
      birimTipi: birimTipi ?? widget.item.birimTipi, // Yeni birim yoksa eskisini
      durum: widget.item.durum,
      vat: widget.item.vat,
      imsrc: widget.item.imsrc,
      adetFiyati: widget.item.adetFiyati,
      kutuFiyati: widget.item.kutuFiyati,
      selectedBirimKey: selectedBirimKey ?? widget.item.selectedBirimKey, // ✅ Dinamik birim key'i
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final item = widget.item; // Daha kolay erişim için

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sol: Ürün görseli
                  _buildItemImage(),
                  SizedBox(width: 3.w),

                  // Sağ taraf: Bilgiler ve Kontroller
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ürün Adı ve Sil Butonu
                        _buildItemHeader(context, cartProvider),
                        SizedBox(height: 0.3.h),
                        // İlk satır: Dropdown | Fiyat | İndirim
                        _buildPriceRow(context),
                        SizedBox(height: 0.5.h),
                        // İkinci satır: Miktar kontrolleri
                        _buildQuantityRow(context),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              Center(
                child: Text(
                  'Final Price: ${item.indirimliTutar.toStringAsFixed(2)} - VAT:${item.vatTutari.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }

  /// Ürün görselini oluşturan widget.
  Widget _buildItemImage() {
    return (widget.item.imsrc == null || widget.item.imsrc!.isEmpty)
        ? Icon(Icons.shopping_bag_sharp, size: 25.w)
        : FutureBuilder<String?>(
      future: widget.imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: 30.w,
            height: 30.w,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Icon(Icons.shopping_bag, size: 25.w);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            File(snapshot.data!),
            width: 30.w,
            height: 30.w,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  /// Ürün adı ve sil butonunu oluşturan widget.
  Widget _buildItemHeader(BuildContext context, CartProvider cartProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.item.urunAdi,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => cartProvider.removeItem(
              widget.item.stokKodu, widget.item.birimTipi),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          iconSize: 2.2.h,
        ),
      ],
    );
  }

  /// Birim seçimi, fiyat ve indirim alanlarını oluşturan widget.
  Widget _buildPriceRow(BuildContext context) {
    return Row(
      children: [
        // Birim kontrolü (Dropdown veya Text)
        Expanded(
          flex: 2,
          child: _buildUnitSelector(context),
        ),
        SizedBox(width: 2.w),
        // Fiyat alanı
        Expanded(
          flex: 2,
          child: TextField(
            controller: _priceController,
            focusNode: _priceFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onPriceChanged,
            onSubmitted: (_) => _formatPriceField(),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(width: 2.w),
        // İndirim alanı
        Expanded(
          flex: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer,
                size: 18.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: TextField(
                  controller: _discountController,
                  focusNode: _discountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onDiscountChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    prefixText: '%',
                    prefixStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Miktar kontrol butonlarını ve alanını oluşturan widget.
  Widget _buildQuantityRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Miktar azaltma butonu (-)
          _buildQuantityButton(
            context,
            icon: Icons.remove,
            color: Theme.of(context).colorScheme.error,
            onPressed: _decrementQuantity,
          ),
          SizedBox(width: 1.w),
          // Miktar TextField - Fiyat alanıyla TAM AYNI stil
          Container(
            width: 12.w,
            child: TextField(
              controller: _quantityController,
              focusNode: _quantityFocusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onSubmitted: _onQuantitySubmitted,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(width: 1.w),
          // Miktar artırma butonu (+)
          _buildQuantityButton(
            context,
            icon: Icons.add,
            color: Theme.of(context).colorScheme.primary,
            onPressed: _incrementQuantity,
          ),
        ],
      ),
    );
  }

  /// Miktar artırma/azaltma için standart bir buton oluşturur.
  Widget _buildQuantityButton(BuildContext context,
      {required IconData icon,
        required Color color,
        required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  /// ✅ Dinamik birim seçimi için Dropdown widget'ı (fiyat7 ile)
  Widget _buildUnitSelector(BuildContext context) {
    // ✅ Birimler yüklenirken loading göster
    if (_birimlersLoading) {
      return Container(
        height: 40,
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

    // ✅ Birim bulunamadıysa eski sisteme fallback (adetFiyati/kutuFiyati)
    if (_birimler.isEmpty) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.item.birimTipi,
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // ✅ Dropdown ile dinamik birimleri göster
    return DropdownButtonFormField<BirimModel>(
      value: _selectedBirim,
      isDense: true,
      icon: const Icon(Icons.arrow_drop_down, size: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      style: TextStyle(
        fontSize: 16.sp,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      items: _birimler.map((birim) {
        return DropdownMenuItem<BirimModel>(
          value: birim,
          child: Text(
            birim.birimadi ?? '',
            style: TextStyle(fontSize: 14.sp),
          ),
        );
      }).toList(),
      onChanged: _birimler.length > 1 ? _onBirimChanged : null,
    );
  }
}