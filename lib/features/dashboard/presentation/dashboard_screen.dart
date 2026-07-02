import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/theme/app_theme.dart';
import '../../attendance/data/attendance_repository.dart';
import '../../auth/data/models/auth_model.dart';
import '../../workout/data/workout_repository.dart';
import '../../../core/providers/session_provider.dart';
import '../data/dashboard_repository.dart';
import '../../hydration/hydration_card.dart';
import '../../hydration/hydration_provider.dart';
import '../../wellness/wellness_card.dart';
import '../../wellness/wellness_provider.dart';
import '../../inbox/inbox_service.dart';

final _dashGymProvider = FutureProvider<GymModel?>((ref) async {
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

final _dashAnnouncementsProvider = FutureProvider<List<AnnouncementModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getAnnouncements(); });

final _dashOffersProvider = FutureProvider<List<OfferModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getOffers(); });

final _dashSubscriptionProvider = FutureProvider<SubscriptionStatusModel?>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getMySubscription(); });

final _dashTodayPlanProvider = FutureProvider<DailyPlan?>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(workoutRepositoryProvider).getTodayPlan(); });

final _dashAttendanceProvider = FutureProvider<List<AttendanceRecord>>(
    (ref) async {
      ref.watch(sessionVersionProvider);
      return (await ref.read(attendanceRepositoryProvider).getMyAttendance()).records;
    });

final _dashUserNameProvider = FutureProvider<String?>(
    (ref) { ref.watch(sessionVersionProvider); return SecureStorage.getUserName(); });

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(_dashUserNameProvider).valueOrNull ?? 'Member';
    final attendance = ref.watch(_dashAttendanceProvider).valueOrNull ?? [];
    final streak = FitDateUtils.attendanceStreak(
        attendance.map((a) => DateTime.tryParse(a.date) ?? DateTime.now()).toList());
    final gym = ref.watch(_dashGymProvider).valueOrNull;
    final unreadCount = ref.watch(inboxUnreadCountProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref
              ..invalidate(_dashGymProvider)
              ..invalidate(_dashAnnouncementsProvider)
              ..invalidate(_dashOffersProvider)
              ..invalidate(_dashSubscriptionProvider)
              ..invalidate(_dashTodayPlanProvider)
              ..invalidate(_dashAttendanceProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Gym header ────────────────────────────────────────────────
              Row(
                children: [
                  // Gym logo
                  if (gym?.fullLogoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        gym!.fullLogoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _GymLogoPlaceholder(),
                      ),
                    )
                  else
                    _GymLogoPlaceholder(),
                  const SizedBox(width: 12),
                  // Gym name + area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gym?.name ?? '',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (gym?.area != null)
                          Text(
                            gym!.area!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Notification inbox bell
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined,
                            color: AppColors.textSecondary),
                        onPressed: () => context.push('/inbox'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.person_outline,
                        color: AppColors.textSecondary),
                    onPressed: () => context.go('/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Member greeting ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${userName.split(' ').first}!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        if (streak > 0)
                          Row(
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(width: 4),
                              Text(
                                '$streak day streak',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Start your streak today!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Subscription chip ─────────────────────────────────────────
              ref.watch(_dashSubscriptionProvider).when(
                    data: (sub) => sub != null
                        ? _SubscriptionChip(subscription: sub)
                        : const _NoSubscriptionCard(),
                    loading: () => const _ShimmerCard(height: 60),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 20),
              // ── Today's workout card ──────────────────────────────────────
              ref.watch(_dashTodayPlanProvider).when(
                    data: (plan) => _TodayPlanCard(plan: plan),
                    loading: () => const _ShimmerCard(height: 120),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 16),
              // ── Quick actions ─────────────────────────────────────────────
              const _QuickActions(),
              const SizedBox(height: 20),
              // ── Announcements ─────────────────────────────────────────────
              ref.watch(_dashAnnouncementsProvider).when(
                    data: (list) {
                      if (list.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Announcements',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          ...list.map((a) => _AnnouncementCard(a: a)),
                        ],
                      );
                    },
                    loading: () => const _ShimmerCard(height: 80),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 20),
              // ── Offers carousel ───────────────────────────────────────────
              ref.watch(_dashOffersProvider).when(
                    data: (offers) => offers.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Offers',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 10),
                              ...offers.map((o) => _OfferCard(offer: o)),
                            ],
                          ),
                    loading: () => const _ShimmerCard(height: 140),
                    error: (e, __) {
                      debugPrint('[OFFERS] provider error: $e');
                      return const SizedBox.shrink();
                    },
                  ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionChip extends StatelessWidget {
  final SubscriptionStatusModel subscription;

  const _SubscriptionChip({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final isActive = subscription.status.toUpperCase() == 'ACTIVE';
    final endDate = subscription.endDate != null
        ? DateTime.tryParse(subscription.endDate!)
        : null;
    final daysLeft = endDate != null ? FitDateUtils.daysUntil(endDate) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isActive
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.verified_outlined : Icons.warning_outlined,
            color: isActive ? AppColors.primary : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isActive
                  ? '${subscription.planName} — ${daysLeft != null ? '$daysLeft days left' : 'Active'}'
                  : 'Subscription ${subscription.status.toLowerCase()}',
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (!isActive)
            TextButton(
              onPressed: () => context.go('/subscription'),
              child: Text('Renew',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _NoSubscriptionCard extends StatelessWidget {
  const _NoSubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/subscription'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No active subscription. Tap to view plans.',
                style: TextStyle(
                    color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final DailyPlan? plan;

  const _TodayPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.go('/workout'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text("Today's Workout",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          )),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              if (plan!.isRestDay)
                const Text('Rest Day — Recovery is progress!',
                    style: TextStyle(color: AppColors.textSecondary))
              else ...[
                if (plan!.workoutEntry?.workoutTitle != null)
                  Text(
                    plan!.workoutEntry!.workoutTitle!,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                if (plan!.workoutEntry?.focus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      plan!.workoutEntry!.focus!,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wellness = ref.watch(wellnessProvider);
    final hydration = ref.watch(hydrationProvider);

    return Column(
      children: [
        // Row 1 — navigation actions
        Row(
          children: [
            _ActionButton(
              icon: Icons.login,
              label: 'Check In',
              onTap: () => context.go('/attendance'),
            ),
            const SizedBox(width: 10),
            _ActionButton(
              icon: Icons.calendar_month,
              label: 'Book Class',
              onTap: () => context.go('/classes'),
            ),
            const SizedBox(width: 10),
            _ActionButton(
              icon: Icons.insights,
              label: 'Progress',
              onTap: () => context.go('/progress'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2 — wellness, hydration, health
        Row(
          children: [
            _ActionButton(
              icon: Icons.mood,
              label: 'Wellness',
              onTap: () => _openSheet(context, const WellnessCard()),
              badge: !wellness.checkedInToday ? '!' : null,
              badgeColor: AppColors.warning,
            ),
            const SizedBox(width: 10),
            _ActionButton(
              icon: Icons.water_drop_outlined,
              label: 'Hydration',
              onTap: () => _openSheet(context, const _HydrationSheet()),
              badge: hydration.isGoalMet ? '✓' : null,
              badgeColor: const Color(0xFF29B6F6),
            ),
            const SizedBox(width: 10),
            _ActionButton(
              icon: Icons.card_membership_outlined,
              label: 'Plans',
              onTap: () => context.push('/subscription'),
            ),
          ],
        ),
      ],
    );
  }

  void _openSheet(BuildContext context, Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  if (badge != null)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel a;
  const _AnnouncementCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a.isPinned
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.cardBorder,
        ),
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.isPinned)
                    Padding(
                      padding: EdgeInsets.only(right: 6, top: 2),
                      child: Icon(Icons.push_pin,
                          size: 13, color: AppColors.primary),
                    ),
                  Expanded(
                    child: Text(
                      a.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14),
                    ),
                  ),
                  if (a.category != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        a.category!,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                a.content,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AnnouncementDetailSheet(a: a),
    );
  }
}

class _AnnouncementDetailSheet extends StatelessWidget {
  final AnnouncementModel a;
  const _AnnouncementDetailSheet({required this.a});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.category != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            a.category!,
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (a.isPinned) ...[
                        Row(
                          children: [
                            Icon(Icons.push_pin,
                                size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Pinned',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        a.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Text(
                a.content,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.imageUrl != null)
              Image.network(
                offer.imageUrl!,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            else
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E2A10), AppColors.primary],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offer.badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        offer.badge!,
                        style: TextStyle(
                            color: AppColors.darkBg,
                            fontWeight: FontWeight.w700,
                            fontSize: 10),
                      ),
                    ),
                  Text(
                    offer.title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (offer.discount != null) ...[
                    SizedBox(height: 4),
                    Text(
                      '${offer.discount!.toInt()}% OFF',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20),
                    ),
                  ],
                  if (offer.validTo != null)
                    Text(
                      'Valid till ${FitDateUtils.formatDate(DateTime.tryParse(offer.validTo!) ?? DateTime.now())}',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                ],
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
      isScrollControlled: true,
      backgroundColor: AppColors.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OfferDetailSheet(offer: offer),
    );
  }
}

class _OfferDetailSheet extends StatelessWidget {
  final OfferModel offer;
  const _OfferDetailSheet({required this.offer});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 0),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full image — fitWidth so portrait posters show completely
                  if (offer.imageUrl != null)
                    Image.network(
                      offer.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  else
                    Container(
                      height: 8,
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E2A10), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + close row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (offer.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  offer.badge!,
                                  style: TextStyle(
                                      color: AppColors.darkBg,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.close,
                                  color: AppColors.textSecondary, size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          offer.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        // Discount
                        if (offer.discount != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_offer_outlined,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${offer.discount!.toInt()}% OFF',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 26),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Description
                        if (offer.description != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            offer.description!,
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.6),
                          ),
                        ],
                        // Valid till
                        if (offer.validTo != null) ...[
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.cardBorder),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                'Valid till ${FitDateUtils.formatDate(DateTime.tryParse(offer.validTo!) ?? DateTime.now())}',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymLogoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(Icons.fitness_center,
          color: AppColors.primary, size: 24),
    );
  }
}

// Wraps HydrationCard with a title for the bottom sheet context
class _HydrationSheet extends StatelessWidget {
  const _HydrationSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hydration Tracker',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const HydrationCard(),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;

  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
