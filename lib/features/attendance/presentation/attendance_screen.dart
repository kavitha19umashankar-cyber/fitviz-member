import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/session_provider.dart';
import '../data/attendance_repository.dart';
import '../../workout/presentation/workout_screen.dart' show todayAttendanceProvider;

// Current-month provider used by the Check In tab
final _myAttendanceProvider = FutureProvider<AttendanceResult>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(attendanceRepositoryProvider).getMyAttendance();
});

// History tab: selected month (defaults to current month)
final _historyMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

// History tab: one cached provider per (month, year) pair
final _historyAttendanceProvider =
    FutureProvider.family<AttendanceResult, (int, int)>((ref, params) {
  ref.watch(sessionVersionProvider);
  final (month, year) = params;
  return ref
      .read(attendanceRepositoryProvider)
      .getMyAttendance(month: month, year: year);
});

final _userIdProvider = FutureProvider<String?>((ref) { ref.watch(sessionVersionProvider); return SecureStorage.getUserId(); });
final _gymIdProvider = FutureProvider<String?>((ref) { ref.watch(sessionVersionProvider); return SecureStorage.getGymId(); });

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _checkOut() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(attendanceRepositoryProvider).checkOut();
      ref.invalidate(_myAttendanceProvider);
      ref.invalidate(todayAttendanceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked out. Great workout!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Check-out failed. Please try again.');
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(_myAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Check In'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Check-in panel ────────────────────────────────────────
          attendanceAsync.when(
            data: (result) {
              final todayDays = result.days.where((d) => d.isToday);
              final todayDay = todayDays.isEmpty ? null : todayDays.first;
              return _CheckInTab(
                todayDay: todayDay,
                onCheckOut: _checkOut,
                loading: _actionLoading,
              );
            },
            loading: () =>
                Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // ── Tab 2: History ───────────────────────────────────────────────
          const _HistoryTabWrapper(),
        ],
      ),
    );
  }
}

class _CheckInTab extends ConsumerWidget {
  final AttendanceDay? todayDay;
  final VoidCallback onCheckOut;
  final bool loading;

  const _CheckInTab({
    required this.todayDay,
    required this.onCheckOut,
    required this.loading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(_userIdProvider).valueOrNull;
    final gymId = ref.watch(_gymIdProvider).valueOrNull;
    final qrData = userId != null && gymId != null
        ? 'fitviz:checkin:$gymId:$userId'
        : null;

    // Status is driven by the most recent session today — an open session
    // (no checkOut yet) means the member is currently checked in.
    final sessions = todayDay?.sessions ?? const [];
    final lastSession = sessions.isEmpty ? null : sessions.last;
    final isCheckedIn = lastSession != null && lastSession.checkOutTime == null;
    final visitCount = sessions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Status",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (lastSession == null)
                  _StatusChip(label: 'Not Checked In', color: AppColors.textMuted)
                else if (isCheckedIn)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusChip(label: 'Checked In', color: AppColors.success),
                      const SizedBox(height: 8),
                      Text(
                        'Since ${FitDateUtils.formatTime(lastSession.checkInTime!)}'
                        '${visitCount > 1 ? ' · Visit #$visitCount today' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusChip(label: 'Completed', color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        visitCount > 1
                            ? '$visitCount visits today · ${_durationLabel(todayDay!.totalDuration)} total'
                            : '${FitDateUtils.formatTime(lastSession.checkInTime!)} — ${FitDateUtils.formatTime(lastSession.checkOutTime!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action button — check-out only (check-in is via QR code or staff)
          if (isCheckedIn) ...[
            OutlinedButton.icon(
              onPressed: loading ? null : onCheckOut,
              icon: loading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Check Out'),
            ),
          ],
          const SizedBox(height: 28),
          // QR Code for staff to scan
          if (qrData != null) ...[
            Text('Show QR code to staff to check in',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wraps the history tab with a month selector and its own provider.
class _HistoryTabWrapper extends ConsumerWidget {
  const _HistoryTabWrapper();

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
        // ── Records for selected month ──────────────────────────────────
        Expanded(
          child: ref
              .watch(_historyAttendanceProvider(
                  (selected.month, selected.year)))
              .when(
                data: (result) => _HistoryTab(
                    days: result.days, stats: result.stats),
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

String _durationLabel(Duration d) {
  if (d.inHours >= 1) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  return '${d.inMinutes}m';
}

class _HistoryTab extends StatelessWidget {
  final List<AttendanceDay> days;
  final AttendanceStats? stats;

  const _HistoryTab({required this.days, this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats header ────────────────────────────────────────────────
        if (stats != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    label: 'Days attended',
                    value: '${stats!.totalDays}',
                    unit: 'days',
                  ),
                ),
                Container(
                    width: 1,
                    height: 36,
                    color: AppColors.cardBorder),
                Expanded(
                  child: _StatBlock(
                    label: 'Total time',
                    value: stats!.totalHours.toStringAsFixed(1),
                    unit: 'hours',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // ── Records list — one card per day, with every session inside ───
        if (days.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('No attendance records this month.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...days.map((day) {
            final date = day.localDate;
            final dayName = DateFormat('EEE').format(date);
            final fullDate = DateFormat('d MMM yyyy').format(date);
            final totalDur = day.totalDuration;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: day.isComplete
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      day.isComplete
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      color: day.isComplete
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              fullDate,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ...day.sessions.map((s) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                s.checkInTime == null
                                    ? '—'
                                    : s.checkOutTime != null
                                        ? '${FitDateUtils.formatTime(s.checkInTime!)}  →  ${FitDateUtils.formatTime(s.checkOutTime!)}'
                                        : 'Checked in at ${FitDateUtils.formatTime(s.checkInTime!)}',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            )),
                      ],
                    ),
                  ),
                  if (totalDur.inMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _durationLabel(totalDur),
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatBlock(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22)),
              TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
