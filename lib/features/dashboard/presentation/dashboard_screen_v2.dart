import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/session_provider.dart';
import '../data/dashboard_repository.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../auth/data/models/auth_model.dart';
import '../../workout/data/workout_repository.dart';
import '../../hydration/hydration_provider.dart';
import '../../wellness/wellness_provider.dart';
import '../../inbox/inbox_service.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_metrics.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_chip.dart';
import '../../../shared/fitviz_v2/widgets/v2_progress_ring.dart';

final _dashGymProviderV2 = FutureProvider<GymModel?>((ref) async {
  ref.watch(sessionVersionProvider);
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(ApiConstants.myGymInfo);
    if (res.data == null) return null;
    return GymModel.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

final _dashAnnouncementsProviderV2 = FutureProvider<List<AnnouncementModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getAnnouncements(); });

final _dashOffersProviderV2 = FutureProvider<List<OfferModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getOffers(); });

final _dashSubscriptionProviderV2 = FutureProvider<SubscriptionStatusModel?>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getMySubscription(); });

final _dashTodayPlanProviderV2 = FutureProvider<DailyPlan?>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(workoutRepositoryProvider).getTodayPlan(); });

final _dashAttendanceResultProviderV2 = FutureProvider((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(attendanceRepositoryProvider).getMyAttendance();
});

final _dashUserNameProviderV2 = FutureProvider<String?>(
    (ref) { ref.watch(sessionVersionProvider); return SecureStorage.getUserName(); });

class DashboardScreenV2 extends ConsumerWidget {
  const DashboardScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(_dashUserNameProviderV2).valueOrNull ?? 'Member';
    final firstName = userName.split(' ').first;
    final initials = userName.trim().isEmpty
        ? '?'
        : userName.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase();
    final attendanceAsync = ref.watch(_dashAttendanceResultProviderV2);
    final streak = attendanceAsync.valueOrNull == null
        ? 0
        : FitDateUtils.attendanceStreak(
            attendanceAsync.value!.records.map((a) => DateTime.tryParse(a.date) ?? DateTime.now()).toList());
    final gym = ref.watch(_dashGymProviderV2).valueOrNull;
    final unreadCount = ref.watch(inboxUnreadCountProvider);
    final subscription = ref.watch(_dashSubscriptionProviderV2).valueOrNull;
    final plan = ref.watch(_dashTodayPlanProviderV2).valueOrNull;
    final hydration = ref.watch(hydrationProvider);
    final wellness = ref.watch(wellnessProvider);
    final announcements = ref.watch(_dashAnnouncementsProviderV2).valueOrNull ?? const [];
    final offers = ref.watch(_dashOffersProviderV2).valueOrNull ?? const [];

    final daysLeft = subscription?.endDate != null
        ? FitDateUtils.daysUntil(DateTime.tryParse(subscription!.endDate!) ?? DateTime.now())
        : null;
    final totalHours = attendanceAsync.valueOrNull?.stats?.totalHours;

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: FitVizV2Colors.accent,
          backgroundColor: FitVizV2Colors.surface,
          onRefresh: () async {
            ref
              ..invalidate(_dashGymProviderV2)
              ..invalidate(_dashAnnouncementsProviderV2)
              ..invalidate(_dashOffersProviderV2)
              ..invalidate(_dashSubscriptionProviderV2)
              ..invalidate(_dashTodayPlanProviderV2)
              ..invalidate(_dashAttendanceResultProviderV2);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
            children: [
              // ── Header: avatar + greeting/streak/gym + bell ─────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FitVizV2Colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FitVizV2Colors.border),
                    ),
                    child: Center(child: Text(initials, style: FitVizV2Text.display(size: 15, color: FitVizV2Colors.accent))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $firstName', style: FitVizV2Text.h1()),
                        const SizedBox(height: 3),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (streak > 0)
                              V2Chip(
                                label: '$streak-day streak',
                                variant: V2ChipVariant.accent,
                                leading: const FitVizV2IconView(FitVizV2Icon.flame, size: 10, color: FitVizV2Colors.accent),
                              ),
                            if (gym?.name != null)
                              Text(gym!.name, style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/inbox'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: FitVizV2Colors.surface),
                          child: const Center(child: FitVizV2IconView(FitVizV2Icon.bell, size: 16, color: FitVizV2Colors.inkDim)),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 6,
                            right: 7,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: FitVizV2Colors.danger),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Bento hero: today's workout ──────────────────────────────
              GestureDetector(
                onTap: () => context.go('/workout'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [FitVizV2Colors.surface2, FitVizV2Colors.surface],
                    ),
                    borderRadius: BorderRadius.circular(FitVizV2Radius.lg),
                    border: Border.all(color: FitVizV2Colors.border),
                  ),
                  child: Row(
                    children: [
                      V2ProgressRing(
                        progress: plan == null ? 0 : (plan.status.toUpperCase() == 'COMPLETED' ? 100 : 45),
                        label: plan == null ? '—' : (plan.status.toUpperCase() == 'COMPLETED' ? '100%' : '45%'),
                        size: V2RingSize.lg,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("TODAY'S PLAN", style: FitVizV2Text.caption(color: FitVizV2Colors.accent)),
                            const SizedBox(height: 6),
                            Text(
                              plan == null
                                  ? 'No plan for today'
                                  : (plan.isRestDay ? 'Rest Day' : (plan.workoutEntry?.workoutTitle ?? 'Workout')),
                              style: FitVizV2Text.h2(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text('Tap to view today\'s plan', style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Stat ring rail ────────────────────────────────────────────
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatRingCard(
                      progress: daysLeft == null ? 0 : (daysLeft.clamp(0, 365) / 365 * 100),
                      label: daysLeft == null ? '—' : '${daysLeft}d',
                      caption: 'Membership\nleft',
                    ),
                    const SizedBox(width: 10),
                    _StatRingCard(
                      progress: totalHours == null ? 0 : (totalHours.clamp(0, 40) / 40 * 100),
                      label: totalHours == null ? '—' : '${totalHours.toStringAsFixed(0)}h',
                      caption: 'Hours\nthis month',
                    ),
                    const SizedBox(width: 10),
                    _StatRingCard(
                      progress: hydration.goalMl == 0 ? 0 : (hydration.consumed / hydration.goalMl * 100),
                      label: '${hydration.glasses}/${(hydration.goalMl / 250).round()}',
                      caption: 'Hydration\ntoday',
                      color: const Color(0xFF29B6F6),
                    ),
                    const SizedBox(width: 10),
                    _StatRingCard(
                      progress: wellness.checkedInToday ? 90 : 20,
                      label: wellness.checkedInToday ? 'Good' : 'Log',
                      caption: 'Wellness\nmood',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Quick actions ─────────────────────────────────────────────
              Text('QUICK ACTIONS', style: FitVizV2Text.caption()),
              const SizedBox(height: 10),
              SizedBox(
                height: 78,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ActionPill(icon: FitVizV2Icon.grid, label: 'Check In', onTap: () => context.go('/attendance')),
                    const SizedBox(width: 10),
                    _ActionPill(icon: FitVizV2Icon.calendar, label: 'Book Class', onTap: () => context.go('/classes')),
                    const SizedBox(width: 10),
                    _ActionPill(icon: FitVizV2Icon.chart, label: 'Progress', onTap: () => context.go('/progress')),
                    const SizedBox(width: 10),
                    _ActionPill(icon: FitVizV2Icon.doc, label: 'Plans', onTap: () => context.push('/subscription')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Pinned announcement ──────────────────────────────────────
              if (announcements.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: FitVizV2Colors.surface,
                    borderRadius: BorderRadius.circular(FitVizV2Radius.md),
                    border: Border.all(color: FitVizV2Colors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: FitVizV2Colors.surface2, borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: FitVizV2IconView(FitVizV2Icon.pin, size: 16, color: FitVizV2Colors.accent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(announcements.first.title, style: FitVizV2Text.body(size: 13, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              announcements.first.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Subscription / offer card ────────────────────────────────
              if (subscription != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FitVizV2Colors.surface,
                    borderRadius: BorderRadius.circular(FitVizV2Radius.md),
                    border: Border.all(color: FitVizV2Colors.accent),
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/subscription'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subscription.planName, style: FitVizV2Text.body(size: 13, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                subscription.endDate != null
                                    ? 'Valid till ${FitDateUtils.formatDate(DateTime.tryParse(subscription.endDate!) ?? DateTime.now())}'
                                    : subscription.status,
                                style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim),
                              ),
                            ],
                          ),
                        ),
                        const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                      ],
                    ),
                  ),
                ),
              if (offers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('CURRENT OFFERS', style: FitVizV2Text.caption()),
                const SizedBox(height: 10),
                ...offers.map((o) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FitVizV2Colors.surface,
                        borderRadius: BorderRadius.circular(FitVizV2Radius.md),
                        border: Border.all(color: FitVizV2Colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.title, style: FitVizV2Text.body(size: 14, weight: FontWeight.w700)),
                          if (o.discount != null) ...[
                            const SizedBox(height: 4),
                            Text('${o.discount!.toInt()}% OFF',
                                style: FitVizV2Text.display(size: 20, color: FitVizV2Colors.accent)),
                          ],
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRingCard extends StatelessWidget {
  final double progress;
  final String label;
  final String caption;
  final Color? color;

  const _StatRingCard({required this.progress, required this.label, required this.caption, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        borderRadius: BorderRadius.circular(FitVizV2Radius.md),
        border: Border.all(color: FitVizV2Colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          V2ProgressRing(progress: progress, label: label, size: V2RingSize.sm, sweepColor: color ?? FitVizV2Colors.accent),
          const SizedBox(height: 8),
          Text(caption, textAlign: TextAlign.center, style: FitVizV2Text.body(size: 10, color: FitVizV2Colors.inkDim)),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final FitVizV2Icon icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FitVizV2Colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: FitVizV2Colors.border),
              ),
              child: Center(child: FitVizV2IconView(icon, size: 20, color: FitVizV2Colors.accent)),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: FitVizV2Text.body(size: 10, color: FitVizV2Colors.inkDim)),
          ],
        ),
      ),
    );
  }
}
