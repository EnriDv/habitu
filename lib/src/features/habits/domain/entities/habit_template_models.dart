class TemplateGoal {
  final String goalKey;
  final String title;
  final String description;

  const TemplateGoal({
    required this.goalKey,
    required this.title,
    required this.description,
  });

  factory TemplateGoal.fromJson(Map<String, dynamic> json) {
    return TemplateGoal(
      goalKey: json['goalKey'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}

class HabitTemplateModel {
  final String id;
  final String title;
  final String? description;
  final String goalKey;
  final String category;
  final List<String> lifestyleTags;
  final String suggestedFrequencyType;
  final List<int> suggestedFrequencyDays;
  final String defaultColorHex;
  final String? defaultIconKey;
  final bool isFeatured;

  const HabitTemplateModel({
    required this.id,
    required this.title,
    required this.description,
    required this.goalKey,
    required this.category,
    required this.lifestyleTags,
    required this.suggestedFrequencyType,
    required this.suggestedFrequencyDays,
    required this.defaultColorHex,
    required this.defaultIconKey,
    required this.isFeatured,
  });

  factory HabitTemplateModel.fromJson(Map<String, dynamic> json) {
    return HabitTemplateModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      goalKey: json['goalKey'] as String? ?? 'general',
      category: json['category'] as String? ?? 'general',
      lifestyleTags: ((json['lifestyleTags'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      suggestedFrequencyType: json['suggestedFrequencyType'] as String? ?? 'daily',
      suggestedFrequencyDays: ((json['suggestedFrequencyDays'] as List<dynamic>?) ?? const [])
          .map((item) => item as int)
          .toList(),
      defaultColorHex: json['defaultColorHex'] as String? ?? '#6366F1',
      defaultIconKey: json['defaultIconKey'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }
}

class HabitRecommendation {
  final String id;
  final String type;
  final String title;
  final String description;
  final String reason;
  final String goalKey;
  final Map<String, dynamic> suggestedPayload;

  const HabitRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.reason,
    required this.goalKey,
    required this.suggestedPayload,
  });

  factory HabitRecommendation.fromJson(Map<String, dynamic> json) {
    return HabitRecommendation(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'template',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      goalKey: json['goalKey'] as String? ?? 'general',
      suggestedPayload: Map<String, dynamic>.from(
        json['suggestedPayload'] as Map? ?? const {},
      ),
    );
  }
}
