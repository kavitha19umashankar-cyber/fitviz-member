import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/session_provider.dart';
import '../data/workout_repository.dart';
import 'workout_screen.dart' show todayAttendanceProvider;
import 'workout_timer_screen_v2.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_metrics.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_chip.dart';
import '../../../shared/fitviz_v2/widgets/v2_segmented_control.dart';
import '../../../shared/fitviz_v2/widgets/v2_timeline_row.dart';
import '../../../shared/fitviz_v2/widgets/v2_empty_state.dart';

final _todayPlanProviderV2 = FutureProvider<DailyPlan?>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(workoutRepositoryProvider).getTodayPlan();
});

final _historyMonthProviderV2 = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

final _historyProviderV2 = FutureProvider.family<List<DailyPlan>, (int, int)>((ref, params) {
  ref.watch(sessionVersionProvider);
  final (month, year) = params;
  return ref.read(workoutRepositoryProvider).getPlanHistory(month: month, year: year);
});

/// Numbered exercise cards with chip-style set/rep tags, best-effort
/// extracted from free-text exercise lines (e.g. "Bench Press - 15 x 4").
final RegExp _setRepPattern = RegExp(r'[-–—]\s*(\d+\s*[x×]\s*\d+)\s*$', caseSensitive: false);

class WorkoutScreenV2 extends ConsumerStatefulWidget {
  const WorkoutScreenV2({super.key});

  @override
  ConsumerState<WorkoutScreenV2> createState() => _WorkoutScreenV2State();
}

class _WorkoutScreenV2State extends ConsumerState<WorkoutScreenV2> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(_todayPlanProviderV2);

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('My Fitness Plan', style: FitVizV2Text.h1())),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkoutTimerScreenV2()),
                    ),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: FitVizV2Colors.surface),
                      child: const Center(
                        child: FitVizV2IconView(FitVizV2Icon.stopwatch, size: 16, color: FitVizV2Colors.accent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              V2SegmentedControl(
                selectedIndex: _tab,
                labels: const ['Today', 'History'],
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _tab == 0
                    ? todayAsync.when(
                        data: (plan) => plan == null
                            ? const V2EmptyState(
                                icon: FitVizV2Icon.dumbbell,
                                title: 'No plan for today',
                                message: 'Check back after midnight for your next workout.',
                              )
                            : _TodayView(plan: plan),
                        loading: () => const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
                        error: (e, _) => V2EmptyState(
                          icon: FitVizV2Icon.dumbbell,
                          title: 'Could not load plan',
                          message: '$e',
                        ),
                      )
                    : const _HistoryTab(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayView extends ConsumerWidget {
  final DailyPlan plan;
  const _TodayView({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plan.isRestDay) {
      final hasAttendance = ref.watch(todayAttendanceProvider).valueOrNull ?? false;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FitVizV2IconView(FitVizV2Icon.smile, size: 40, color: FitVizV2Colors.accent),
            const SizedBox(height: 14),
            Text('Rest Day', style: FitVizV2Text.h1()),
            const SizedBox(height: 8),
            if (hasAttendance) ...[
              const V2Chip(label: 'Completed', variant: V2ChipVariant.success),
              const SizedBox(height: 8),
            ],
            Text(
              hasAttendance ? 'Great job showing up! Rest day completed.' : 'Take it easy. Recovery is part of progress.',
              textAlign: TextAlign.center,
              style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FitVizV2Colors.surface,
              border: Border.all(color: FitVizV2Colors.border),
              borderRadius: BorderRadius.circular(FitVizV2Radius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(FitDateUtils.formatDate(DateTime.tryParse(plan.planDate) ?? DateTime.now()),
                          style: FitVizV2Text.caption()),
                      const SizedBox(height: 3),
                      Text(plan.workoutEntry?.workoutTitle ?? 'Workout', style: FitVizV2Text.h2()),
                    ],
                  ),
                ),
                _statusChip(plan.status),
              ],
            ),
          ),
          if (plan.workoutEntry != null && plan.workoutEntry!.exercises.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...plan.workoutEntry!.exercises.asMap().entries.map((entry) => _ExerciseRow(index: entry.key + 1, line: entry.value)),
          ],
          if (plan.dietEntry?.meals != null) ...[
            const SizedBox(height: 16),
            Text('DIET PLAN', style: FitVizV2Text.caption()),
            const SizedBox(height: 8),
            ..._mealRows(plan.dietEntry!.meals!),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const V2Chip(label: 'Done', variant: V2ChipVariant.success);
      case 'MISSED':
        return const V2Chip(label: 'Missed', variant: V2ChipVariant.danger);
      default:
        return const V2Chip(label: 'Pending', variant: V2ChipVariant.warning);
    }
  }

  List<Widget> _mealRows(Map<String, dynamic> meals) {
    const order = ['breakfast', 'lunch', 'dinner', 'snack'];
    return order.where((k) => meals[k] != null).map((k) {
      final meal = meals[k] as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k[0].toUpperCase() + k.substring(1), style: FitVizV2Text.body(size: 12, weight: FontWeight.w700, color: FitVizV2Colors.accent)),
            const SizedBox(height: 2),
            Text(meal['name'] as String? ?? '-', style: FitVizV2Text.body(size: 13)),
          ],
        ),
      );
    }).toList();
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final String line;
  const _ExerciseRow({required this.index, required this.line});

  @override
  Widget build(BuildContext context) {
    final match = _setRepPattern.firstMatch(line);
    final setRep = match?.group(1)?.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final name = match != null ? line.substring(0, match.start).trim() : line;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        border: Border.all(color: FitVizV2Colors.border),
        borderRadius: BorderRadius.circular(FitVizV2Radius.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: FitVizV2Colors.surface2, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$index', style: FitVizV2Text.data(size: 12, color: FitVizV2Colors.accent))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: FitVizV2Text.body(size: 13))),
          if (setRep != null) ...[
            const SizedBox(width: 8),
            V2Chip(label: setRep),
          ],
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_historyMonthProviderV2);
    final now = DateTime.now();
    final isCurrentMonth = selected.year == now.year && selected.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => ref.read(_historyMonthProviderV2.notifier).state = DateTime(selected.year, selected.month - 1),
              child: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.accent),
            ),
            Text(_monthLabel(selected), style: FitVizV2Text.body(size: 14, weight: FontWeight.w700)),
            GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () => ref.read(_historyMonthProviderV2.notifier).state = DateTime(selected.year, selected.month + 1),
              child: Transform.rotate(
                angle: 3.1416,
                child: FitVizV2IconView(FitVizV2Icon.chevron,
                    size: 16, color: isCurrentMonth ? FitVizV2Colors.border : FitVizV2Colors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ref.watch(_historyProviderV2((selected.month, selected.year))).when(
                data: (plans) => plans.isEmpty
                    ? const V2EmptyState(icon: FitVizV2Icon.doc, title: 'No history yet', message: 'Completed plans will show up here.')
                    : ListView.builder(
                        itemCount: plans.length,
                        itemBuilder: (context, i) {
                          final p = plans[i];
                          final date = DateTime.tryParse(p.planDate) ?? DateTime.now();
                          return V2TimelineRow(
                            isLast: i == plans.length - 1,
                            dotState: p.status.toUpperCase() == 'COMPLETED'
                                ? V2TimelineDotState.on
                                : p.status.toUpperCase() == 'MISSED'
                                    ? V2TimelineDotState.off
                                    : V2TimelineDotState.neutral,
                            body: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(FitDateUtils.relativeDateLabel(date), style: FitVizV2Text.body(size: 13, weight: FontWeight.w700)),
                                      Text(p.isRestDay ? 'Rest Day' : (p.workoutEntry?.workoutTitle ?? 'Workout'),
                                          style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
                error: (e, _) => Center(child: Text('Error: $e', style: FitVizV2Text.body(color: FitVizV2Colors.inkDim))),
              ),
        ),
      ],
    );
  }

  String _monthLabel(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }
}
