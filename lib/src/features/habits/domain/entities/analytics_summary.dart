class AnalyticsHabitStat {
  final String habitId;
  final String title;
  final String colorHex;
  final int completions;
  final int currentStreak;
  final int longestStreak;

  const AnalyticsHabitStat({
    required this.habitId,
    required this.title,
    required this.colorHex,
    required this.completions,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory AnalyticsHabitStat.fromJson(Map<String, dynamic> json) {
    return AnalyticsHabitStat(
      habitId: json['habitId'] as String,
      title: json['title'] as String,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      completions: json['completions'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
    );
  }
}

class AnalyticsHeatmapPoint {
  final DateTime date;
  final int count;

  const AnalyticsHeatmapPoint({
    required this.date,
    required this.count,
  });

  factory AnalyticsHeatmapPoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsHeatmapPoint(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}

class AnalyticsTimeBucket {
  final String label;
  final int count;

  const AnalyticsTimeBucket({
    required this.label,
    required this.count,
  });

  factory AnalyticsTimeBucket.fromJson(Map<String, dynamic> json) {
    return AnalyticsTimeBucket(
      label: json['label'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class AnalyticsSummary {
  final int totalActiveHabits;
  final int totalCompletedLast7Days;
  final int totalCompletedLast30Days;
  final double weeklySuccessRate;
  final double monthlySuccessRate;
  final int maxActiveStreak;
  final String mostProductiveWeekday;
  final String bestCompletionWindow;
  final List<AnalyticsHabitStat> topHabits;
  final List<AnalyticsHabitStat> needsAttentionHabits;
  final List<AnalyticsHeatmapPoint> heatmap;
  final List<AnalyticsTimeBucket> timeBuckets;

  const AnalyticsSummary({
    required this.totalActiveHabits,
    required this.totalCompletedLast7Days,
    required this.totalCompletedLast30Days,
    required this.weeklySuccessRate,
    required this.monthlySuccessRate,
    required this.maxActiveStreak,
    required this.mostProductiveWeekday,
    required this.bestCompletionWindow,
    required this.topHabits,
    required this.needsAttentionHabits,
    required this.heatmap,
    required this.timeBuckets,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalActiveHabits: json['totalActiveHabits'] as int? ?? 0,
      totalCompletedLast7Days: json['totalCompletedLast7Days'] as int? ?? 0,
      totalCompletedLast30Days: json['totalCompletedLast30Days'] as int? ?? 0,
      weeklySuccessRate: (json['weeklySuccessRate'] as num?)?.toDouble() ?? 0,
      monthlySuccessRate: (json['monthlySuccessRate'] as num?)?.toDouble() ?? 0,
      maxActiveStreak: json['maxActiveStreak'] as int? ?? 0,
      mostProductiveWeekday: json['mostProductiveWeekday'] as String? ?? 'Sin datos',
      bestCompletionWindow: json['bestCompletionWindow'] as String? ?? 'Sin datos',
      topHabits: ((json['topHabits'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsHabitStat.fromJson)
          .toList(),
      needsAttentionHabits: ((json['needsAttentionHabits'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsHabitStat.fromJson)
          .toList(),
      heatmap: ((json['heatmap'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsHeatmapPoint.fromJson)
          .toList(),
      timeBuckets: ((json['timeBuckets'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsTimeBucket.fromJson)
          .toList(),
    );
  }
}
