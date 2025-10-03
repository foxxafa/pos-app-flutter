import 'package:flutter/services.dart';

/// El terminali (handheld scanner) tuş tespiti için merkezi servis
class ScannerService {
  // Scanner tuşları için USB HID kodları
  static const Set<int> _scannerPhysicalKeys = {
    392983,       // KEYCODE_SCANNER_RIGHT (Game Button Right 1)
    73014444098,  // KEYCODE_SCANNER_RIGHT alternatif
    73014444272,  // KEYCODE_SCANNER_BOTTOM (Key with ID 0x11000000f0)
    0x070053,     // Num Lock
    0x070054,     // Keypad /
  };

  // LogicalKey ID kontrolü (Sunmi ve diğerleri)
  static const Set<int> _scannerLogicalKeys = {
    73014444321,  // KEYCODE_SCANNER_RIGHT
    73014444322,  // KEYCODE_SCANNER_BOTTOM
    4294967309,   // Alternatif scanner key
    0x01100000209,
    0x01100000208,
    4294967556,
    73014445159,
  };

  /// Scanner tuşu olup olmadığını kontrol eder
  static bool isScannerKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isPhysicalMatch = _scannerPhysicalKeys.contains(event.physicalKey.usbHidUsage);
    final isLogicalMatch = _scannerLogicalKeys.contains(event.logicalKey.keyId);

    return isPhysicalMatch || isLogicalMatch;
  }

  /// Scanner key handler oluşturur
  /// [onScannerKeyPressed] scanner tuşuna basıldığında çağrılacak callback
  static bool Function(KeyEvent) createHandler(VoidCallback onScannerKeyPressed) {
    return (KeyEvent event) {
      if (isScannerKey(event)) {
        onScannerKeyPressed();
        return true; // Event'i handle ettik
      }
      return false; // Event'i başkası da görebilir
    };
  }
}
