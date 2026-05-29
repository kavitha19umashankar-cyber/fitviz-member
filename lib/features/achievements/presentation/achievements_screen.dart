import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/achievement_repository.dart';

// Icon mapping for string icon names from the API
IconData _iconFor(String icon) {
  switch (icon) {
    case 'star': return Icons.star_outline;
    case 'fire': return Icons.local_fire_department_outlined;
    case 'trophy': return Icons.emoji_events_outlined;
    case 'dumbbell': return Icons.fitness_center;
    case 'heart': return Icons.favorite_outline;
    case 'bolt': return Icons.bolt;
    case 'clock': return Icons.alarm;
    case 'calendar': return Icons.calendar_month_outlined;
    case 'medal': return Icons.military_tech_outlined;
    case 'crown': return Icons.workspace_premium_outlined;
    default: return Icons.emoji_events_outlined;
  }
}

// Fallback local badges when the API returns empty (computed client-side)
List<Achievement> _localBadges(List<Achievement> apiList) {
  if (apiList.isNotEmpty) return apiList;
  // Show placeholder locked badges so the screen always has content
  return const [
    Achievement(id: 'first_checkin', name: 'First Step', description: 'Complete your first gym check-in', icon: 'star', category: 'Attendance', earned: false),
    Achievement(id: 'streak_7', name: '7-Day Warrior', description: 'Attend the gym 7 days in a row', icon: 'fire', category: 'Streaks', earned: false),
    Achievement(id: 'streak_30', name: '30-Day Legend', description: 'Attend 30 consecutive days', icon: 'crown', category: 'Streaks', earned: false),
    Achievement(id: 'early_bird', name: 'Early Bird', description: 'Check in before 7 AM', icon: 'clock', category: 'Attendance', earned: false),
    Achievement(id: 'class_10', name: 'Class Regular', description: 'Book 10 group classes', icon: 'calendar', category: 'Classes', earned: false),
    Achievement(id: 'workouts_100', name: 'Century Club', description: 'Complete 100 workout sessions', icon: 'trophy', category: 'Workouts', earned: false),
    Achievement(id: 'workout_first', name: 'First Sweat', description: 'Complete your first workout plan', icon: 'dumbbell', category: 'Workouts', earned: false),
    Achievement(id: 'streak_14', name: '2-Week Grind', description: 'Attend 14 consecutive days', icon: 'bolt', category: 'Streaks', earned: false),
  ];
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAchievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: async.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _BadgeGrid(badges: _localBadges([])),
        data: (list) => _BadgeGrid(badges: _localBadges(list)),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<Achievement> badges;
  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    final earned = badges.where((b) => b.earned).toList();
    final locked = badges.where((b) => !b.earned).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (earned.isNotEmpty) ...[
          _SectionHeader(
            title: 'Earned',
            subtitle: '${earned.length} of ${badges.length}',
          ),
          const SizedBox(height: 12),
          _grid(context, earned, locked: false),
          const SizedBox(height: 24),
        ],
        if (locked.isNotEmpty) ...[
          _SectionHeader(title: 'Locked', subtitle: '${locked.length} remaining'),
          const SizedBox(height: 12),
          _grid(context, locked, locked: true),
        ],
        if (badges.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.emoji_events_outlined,
                    color: AppColors.textMuted, size: 52),
                const SizedBox(height: 12),
                Text('No achievements yet',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('Keep showing up!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _grid(BuildContext context, List<Achievement> list, {required bool locked}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => _BadgeTile(badge: list[i], locked: locked),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(subtitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement badge;
  final bool locked;
  const _BadgeTile({required this.badge, required this.locked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: locked ? AppColors.surface : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked
                ? AppColors.cardBorder
                : AppColors.primary.withOpacity(0.35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.cardBorder.withOpacity(0.4)
                    : AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                locked ? Icons.lock_outline : _iconFor(badge.icon),
                color: locked ? AppColors.textMuted : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: locked ? AppColors.textMuted : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BadgeDetailSheet(badge: badge, locked: locked),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final Achievement badge;
  final bool locked;
  const _BadgeDetailSheet({required this.badge, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: locked
                  ? AppColors.cardBorder.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              locked ? Icons.lock_outline : _iconFor(badge.icon),
              color: locked ? AppColors.textMuted : AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(badge.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge.category,
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          if (!locked && badge.earnedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Earned on ${DateFormat('dd MMM yyyy').format(badge.earnedAt!)}',
              style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
          if (locked) ...[
            const SizedBox(height: 16),
            Text(
              'Keep going — you can unlock this!',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
