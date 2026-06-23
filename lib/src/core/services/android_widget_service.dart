import 'package:flutter/services.dart';

class AndroidWidgetService {
  static const MethodChannel _channel = MethodChannel('habitu/widget');

  Future<void> updateTodaySummary({
    required int completedCount,
    required int totalCount,
    String? routineId,
    String? routineTitle,
    String? pendingHabitId,
    String? pendingHabitTitle,
  }) async {
    try {
      await _channel.invokeMethod<void>('updateTodaySummary', {
        'completedCount': completedCount,
        'totalCount': totalCount,
        'routineId': routineId,
        'routineTitle': routineTitle,
        'pendingHabitId': pendingHabitId,
        'pendingHabitTitle': pendingHabitTitle,
      });
    } catch (_) {
      // Android-only best effort.
    }
  }
}
