import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/session_provider.dart';
import '../data/attendance_repository.dart';
import '../../workout/presentation/workout_screen.dart' show todayAttendanceProvider;
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_metrics.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_chip.dart';
import '../../../shared/fitviz_v2/widgets/v2_segmented_control.dart';
import '../../../shared/fitviz_v2/widgets/v2_pill_button.dart';
import '../../../shared/fitviz_v2/widgets/v2_qr_viewfinder_frame.dart';
import '../../../shared/fitviz_v2/widgets/v2_progress_ring.dart';
import '../../../shared/fitviz_v2/widgets/v2_timeline_row.dart';
import '../../../shared/fitviz_v2/widgets/v2_empty_state.dart';

final _myAttendanceProviderV2 = FutureProvider<AttendanceResult>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(attendanceRepositoryProvider).getMyAttendance();
});

final _historyMonthProviderV2b = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

final _historyAttendanceProviderV2 = FutureProvider.family<AttendanceResult, (int, int)>((ref, params) {
  ref.watch(sessionVersionProvider);
  final (month, year) = params;
  return ref.read(attendanceRepositoryProvider).getMyAttendance(month: month, year: year);
});

final _userIdProviderV2 = FutureProvider<String?>((ref) { ref.watch(sessionVersionProvider); return SecureStorage.getUserId(); });
final _gymIdProviderV2 = FutureProvider<String?>((ref) { ref.watch(sessionVersionProvider); return SecureStorage.getGymId(); });

class AttendanceScreenV2 extends ConsumerStatefulWidget {
  const AttendanceScreenV2({super.key});

  @override
  ConsumerState<AttendanceScreenV2> createState() => _AttendanceScreenV2State();
}

class _AttendanceScreenV2State extends ConsumerState<AttendanceScreenV2> {
  int _tab = 0;
  bool _actionLoading = false;

  Future<void> _checkOut() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(attendanceRepositoryProvider).checkOut();
      ref.invalidate(_myAttendanceProviderV2);
      ref.invalidate(todayAttendanceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked out. Great workout!'), backgroundColor: FitVizV2Colors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-out failed. Please try again.'), backgroundColor: FitVizV2Colors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(_myAttendanceProviderV2);

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Attendance', style: FitVizV2Text.h1()),
              const SizedBox(height: 12),
              V2SegmentedControl(
                selectedIndex: _tab,
                labels: const ['Check In', 'History'],
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _tab == 0
                    ? attendanceAsync.when(
                        data: (result) {
                          final todayDays = result.days.where((d) => d.isToday);
                          final todayDay = todayDays.isEmpty ? null : todayDays.first;
                          return _CheckInTab(todayDay: todayDay, onCheckOut: _checkOut, loading: _actionLoading);
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
                        error: (e, _) => V2EmptyState(icon: FitVizV2Icon.grid, title: 'Could not load', message: '$e'),
                      )
                    : const _HistoryTabWrapper(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInTab extends ConsumerWidget {
  final AttendanceDay? todayDay;
  final VoidCallback onCheckOut;
  final bool loading;

  const _CheckInTab({required this.todayDay, required this.onCheckOut, required this.loading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(_userIdProviderV2).valueOrNull;
    final gymId = ref.watch(_gymIdProviderV2).valueOrNull;
    final qrData = userId != null && gymId != null ? 'fitviz:checkin:$gymId:$userId' : null;

    final sessions = todayDay?.sessions ?? const [];
    final lastSession = sessions.isEmpty ? null : sessions.last;
    final isCheckedIn = lastSession != null && lastSession.checkOutTime == null;
    final visitCount = sessions.length;

    ({String label, V2ChipVariant variant, String? sub}) status;
    if (lastSession == null) {
      status = (label: 'Not Checked In', variant: V2ChipVariant.neutral, sub: null);
    } else if (isCheckedIn) {
      status = (
        label: 'Checked In',
        variant: V2ChipVariant.success,
        sub: 'Since ${FitDateUtils.formatTime(lastSession.checkInTime!)}${visitCount > 1 ? ' · Visit #$visitCount today' : ''}',
      );
    } else {
      status = (
        label: 'Completed',
        variant: V2ChipVariant.accent,
        sub: visitCount > 1
            ? '$visitCount visits today · ${_durationLabel(todayDay!.totalDuration)} total'
            : '${FitDateUtils.formatTime(lastSession.checkInTime!)} — ${FitDateUtils.formatTime(lastSession.checkOutTime!)}',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Status", style: FitVizV2Text.body(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                V2Chip(label: status.label, variant: status.variant),
                if (status.sub != null) ...[
                  const SizedBox(height: 8),
                  Text(status.sub!, style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim)),
                ],
              ],
            ),
          ),
          if (isCheckedIn) ...[
            const SizedBox(height: 14),
            V2PillButton(
              label: 'Check Out',
              loading: loading,
              onTap: loading ? null : onCheckOut,
              variant: V2PillButtonVariant.outline,
            ),
          ],
          if (qrData != null) ...[
            const SizedBox(height: 24),
            Text('Show QR code to staff to check in',
                textAlign: TextAlign.center, style: FitVizV2Text.body(size: 13, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Center(
              child: V2QrViewfinderFrame(
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 190, backgroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _durationLabel(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _HistoryTabWrapper extends ConsumerWidget {
  const _HistoryTabWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_historyMonthProviderV2b);
    final now = DateTime.now();
    final isCurrentMonth = selected.year == now.year && selected.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => ref.read(_historyMonthProviderV2b.notifier).state = DateTime(selected.year, selected.month - 1),
              child: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.accent),
            ),
            Text(DateFormat('MMMM yyyy').format(selected), style: FitVizV2Text.body(size: 14, weight: FontWeight.w700)),
            GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () => ref.read(_historyMonthProviderV2b.notifier).state = DateTime(selected.year, selected.month + 1),
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
          child: ref.watch(_historyAttendanceProviderV2((selected.month, selected.year))).when(
                data: (result) => _HistoryTab(days: result.days, stats: result.stats),
                loading: () => const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
                error: (e, _) => Center(child: Text('Error: $e', style: FitVizV2Text.body(color: FitVizV2Colors.inkDim))),
              ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<AttendanceDay> days;
  final AttendanceStats? stats;
  const _HistoryTab({required this.days, this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stats != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                V2ProgressRing(progress: (stats!.totalDays.clamp(0, 30) / 30 * 100), label: '${stats!.totalDays}', size: V2RingSize.md),
                const SizedBox(width: 24),
                V2ProgressRing(
                  progress: (stats!.totalHours.clamp(0, 40) / 40 * 100),
                  label: stats!.totalHours.toStringAsFixed(0),
                  size: V2RingSize.md,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 88, child: Text('days attended', textAlign: TextAlign.center, style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim))),
                  const SizedBox(width: 24),
                  SizedBox(width: 88, child: Text('total hours', textAlign: TextAlign.center, style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (days.isEmpty)
            const V2EmptyState(icon: FitVizV2Icon.grid, title: 'No records yet', message: 'Attendance for this month will show up here.')
          else
            ...days.asMap().entries.map((entry) {
              final day = entry.value;
              final date = day.localDate;
              final totalDur = day.totalDuration;
              return V2TimelineRow(
                isLast: entry.key == days.length - 1,
                dotState: day.isComplete ? V2TimelineDotState.on : V2TimelineDotState.neutral,
                body: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${DateFormat('EEE').format(date)}  ${DateFormat('d MMM yyyy').format(date)}',
                              style: FitVizV2Text.body(size: 13, weight: FontWeight.w700)),
                          ...day.sessions.map((s) => Text(
                                s.checkInTime == null
                                    ? '—'
                                    : s.checkOutTime != null
                                        ? '${FitDateUtils.formatTime(s.checkInTime!)}  →  ${FitDateUtils.formatTime(s.checkOutTime!)}'
                                        : 'Checked in at ${FitDateUtils.formatTime(s.checkInTime!)}',
                                style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim),
                              )),
                        ],
                      ),
                    ),
                    if (totalDur.inMinutes > 0) V2Chip(label: _durationLabel(totalDur)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _durationLabel(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}
