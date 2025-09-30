import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:easy_localization/easy_localization.dart';

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String barcode) onScanned;
  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cart.scan'.tr())),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isProcessing) return; // Zaten işlem yapılıyorsa çık

          final barcode = capture.barcodes.firstOrNull?.rawValue;
          if (barcode != null && barcode.isNotEmpty) {
            _isProcessing = true; // İşlem başladı

            widget.onScanned(barcode);

            // Güvenli navigation
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    );
  }
}