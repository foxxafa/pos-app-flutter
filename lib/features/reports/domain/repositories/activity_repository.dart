// lib/features/reports/domain/repositories/activity_repository.dart
import 'package:pos_app/features/reports/domain/entities/activity_model.dart';

abstract class ActivityRepository {
  /// Load all recent activities from local storage
  Future<List<String>> loadActivities();

  /// Load activities parsed as ActivityModel
  Future<List<ActivityModel>> loadParsedActivities();

  /// Add a new activity to recent activities
  Future<void> addActivity(String activity);

  /// Remove activity by order number (fisNo)
  Future<void> removeActivityByOrderNo(String fisNo);

  /// Update activity total amount by order number
  Future<void> updateActivityTotal({
    required String fisNo,
    required String newTotal,
  });

  /// Clear all activities
  Future<void> clearActivities();
}