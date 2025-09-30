// lib/features/reports/domain/entities/activity_model.dart

/// Recent activity summary model for orders and refunds
class ActivityModel {
  final String date;
  final String no;
  final String type;
  final String total;
  final String rawActivity; // Full activity text

  ActivityModel({
    required this.date,
    required this.no,
    required this.type,
    required this.total,
    required this.rawActivity,
  });

  factory ActivityModel.fromRawString(String rawActivity) {
    final lines = rawActivity.split('\n');

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

    return ActivityModel(
      date: date,
      no: no,
      type: type,
      total: total,
      rawActivity: rawActivity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'no': no,
      'type': type,
      'total': total,
      'rawActivity': rawActivity,
    };
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      date: json['date'] ?? '',
      no: json['no'] ?? '',
      type: json['type'] ?? '',
      total: json['total'] ?? '',
      rawActivity: json['rawActivity'] ?? '',
    );
  }
}