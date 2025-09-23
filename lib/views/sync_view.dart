import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pos_app/controllers/sync_controller.dart';
import 'package:pos_app/controllers/transaction_controller.dart';
import 'package:pos_app/models/cheque_model.dart';
import 'package:pos_app/models/transaction_model.dart';
import 'package:pos_app/views/menu_view.dart';
import 'package:sizer/sizer.dart';
import 'package:pos_app/core/local/database_helper.dart'; // Sizer import

class SyncView extends StatefulWidget {
  @override
  _SyncViewState createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  final SyncController _syncController = SyncController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _handleCleanSync() async {
    setState(() {
      _isLoading = true;
      _message = "Don't close the page, syncing...";
    });

    try {

      

    await _syncController.cleanSync();
          await _syncController.SyncAllRefunds();


     // await _syncController.cleanSync();
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

          await _syncController.updateSync();
      await _syncController.syncPendingRefunds();
      await _syncController.SyncAllRefunds();
 
  
  


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
                //             await _syncController.SyncAllRefunds();
                //             setState(() => _isLoading = false);
                //           },
                //   child: Text("Sync Refunds"),
                // ),
//                 ElevatedButton(
//   onPressed: () async {
//     await _syncController.syncPendingRefunds();
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
                //       SyncController syncController = SyncController();
                //       syncController.syncPendingSales();
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

                       

bool success=false;
                        if (data['cekno']==null) {
   success = await TahsilatController().sendTahsilat(
    context,
    tahsilat,
    method,
  );
}else{
   final cektahsilat = ChequeModel(
                          tutar: (data['tutar'] as num).toDouble(),
                          aciklama: data['aciklama'],
                          carikod: data['carikod'],
                          username: data['username'],
                          cekno: data['cekno'],

                        );
   success = await TahsilatController().sendTahsilat(
    context,
tahsilat,
    method,cheque_model: cektahsilat
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
                      SyncController syncController = SyncController();
                      syncController.syncPendingSales();

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
