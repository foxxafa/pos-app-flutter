import 'package:shared_preferences/shared_preferences.dart';

class RecentActivityController {
  static const String _key = 'recent_activities';

  static Future<List<String>> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> removeActivityByOrderNo(String fisNo) async {
  final prefs = await SharedPreferences.getInstance();
  final activities = prefs.getStringList(_key) ?? [];

  // Order no içeren activity'yi filtrele (silmek için)
  final filtered = activities.where((activity) {
    // Burada order no'yu içermeyenler kalacak, order no'yu içeren silinecek
    return !(activity.contains("Order") && activity.contains(fisNo));
  }).toList();

  await prefs.setStringList(_key, filtered);
}

static Future<void> updateActivityTotal({
  required String fisNo,
  required String newTotal,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final activities = prefs.getStringList(_key) ?? [];

  final updated = activities.map((activity) {
    if (activity.contains('Order placed') && activity.contains('Fiş No') && activity.contains(fisNo)) {
      final lines = activity.split('\n');
      final updatedLines = lines.map((line) {
        if (line.contains('Toplam Tutar')) {
          return 'Toplam Tutar   : $newTotal';
        }
        return line;
      }).toList();
      return updatedLines.join('\n');
    }
    return activity;
  }).toList();

  await prefs.setStringList(_key, updated);
}

  static Future<void> addActivity(String activity) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.insert(0, activity); // en yeni başa eklensin
    if (current.length > 20) {
      current.removeLast(); // max 20 kayıt tut
    }
    await prefs.setStringList(_key, current);
  }

  static Future<void> clearActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class RefundOrderSummary {
  final String date;
  final String no;
  final String type;
  final String total;

  RefundOrderSummary({
    required this.date,
    required this.no,
    required this.type,
    required this.total,
  });
}

List<RefundOrderSummary> parseRefundActivities(List<String> rawOrders) {
  final result = <RefundOrderSummary>[];

  for (final raw in rawOrders) {
    final lines = raw.split('\n');

    String date = '';
    String no = '';
    String type = '';
    String total = '';

    for (final line in lines) {
      if (line.contains('Fiş Tarihi')) {
        date = line.split(':').last.trim();
      } else if (line.contains('Fiş No')) {
        no = line.split(':').last.trim();
      } else if (line.contains('Ödeme Türü')) {
        type = line.split(':').last.trim();
      } else if (line.contains('Toplam Tutar')) {
        total = line.split(':').last.trim();
      }
    }

    if (no.isNotEmpty) {
      result.add(RefundOrderSummary(
        date: date,
        no: no,
        type: type,
        total: total,
      ));
    }
  }

  return result;
}
