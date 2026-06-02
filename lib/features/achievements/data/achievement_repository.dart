import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/session_provider.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool earned;
  final DateTime? earnedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.earned,
    this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id']?.toString() ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        icon: j['icon'] as String? ?? 'star',
        category: j['category'] as String? ?? 'general',
        earned: j['earned'] as bool? ?? false,
        earnedAt: j['earnedAt'] != null
            ? DateTime.tryParse(j['earnedAt'] as String)
            : null,
      );
}

class AchievementRepository {
  final dynamic _dio;
  AchievementRepository(this._dio);

  Future<List<Achievement>> getMyAchievements() async {
    try {
      final res = await _dio.get(ApiConstants.myAchievements);
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

final achievementRepositoryProvider =
    Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.read(dioProvider));
});

final myAchievementsProvider = FutureProvider<List<Achievement>>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(achievementRepositoryProvider).getMyAchievements();
});
