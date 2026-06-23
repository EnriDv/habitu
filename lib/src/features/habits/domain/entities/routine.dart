class RoutineSummary {
  final String id;
  final String title;
  final String? description;
  final String timeOfDay;
  final String? anchorTime;
  final List<int> daysOfWeek;
  final int habitCount;
  final int completedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.timeOfDay,
    required this.anchorTime,
    required this.daysOfWeek,
    required this.habitCount,
    required this.completedCount,
    required this.createdAt,
    required this.updatedAt,
  });

  double get completionRate => habitCount == 0 ? 0 : completedCount / habitCount;

  factory RoutineSummary.fromJson(Map<String, dynamic> json) {
    return RoutineSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeOfDay: json['timeOfDay'] as String? ?? 'morning',
      anchorTime: json['anchorTime'] as String?,
      daysOfWeek: ((json['daysOfWeek'] as List<dynamic>?) ?? const [])
          .map((item) => item as int)
          .toList(),
      habitCount: json['habitCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class RoutineHabitItem {
  final String habitId;
  final String title;
  final String? description;
  final String colorHex;
  final int sortOrder;
  final bool isCompletedToday;

  const RoutineHabitItem({
    required this.habitId,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.sortOrder,
    required this.isCompletedToday,
  });

  factory RoutineHabitItem.fromJson(Map<String, dynamic> json) {
    return RoutineHabitItem(
      habitId: json['habitId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isCompletedToday: json['isCompletedToday'] as bool? ?? false,
    );
  }
}

class RoutineDetail {
  final String id;
  final String title;
  final String? description;
  final String timeOfDay;
  final String? anchorTime;
  final List<int> daysOfWeek;
  final List<RoutineHabitItem> habits;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.timeOfDay,
    required this.anchorTime,
    required this.daysOfWeek,
    required this.habits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoutineDetail.fromJson(Map<String, dynamic> json) {
    return RoutineDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeOfDay: json['timeOfDay'] as String? ?? 'morning',
      anchorTime: json['anchorTime'] as String?,
      daysOfWeek: ((json['daysOfWeek'] as List<dynamic>?) ?? const [])
          .map((item) => item as int)
          .toList(),
      habits: ((json['habits'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RoutineHabitItem.fromJson)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
