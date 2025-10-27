import 'package:flutter/services.dart';

/// El terminali (handheld scanner) tuş tespiti için merkezi servis
class ScannerService {
  // 🛡️ Duplicate scan prevention
  static DateTime? _lastScanTime;
  static const int _debounceMilliseconds = 300; // 300ms debounce

  // Scanner tuşları için USB HID kodları
  static const Set<int> _scannerPhysicalKeys = {
    392983,       // KEYCODE_SCANNER_RIGHT (Game Button Right 1)
    73014444098,  // KEYCODE_SCANNER_RIGHT alternatif
    73014444272,  // KEYCODE_SCANNER_BOTTOM (Key with ID 0x11000000f0)
    458820,       // Terminal 1 USB HID
    458881,       // Terminal 2 USB HID
    0x070053,     // Num Lock
    0x070054,     // Keypad /
  };

  // LogicalKey ID kontrolü (Sunmi ve diğerleri)
  static const Set<int> _scannerLogicalKeys = {
    73014444321,  // KEYCODE_SCANNER_RIGHT
    73014444322,  // KEYCODE_SCANNER_BOTTOM
    73014444552,  // Terminal 3 Logical ID
    73014444553,  // Terminal 4 Logical ID (0x01100000209)
    4294967309,   // Alternatif scanner key
    4294969355,   // Terminal 1 Logical ID
    4294969871,   // Terminal 2 Logical ID
    73014444296,  // 0x01100000208
    4294967556,   // Eski scanner key
    73014445159,  // Eski scanner key
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
        // 🛡️ Duplicate scan prevention: Çok hızlı ardışık tuşları ignore et
        final now = DateTime.now();
        if (_lastScanTime != null) {
          final timeDiff = now.difference(_lastScanTime!).inMilliseconds;
          if (timeDiff < _debounceMilliseconds) {
            print('⚠️ ScannerService: Duplicate scan ignored (${timeDiff}ms ago)');
            return true; // Event'i handle ettik ama callback çağırmadık
          }
        }

        // ✅ Yeni scan - kaydet ve callback çağır
        _lastScanTime = now;
        print('✅ ScannerService: Scanner key detected');
        onScannerKeyPressed();
        return true; // Event'i handle ettik
      }
      return false; // Event'i başkası da görebilir
    };
  }
}
