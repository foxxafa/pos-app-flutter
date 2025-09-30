// lib/features/reports/data/repositories/activity_repository_impl.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_app/features/reports/domain/entities/activity_model.dart';
import 'package:pos_app/features/reports/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  static const String _key = 'recent_activities';
  static const int _maxActivities = 20;

  @override
  Future<List<String>> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  @override
  Future<List<ActivityModel>> loadParsedActivities() async {
    final rawActivities = await loadActivities();
    return rawActivities
        .where((raw) => raw.isNotEmpty)
        .map((raw) => ActivityModel.fromRawString(raw))
        .where((model) => model.no.isNotEmpty) // Only include activities with order number
        .toList();
  }

  @override
  Future<void> addActivity(String activity) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];

    // Add new activity at the beginning (most recent first)
    current.insert(0, activity);

    // Keep only the most recent activities
    if (current.length > _maxActivities) {
      current.removeLast();
    }

    await prefs.setStringList(_key, current);
  }

  @override
  Future<void> removeActivityByOrderNo(String fisNo) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_key) ?? [];

    // Filter out activities that contain the order number
    final filtered = activities.where((activity) {
      return !(activity.contains("Order") && activity.contains(fisNo));
    }).toList();

    await prefs.setStringList(_key, filtered);
  }

  @override
  Future<void> updateActivityTotal({
    required String fisNo,
    required String newTotal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_key) ?? [];

    final updated = activities.map((activity) {
      // Check if this activity is an order with the matching fisNo
      if (activity.contains('Order placed') &&
          activity.contains('Fiş No') &&
          activity.contains(fisNo)) {
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

  @override
  Future<void> clearActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}