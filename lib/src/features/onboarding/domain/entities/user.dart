class User {
  final String id;
  final String email;
  final String fullName;
  final String? profilePictureUrl;
  final String role;
  final String? ucbId;
  final bool isActive;
  final String? academicProgram;
  final String? persona;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
    required this.role,
    this.ucbId,
    required this.isActive,
    this.academicProgram,
    this.persona,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profilePictureUrl,
    String? role,
    String? ucbId,
    bool? isActive,
    String? academicProgram,
    String? persona,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      ucbId: ucbId ?? this.ucbId,
      isActive: isActive ?? this.isActive,
      academicProgram: academicProgram ?? this.academicProgram,
      persona: persona ?? this.persona,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'ucbId': ucbId,
      'isActive': isActive,
      'academicProgram': academicProgram,
      'persona': persona,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      role: json['role'] as String? ?? 'student',
      ucbId: json['ucbId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      academicProgram: json['academicProgram'] as String?,
      persona: json['persona'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'User(id: $id, fullName: $fullName, role: $role)';
}
