import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/session_provider.dart';
import '../data/workout_repository.dart';
import 'workout_timer_screen.dart';

final _todayPlanProvider = FutureProvider<DailyPlan?>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(workoutRepositoryProvider).getTodayPlan();
});

// History tab: selected month (defaults to current month)
final _historyMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

// History tab: one cached provider per (month, year) pair
final _historyProvider =
    FutureProvider.family<List<DailyPlan>, (int, int)>((ref, params) {
  ref.watch(sessionVersionProvider);
  final (month, year) = params;
  return ref
      .read(workoutRepositoryProvider)
      .getPlanHistory(month: month, year: year);
});

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(_todayPlanProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkBg,
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Timer', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutTimerScreen()),
        ),
      ),
      appBar: AppBar(
          title: const Text('My Fitness Plan'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: "Today"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Today's plan ────────────────────────────────────────────────
            todayAsync.when(
              data: (plan) => plan == null
                  ? const _EmptyState(
                      icon: Icons.fitness_center,
                      message: "No plan for today yet.\nCheck back after midnight.",
                    )
                  : _TodayPlanView(plan: plan),
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _EmptyState(
                icon: Icons.error_outline,
                message: 'Could not load today\'s plan.\n$e',
              ),
            ),
            // ── History ──────────────────────────────────────────────────
            const _HistoryViewWrapper(),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanView extends StatelessWidget {
  final DailyPlan plan;

  const _TodayPlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan.isRestDay) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Rest Day',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'Take it easy. Recovery is part of progress.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Row(
            children: [
              _StatusBadge(status: plan.status),
              const Spacer(),
              Text(
                FitDateUtils.formatDate(
                    DateTime.tryParse(plan.planDate) ?? DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Workout section
          if (plan.workoutEntry != null) ...[
            _SectionCard(
              title: plan.workoutEntry!.workoutTitle ?? 'Today\'s Workout',
              subtitle: plan.workoutEntry!.focus,
              icon: Icons.fitness_center,
              accentColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.workoutEntry!.exercises
                    .map((exercise) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            exercise,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.4),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Diet section
          if (plan.dietEntry != null)
            _DietCard(diet: plan.dietEntry!),
        ],
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.accentColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              widget.child,
            ],
          ],
        ),
      ),
    );
  }
}

class _DietCard extends StatelessWidget {
  final DietEntry diet;

  const _DietCard({required this.diet});

  @override
  Widget build(BuildContext context) {
    final meals = diet.meals;
    final mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];

    return _SectionCard(
      title: 'Diet Plan',
      subtitle: diet.dietType,
      icon: Icons.restaurant_menu,
      accentColor: const Color(0xFF4CAF50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: mealOrder
            .where((key) => meals != null && meals[key] != null)
            .map((key) {
          final meal = meals![key] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key[0].toUpperCase() + key.substring(1),
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  meal['name'] as String? ?? '',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                if (meal['ingredients'] != null)
                  Text(
                    meal['ingredients'] as String,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryViewWrapper extends ConsumerWidget {
  const _HistoryViewWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_historyMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selected.year == now.year && selected.month == now.month;

    void prevMonth() {
      final d = DateTime(selected.year, selected.month - 1);
      ref.read(_historyMonthProvider.notifier).state = d;
    }

    void nextMonth() {
      if (isCurrentMonth) return;
      final d = DateTime(selected.year, selected.month + 1);
      ref.read(_historyMonthProvider.notifier).state = d;
    }

    return Column(
      children: [
        // ── Month selector bar ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: prevMonth,
                icon: Icon(Icons.chevron_left,
                    color: AppColors.primary, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateFormat('MMMM yyyy').format(selected),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              IconButton(
                onPressed: isCurrentMonth ? null : nextMonth,
                icon: Icon(Icons.chevron_right,
                    color: isCurrentMonth
                        ? AppColors.textMuted
                        : AppColors.primary,
                    size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // ── Plan records for selected month ─────────────────────────────
        Expanded(
          child: ref
              .watch(_historyProvider((selected.month, selected.year)))
              .when(
                data: (plans) => _HistoryView(plans: plans),
                loading: () => Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: TextStyle(
                            color: AppColors.textSecondary))),
              ),
        ),
      ],
    );
  }
}

class _HistoryView extends StatelessWidget {
  final List<DailyPlan> plans;

  const _HistoryView({required this.plans});

  void _showDetail(BuildContext context, DailyPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlanDetailSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const _EmptyState(
          icon: Icons.history, message: 'No plan history yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = plans[i];
        final date = DateTime.tryParse(p.planDate) ?? DateTime.now();
        final hasDetail = !p.isRestDay &&
            (p.workoutEntry != null || p.dietEntry != null);
        return Card(
          child: InkWell(
            onTap: () => _showDetail(context, p),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    p.isRestDay
                        ? Icons.self_improvement
                        : Icons.fitness_center,
                    color: _statusColor(p.status),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FitDateUtils.relativeDateLabel(date),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.isRestDay
                              ? 'Rest Day'
                              : p.workoutEntry?.workoutTitle ?? 'Workout',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: p.status, small: true),
                  if (hasDetail) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'MISSED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _PlanDetailSheet extends StatelessWidget {
  final DailyPlan plan;

  const _PlanDetailSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(plan.planDate) ?? DateTime.now();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle + header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FitDateUtils.formatDate(date),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (plan.workoutEntry?.workoutTitle != null &&
                              !plan.isRestDay)
                            Text(
                              plan.workoutEntry!.workoutTitle!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: plan.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.cardBorder),
              ],
            ),
          ),
          // Scrollable content — reuses the same widgets as Today tab
          Expanded(
            child: plan.isRestDay
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.self_improvement,
                            size: 56, color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'Rest Day',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Recovery is part of the process.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      if (plan.workoutEntry != null) ...[
                        _SectionCard(
                          title: plan.workoutEntry!.workoutTitle ??
                              'Workout',
                          subtitle: plan.workoutEntry!.focus,
                          icon: Icons.fitness_center,
                          accentColor: AppColors.primary,
                          child: plan.workoutEntry!.exercises.isEmpty
                              ? const Text(
                                  'No exercise details recorded.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: plan.workoutEntry!.exercises
                                      .map((exercise) => Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 4),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    exercise,
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontSize: 14,
                                                        height: 1.4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (plan.dietEntry != null)
                        _DietCard(diet: plan.dietEntry!),
                      if (plan.workoutEntry == null && plan.dietEntry == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              'No details recorded for this day.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const _StatusBadge({required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = AppColors.success;
        break;
      case 'MISSED':
        color = AppColors.error;
        break;
      case 'RESCHEDULED':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1).toLowerCase(),
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: small ? 11 : 13),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
