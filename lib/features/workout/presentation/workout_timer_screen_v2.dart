import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_timer_provider.dart';
import '../providers/rest_timer_provider.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_metrics.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_progress_ring.dart';
import '../../../shared/fitviz_v2/widgets/v2_chip.dart';

/// FitViz v2 Workout Timer — a single large dial as the focal point (session
/// timer + play control centered inside it), rather than three stacked
/// boxes. Preserves the legacy live-clock and rest-timer functionality.
class WorkoutTimerScreenV2 extends ConsumerStatefulWidget {
  const WorkoutTimerScreenV2({super.key});

  @override
  ConsumerState<WorkoutTimerScreenV2> createState() => _WorkoutTimerScreenV2State();
}

class _WorkoutTimerScreenV2State extends ConsumerState<WorkoutTimerScreenV2> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _showRestDoneSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rest over — back to it!'),
        backgroundColor: FitVizV2Colors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionTimerProvider);
    final rest = ref.watch(restTimerProvider);
    ref.listen(restTimerProvider, (previous, next) {
      if (previous?.running == true && !next.running) _showRestDoneSnack();
    });
    final sessionMinutes = session.elapsed.inSeconds == 0 ? 0 : (session.elapsed.inSeconds % 3600) / 36;

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const FitVizV2IconView(FitVizV2Icon.chevron, size: 18, color: FitVizV2Colors.ink),
                  ),
                  Expanded(
                    child: Text('Workout Timer',
                        textAlign: TextAlign.center, style: FitVizV2Text.body(size: 17, weight: FontWeight.w800)),
                  ),
                  Text(_formatClock(_now), style: FitVizV2Text.data(size: 12, color: FitVizV2Colors.inkDim)),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // ── Focal dial: session timer + play control ──────────
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          V2ProgressRing(
                            progress: sessionMinutes.toDouble(),
                            label: '',
                            size: V2RingSize.lg,
                            sweepColor: session.running ? FitVizV2Colors.accent : FitVizV2Colors.inkDim,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDuration(session.elapsed),
                                style: FitVizV2Text.data(size: 30, color: session.running ? FitVizV2Colors.accent : FitVizV2Colors.ink),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => ref.read(sessionTimerProvider.notifier).toggle(),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: session.running ? FitVizV2Colors.surface2 : FitVizV2Colors.accent,
                                    border: session.running ? Border.all(color: FitVizV2Colors.danger) : null,
                                  ),
                                  child: Center(
                                    child: session.running
                                        ? const Icon(Icons.pause, color: FitVizV2Colors.danger, size: 24)
                                        : const FitVizV2IconView(FitVizV2Icon.play, size: 20, color: FitVizV2Colors.accentInk),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (session.elapsed > Duration.zero)
                        GestureDetector(
                          onTap: () => ref.read(sessionTimerProvider.notifier).reset(),
                          child: Text('Reset', style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim)),
                        ),
                      const SizedBox(height: 32),
                      // ── Rest timer (secondary) ─────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FitVizV2Colors.surface,
                          border: Border.all(color: rest.running ? FitVizV2Colors.success : FitVizV2Colors.border),
                          borderRadius: BorderRadius.circular(FitVizV2Radius.md),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const FitVizV2IconView(FitVizV2Icon.stopwatch, size: 15, color: FitVizV2Colors.success),
                                const SizedBox(width: 8),
                                Text('REST TIMER', style: FitVizV2Text.caption(color: FitVizV2Colors.inkDim)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _formatDuration(rest.running ? rest.remaining : Duration(seconds: rest.selectedSeconds)),
                              style: FitVizV2Text.data(size: 34, color: rest.running ? FitVizV2Colors.ink : FitVizV2Colors.inkDim),
                            ),
                            const SizedBox(height: 14),
                            if (!rest.running)
                              Wrap(
                                spacing: 8,
                                alignment: WrapAlignment.center,
                                children: rest.presets.map((p) {
                                  final selected = p == rest.selectedSeconds;
                                  return GestureDetector(
                                    onTap: () => ref.read(restTimerProvider.notifier).selectPreset(p),
                                    child: V2Chip(
                                      label: p >= 60 ? '${p ~/ 60}m' : '${p}s',
                                      variant: selected ? V2ChipVariant.accent : V2ChipVariant.neutral,
                                    ),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: rest.running
                                  ? () => ref.read(restTimerProvider.notifier).cancel()
                                  : () => ref.read(restTimerProvider.notifier).start(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                decoration: BoxDecoration(
                                  color: rest.running ? FitVizV2Colors.surface2 : FitVizV2Colors.success,
                                  borderRadius: BorderRadius.circular(FitVizV2Radius.pill),
                                  border: rest.running ? Border.all(color: FitVizV2Colors.danger) : null,
                                ),
                                child: Text(
                                  rest.running ? 'Cancel Rest' : 'Start Rest',
                                  style: TextStyle(
                                    color: rest.running ? FitVizV2Colors.danger : FitVizV2Colors.accentInk,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
