import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/core/sync/sync_service.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/orders/domain/repositories/order_repository.dart';
import 'package:pos_app/features/products/domain/repositories/product_repository.dart';
import 'package:pos_app/features/refunds/domain/repositories/refund_repository.dart';
import 'package:pos_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:pos_app/features/transactions/domain/entities/cheque_model.dart';
import 'package:pos_app/features/transactions/domain/entities/transaction_model.dart';
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';
import 'package:pos_app/core/widgets/menu_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart'; // Sizer import

class SyncView extends StatefulWidget {
  @override
  _SyncViewState createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  late SyncService _syncService;
  bool _isLoading = false;
  String _message = '';

  // 🔑 El terminali key tespiti için
  final ValueNotifier<List<Map<String, dynamic>>> _currentPressKeysNotifier = ValueNotifier([]);
  Timer? _keyGroupTimer;
  final List<Map<String, dynamic>> _tempKeyBuffer = [];

  // Hardware keyboard handler
  @override
  void initState() {
    super.initState();
    // Hardware keyboard event'lerini dinle
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _keyGroupTimer?.cancel();
    _currentPressKeysNotifier.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // PhysicalKeyboardKey'den bilgi çek
      final physicalKey = event.physicalKey;

      final keyInfo = {
        'keyId': event.logicalKey.keyId,
        'label': event.logicalKey.keyLabel,
        'physicalKey': physicalKey.debugName ?? physicalKey.usbHidUsage.toString(),
        'physicalKeyID': physicalKey.usbHidUsage,
        'eventType': 'KeyDown',
        'timestamp': DateTime.now().toString(),
      };

      // Aynı tuşu tekrar ekleme
      final existingIndex = _tempKeyBuffer.indexWhere((k) =>
        k['physicalKeyID'] == keyInfo['physicalKeyID']);

      if (existingIndex == -1) {
        _tempKeyBuffer.add(keyInfo);
      }

      // Debug konsola yazdır
      print('🔑 Hardware Key Detected: LogicalID=${event.logicalKey.keyId}, '
            'Physical=${event.physicalKey.debugName}, '
            'USB_HID=${event.physicalKey.usbHidUsage}');

      // Timer'ı iptal et ve yeni başlat
      _keyGroupTimer?.cancel();
      _keyGroupTimer = Timer(Duration(milliseconds: 200), () {
        // 200ms sonra hala key gelmediyse, buffer'daki tüm keyleri göster
        if (_tempKeyBuffer.isNotEmpty) {
          _currentPressKeysNotifier.value = List.from(_tempKeyBuffer);
          print('📋 Scanner Press Complete - Total keys: ${_tempKeyBuffer.length}');
          _tempKeyBuffer.clear();
        }
      });
    }
    return false; // Event'i başka widgetlar da alsın
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncService = SyncService(
      customerRepository: Provider.of<CustomerRepository>(context, listen: false),
      orderRepository: Provider.of<OrderRepository>(context, listen: false),
      productRepository: Provider.of<ProductRepository>(context, listen: false),
      refundRepository: Provider.of<RefundRepository>(context, listen: false),
    );
  }

  Future<void> _handleCleanSync() async {
    setState(() {
      _isLoading = true;
      _message = "Don't close the page, syncing...";
    });

    try {

      

    await _syncService.cleanSync();
          await _syncService.SyncAllRefunds();


     // await _syncService.cleanSync();
      print("refundsssssssssss");

    } on SocketException {
      // İnternet yoksa popup göster
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Connection Error'),
              content: Text(
                'No internet connection. Please check your network.',
              ),
              actions: [
                TextButton(
                  onPressed:
                      () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MenuView()),
                        (Route<dynamic> route) => false,
                      ),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return null;
    }

    setState(() {
      _isLoading = false;
      _message = 'Sync completed.';

           ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: SizedBox(
                                    height: 15.h,
                                    child: Center(
                                      child: Text(
                                        'Full Sync Completed',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
    });
  }

  Future<void> _handleUpdateSync() async {
    setState(() {
      _isLoading = true;
      _message = 'Updating sync...';
    });

    try {

          await _syncService.updateSync();
      await _syncService.syncPendingRefunds();
      await _syncService.SyncAllRefunds();
 
  
  


    } on SocketException {
      // İnternet yoksa popup göster
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Connection Error'),
              content: Text(
                'No internet connection. Please check your network.',
              ),
              actions: [
                TextButton(
                  onPressed:
                      () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MenuView()),
                        (Route<dynamic> route) => false,
                      ),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return null;
    }

    setState(() {
      _isLoading = false;
      _message = 'Update Sync completed.';

      ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: SizedBox(
                                    height: 15.h,
                                    child: Center(
                                      child: Text(
                                        'Update Sync completed.',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
    });
  }

  // 🔑 El terminali key ID tespit dialog'u
  void _showKeyDetectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _currentPressKeysNotifier,
        builder: (context, detectedKeys, child) {
          return AlertDialog(
            title: Text('Scanner Key Debug', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 80.w,
              height: 60.h,
              child: detectedKeys.isEmpty
                  ? Center(
                      child: Text(
                        'Press scanner button...',
                        style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < detectedKeys.length; i++) ...[
                            if (i > 0) Divider(height: 4.h, thickness: 2),
                            Text(
                              'Key ${i + 1}',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            _buildBigKeyInfo('Logical ID', detectedKeys[i]['keyId'].toString()),
                            SizedBox(height: 2.h),
                            _buildBigKeyInfo('Physical', detectedKeys[i]['physicalKey'].toString()),
                            SizedBox(height: 2.h),
                            _buildBigKeyInfo('USB HID', detectedKeys[i]['physicalKeyID'].toString()),
                          ],
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBigKeyInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      // Sizer ile sarmalıyoruz
      builder: (context, orientation, deviceType) {
        return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.home, size: 28.sp),
                tooltip: 'Return to Menu',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MenuView()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              title: Text('Sync View', style: TextStyle(fontSize: 18.sp)),
              actions: [
                // 🔑 Key tespit butonu
                IconButton(
                  icon: Icon(Icons.settings_remote, size: 24.sp),
                  tooltip: 'El Terminali Key Tespiti',
                  onPressed: _showKeyDetectionDialog,
                ),
              ],
            ),
            body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ElevatedButton(
                //   onPressed:
                //       _isLoading
                //           ? null
                //           : () async {
                //             setState(() => _isLoading = true);
                //             await _syncService.SyncAllRefunds();
                //             setState(() => _isLoading = false);
                //           },
                //   child: Text("Sync Refunds"),
                // ),
//                 ElevatedButton(
//   onPressed: () async {
//     await _syncService.syncPendingRefunds();
//   },
//   child: Text("Send pending refunds"),
// ),

                ElevatedButton(
                  onPressed: () async {
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    if (connectivityResult[0] == ConnectivityResult.none) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please connect to Internet.'),
                        ),
                      );
                    } else {
                      _isLoading ? null : _handleCleanSync();
                    }
                  },
                  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 10.h), // genişlik, yükseklik
  ),
                  child: Text(
                    'Initial SETUP / Reset Data',
                    style: TextStyle(fontSize: 19.sp),
                  ),
                ),
                SizedBox(height: 3.h),
                // ElevatedButton(
                //   onPressed: () async {
                //     final connectivityResult =
                //         await Connectivity().checkConnectivity();
                //     if (connectivityResult[0] == ConnectivityResult.none) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //           content: Text('Please connect to Internet.'),
                //         ),
                //       );
                //     } else {
                //       _isLoading ? null : _handleUpdateSync();
                //     }
                //   },
                //   style: ElevatedButton.styleFrom(
                //     padding: EdgeInsets.symmetric(vertical: 2.h),
                //   ),
                //   child: Text('Update Data', style: TextStyle(fontSize: 15.sp)),
                // ),
                // SizedBox(height: 3.h),
                // ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //     padding: EdgeInsets.symmetric(vertical: 2.h),
                //   ),
                //   onPressed: () async {
                //     final connectivityResult =
                //         await Connectivity().checkConnectivity();
                //     if (connectivityResult[0] == ConnectivityResult.none) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //           content: Text('Please connect to Internet.'),
                //         ),
                //       );
                //     } else {
                //       SyncService syncService = SyncService();
                //       syncService.syncPendingSales();
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(content: Text('Orders sent.')),
                //       );
                //     }
                //   },
                //   child: const Text('Send Pending Orders'),
                // ),
                // SizedBox(height: 3.h),
                ElevatedButton(
                   style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 10.h), // genişlik, yükseklik
  ),
                  onPressed: () async {
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    if (connectivityResult[0] == ConnectivityResult.none) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please connect to Internet.'),
                        ),
                      );
                    } else {
                      DatabaseHelper dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

                      final List<Map<String, dynamic>> records = await db.query(
                        'tahsilatlar',
                      );

                      final transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
                      final apiKey = Provider.of<UserProvider>(context, listen: false).apikey;

                      for (var record in records) {
                        final Map<String, dynamic> data = jsonDecode(
                          record['data'],
                        );
                        final String method = record['method'];

                        final tahsilat = TahsilatModel(
                          tutar: (data['tutar'] as num).toDouble(),
                          aciklama: data['aciklama'],
                          carikod: data['carikod'],
                          username: data['username'],
                        );

                        bool success = false;
                        if (data['cekno'] == null) {
                          success = await transactionRepository.sendTahsilat(
                            model: tahsilat,
                            method: method,
                            apiKey: apiKey,
                          );
                        } else {
                          final cektahsilat = ChequeModel(
                            tutar: (data['tutar'] as num).toDouble(),
                            aciklama: data['aciklama'],
                            carikod: data['carikod'],
                            username: data['username'],
                            cekno: data['cekno'],
                          );
                          success = await transactionRepository.sendTahsilat(
                            model: tahsilat,
                            method: method,
                            apiKey: apiKey,
                            chequeModel: cektahsilat,
                          );
                        }

                        if (success) {
                          await db.delete(
                            'tahsilatlar',
                            where: 'id = ?',
                            whereArgs: [record['id']],
                          );
                        }
                      }
                      _syncService.syncPendingSales();

                      if (connectivityResult[0] == ConnectivityResult.none) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please connect to Internet.'),
                          ),
                        );
                      } else {
                        _isLoading ? null : _handleUpdateSync();
                      }
                      // Database açık kalacak - App Inspector için

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Pending transactions processed.",
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text("Sync Data",                            style: TextStyle(fontSize: 22.sp),
),
                ),
                SizedBox(height: 5.h),
                if (_isLoading) Center(child: CircularProgressIndicator()),
                if (_message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Center(
                      child: Text(
                        _message,
                        style: TextStyle(fontSize: 18.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
