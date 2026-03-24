class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final int totalEntries;
  final int totalNotes;
  final int points;
  final int unlockedCount;
  final int totalAchievements;
  final List<Achievement> achievements;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    required this.totalEntries,
    required this.totalNotes,
    required this.points,
    required this.unlockedCount,
    required this.totalAchievements,
    required this.achievements,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalDays: json['total_days'] ?? 0,
      totalEntries: json['total_entries'] ?? 0,
      totalNotes: json['total_notes'] ?? 0,
      points: json['points'] ?? 0,
      unlockedCount: json['unlocked_count'] ?? 0,
      totalAchievements: json['total_achievements'] ?? 0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => Achievement.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Get next achievement to unlock
  Achievement? get nextAchievement {
    try {
      return achievements.firstWhere((a) => !a.isUnlocked);
    } catch (_) {
      return null;
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int required;
  final int current;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.required,
    required this.current,
    required this.isUnlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      required: json['required'] ?? 0,
      current: json['current'] ?? 0,
      isUnlocked: json['unlocked'] ?? false,
    );
  }

  double get progress {
    if (required == 0) return 1.0;
    return (current / required).clamp(0.0, 1.0);
  }
}
