// lib/core/utils/fisno_generator.dart

/// FisNo (Sipariş Numarası) üretimi için utility class
///
/// Format: MO + YY + MM + DD + ÇalışanID(2) + Dakika(2) + Mikrosaniye(4)
/// Örnek: MO250724053539746
///
/// Breakdown:
/// - MO: Prefix (Mobil Order)
/// - 25: Yıl (2025)
/// - 07: Ay (Temmuz)
/// - 24: Gün (24)
/// - 05: Çalışan ID (1-99 arası)
/// - 35: Dakika (00-59)
/// - 39746: Mikrosaniye (Saniye * 1000 + Milisaniye) mod 10000 = (39 * 1000 + 746) % 10000 = 39746
///
/// Mikrosaniye formatı dakika başına 60.000 farklı kombinasyon sunar (0-59999 arası)
class FisNoGenerator {
  /// Benzersiz FisNo üretir
  ///
  /// [userId]: Çalışan ID'si (1-99 arası önerilir)
  ///
  /// Returns: 15 karakterlik benzersiz FisNo
  ///
  /// Örnek kullanım:
  /// ```dart
  /// final fisNo = FisNoGenerator.generate(userId: 5);
  /// print(fisNo); // MO250724053539746
  /// ```
  static String generate({required int userId}) {
    final now = DateTime.now();

    // Yıl (son 2 basamak)
    final yy = (now.year % 100).toString().padLeft(2, '0');

    // Ay
    final mm = now.month.toString().padLeft(2, '0');

    // Gün
    final dd = now.day.toString().padLeft(2, '0');

    // Çalışan ID (1-99 arası, 2 basamak)
    // Eğer 99'dan büyükse mod 100 al
    final employeeId = (userId % 100).toString().padLeft(2, '0');

    // Dakika (00-59)
    final dakika = now.minute.toString().padLeft(2, '0');

    // Mikrosaniye: (Saniye * 1000 + Milisaniye) % 10000
    // Bu bize 0-59999 arası bir değer verir (4 basamak)
    // Örnek: 10:50:39.746 → (39 * 1000 + 746) % 10000 = 39746
    final mikrosaniye = ((now.second * 1000) + now.millisecond) % 10000;
    final mikroStr = mikrosaniye.toString().padLeft(4, '0');

    final fisNo = 'MO$yy$mm$dd$employeeId$dakika$mikroStr';

    print('🔢 FisNo üretildi: $fisNo');
    print('   📅 Tarih: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}.${now.millisecond}');
    print('   👤 Çalışan ID: $userId');
    print('   ⏱️  Mikrosaniye: $mikrosaniye (${now.second}s * 1000 + ${now.millisecond}ms)');

    return fisNo;
  }

  /// FisNo'dan bilgileri parse eder (debugging ve raporlama için)
  ///
  /// [fisNo]: Parse edilecek FisNo
  ///
  /// Returns: FisNo içindeki bilgileri içeren Map
  ///
  /// Örnek kullanım:
  /// ```dart
  /// final info = FisNoGenerator.parse('MO250724053539746');
  /// print(info['userId']); // 5
  /// print(info['year']); // 2025
  /// ```
  static Map<String, dynamic> parse(String fisNo) {
    if (fisNo.length != 15 || !fisNo.startsWith('MO')) {
      return {
        'error': 'Geçersiz FisNo formatı',
        'expected': 'MO + YY(2) + MM(2) + DD(2) + UserID(2) + Minute(2) + Microsecond(4)',
        'received': fisNo,
      };
    }

    try {
      final microsecond = int.parse(fisNo.substring(11, 15));
      final second = microsecond ~/ 1000;  // Saniye kısmını çıkar
      final millisecond = microsecond % 1000;  // Milisaniye kısmını çıkar

      return {
        'prefix': fisNo.substring(0, 2),           // MO
        'year': '20${fisNo.substring(2, 4)}',      // 2025
        'month': fisNo.substring(4, 6),            // 07
        'day': fisNo.substring(6, 8),              // 24
        'userId': int.parse(fisNo.substring(8, 10)), // 05
        'minute': fisNo.substring(10, 12),         // 35
        'microsecond': fisNo.substring(11, 15),    // 39746
        'second': second,                          // 39 (hesaplanmış)
        'millisecond': millisecond,                // 746 (hesaplanmış)
        'fullDate': '20${fisNo.substring(2, 4)}-${fisNo.substring(4, 6)}-${fisNo.substring(6, 8)}',
        'isValid': true,
      };
    } catch (e) {
      return {
        'error': 'Parse hatası: $e',
        'isValid': false,
      };
    }
  }

  /// İki FisNo'yu karşılaştırır (sıralama için)
  ///
  /// Returns:
  /// - Negatif değer: fisNo1 < fisNo2
  /// - 0: fisNo1 == fisNo2
  /// - Pozitif değer: fisNo1 > fisNo2
  static int compare(String fisNo1, String fisNo2) {
    return fisNo1.compareTo(fisNo2);
  }

  /// FisNo'nun geçerli olup olmadığını kontrol eder
  ///
  /// [fisNo]: Kontrol edilecek FisNo
  ///
  /// Returns: true ise geçerli, false ise geçersiz
  static bool isValid(String fisNo) {
    if (fisNo.length != 15) return false;
    if (!fisNo.startsWith('MO')) return false;

    // Sadece MO prefix'i hariç geri kalan rakam olmalı
    final numbers = fisNo.substring(2);
    return RegExp(r'^\d{13}$').hasMatch(numbers);
  }

  /// Belirli bir tarih aralığındaki FisNo'ları filtreler
  ///
  /// [fisNoList]: FisNo listesi
  /// [startDate]: Başlangıç tarihi
  /// [endDate]: Bitiş tarihi
  ///
  /// Returns: Tarih aralığında olan FisNo'lar
  static List<String> filterByDateRange(
    List<String> fisNoList,
    DateTime startDate,
    DateTime endDate,
  ) {
    return fisNoList.where((fisNo) {
      final parsed = parse(fisNo);
      if (parsed['error'] != null) return false;

      try {
        final fisDate = DateTime.parse(parsed['fullDate']);
        return fisDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               fisDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Belirli bir çalışana ait FisNo'ları filtreler
  ///
  /// [fisNoList]: FisNo listesi
  /// [userId]: Çalışan ID'si
  ///
  /// Returns: Çalışana ait FisNo'lar
  static List<String> filterByUser(List<String> fisNoList, int userId) {
    final targetUserId = (userId % 100).toString().padLeft(2, '0');

    return fisNoList.where((fisNo) {
      if (fisNo.length != 15) return false;
      final fisUserId = fisNo.substring(8, 10);
      return fisUserId == targetUserId;
    }).toList();
  }
}