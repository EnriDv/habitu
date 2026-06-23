class Friend {
  final String friendshipId;
  final String friendId;
  final String fullName;
  final String? avatarUrl;
  final String? academicProgram;
  final String status;
  final DateTime updatedAt;

  const Friend({
    required this.friendshipId,
    required this.friendId,
    required this.fullName,
    this.avatarUrl,
    this.academicProgram,
    required this.status,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        friendshipId: json['friendshipId'] as String,
        friendId: json['friendId'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        academicProgram: json['academicProgram'] as String?,
        status: json['status'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class UserSearchResult {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? academicProgram;
  final bool alreadyFriend;

  const UserSearchResult({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.academicProgram,
    required this.alreadyFriend,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        academicProgram: json['academicProgram'] as String?,
        alreadyFriend: json['alreadyFriend'] as bool,
      );
}

class FriendPublicHabit {
  final String habitId;
  final String title;
  final String? description;
  final String colorHex;
  final int currentStreak;
  final int longestStreak;
  final String? lastExtendedDate;

  const FriendPublicHabit({
    required this.habitId,
    required this.title,
    this.description,
    required this.colorHex,
    required this.currentStreak,
    required this.longestStreak,
    this.lastExtendedDate,
  });

  factory FriendPublicHabit.fromJson(Map<String, dynamic> json) => FriendPublicHabit(
        habitId: json['habitId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        colorHex: json['colorHex'] as String,
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        lastExtendedDate: json['lastExtendedDate'] as String?,
      );
}

class FriendDetail {
  final String friendId;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String? academicProgram;
  final String universityHeadquarters;
  final List<FriendPublicHabit> publicHabits;

  const FriendDetail({
    required this.friendId,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.academicProgram,
    required this.universityHeadquarters,
    required this.publicHabits,
  });

  factory FriendDetail.fromJson(Map<String, dynamic> json) => FriendDetail(
        friendId: json['friendId'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        academicProgram: json['academicProgram'] as String?,
        universityHeadquarters: json['universityHeadquarters'] as String? ?? '',
        publicHabits: (json['publicHabits'] as List<dynamic>)
            .map((h) => FriendPublicHabit.fromJson(h as Map<String, dynamic>))
            .toList(),
      );
}

class RankingEntry {
  final int rank;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? academicProgram;
  final String habitTitle;
  final String colorHex;
  final int currentStreak;
  final int longestStreak;

  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.academicProgram,
    required this.habitTitle,
    required this.colorHex,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
        rank: json['rank'] as int,
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        academicProgram: json['academicProgram'] as String?,
        habitTitle: json['habitTitle'] as String,
        colorHex: json['colorHex'] as String,
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
      );
}

class SocialChallenge {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? coverImageUrl;
  final String startDate;
  final String endDate;
  final int participantCount;
  final int? maxParticipants;
  final bool isJoined;

  const SocialChallenge({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    this.maxParticipants,
    required this.isJoined,
  });

  bool get isFull => maxParticipants != null && participantCount >= maxParticipants!;

  factory SocialChallenge.fromJson(Map<String, dynamic> json) => SocialChallenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String? ?? 'general',
        coverImageUrl: json['coverImageUrl'] as String?,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        participantCount: json['participantCount'] as int,
        maxParticipants: json['maxParticipants'] as int?,
        isJoined: json['isJoined'] as bool,
      );
}
