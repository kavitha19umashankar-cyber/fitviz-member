import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/session_timer_provider.dart';
import '../providers/rest_timer_provider.dart';

class WorkoutTimerScreen extends ConsumerStatefulWidget {
  const WorkoutTimerScreen({super.key});

  @override
  ConsumerState<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends ConsumerState<WorkoutTimerScreen> {
  // Clock
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
      SnackBar(
        content: const Text('Rest over — back to it!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
    final s = dt.second.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m:$s $period';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionTimerProvider);
    final rest = ref.watch(restTimerProvider);
    ref.listen(restTimerProvider, (previous, next) {
      if (previous?.running == true && !next.running) _showRestDoneSnack();
    });
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Workout Timer'),
        backgroundColor: AppColors.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Live Clock ──────────────────────────────────────────────────
              _ClockCard(time: _formatClock(_now)),
              const SizedBox(height: 20),

              // ── Session Timer ───────────────────────────────────────────────
              _SessionTimerCard(
                elapsed: session.elapsed,
                running: session.running,
                label: _formatDuration(session.elapsed),
                onToggle: () =>
                    ref.read(sessionTimerProvider.notifier).toggle(),
                onReset: () => ref.read(sessionTimerProvider.notifier).reset(),
              ),
              const SizedBox(height: 20),

              // ── Rest Timer ──────────────────────────────────────────────────
              _RestTimerCard(
                presets: rest.presets,
                selectedSeconds: rest.selectedSeconds,
                remaining: rest.remaining.inSeconds,
                running: rest.running,
                progress: rest.running && rest.selectedSeconds > 0
                    ? rest.remaining.inSeconds / rest.selectedSeconds
                    : 1.0,
                onPresetChanged: rest.running
                    ? null
                    : (v) => ref.read(restTimerProvider.notifier).selectPreset(v),
                onStart: rest.running
                    ? () => ref.read(restTimerProvider.notifier).cancel()
                    : () => ref.read(restTimerProvider.notifier).start(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final String time;
  const _ClockCard({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            'Current Time',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            time,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTimerCard extends StatelessWidget {
  final Duration elapsed;
  final bool running;
  final String label;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const _SessionTimerCard({
    required this.elapsed,
    required this.running,
    required this.label,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: running
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Session Timer',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (elapsed > Duration.zero)
                GestureDetector(
                  onTap: onReset,
                  child: Text('Reset',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: running ? AppColors.primary : AppColors.textPrimary,
                fontSize: 52,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: running
                    ? AppColors.error.withOpacity(0.12)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                border: running
                    ? Border.all(color: AppColors.error.withOpacity(0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    running ? Icons.pause : Icons.play_arrow,
                    color: running ? AppColors.error : AppColors.darkBg,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    running
                        ? 'Pause'
                        : (elapsed > Duration.zero ? 'Resume' : 'Start'),
                    style: TextStyle(
                      color: running ? AppColors.error : AppColors.darkBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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

class _RestTimerCard extends StatelessWidget {
  final List<int> presets;
  final int selectedSeconds;
  final int remaining;
  final bool running;
  final double progress;
  final ValueChanged<int>? onPresetChanged;
  final VoidCallback onStart;

  const _RestTimerCard({
    required this.presets,
    required this.selectedSeconds,
    required this.remaining,
    required this.running,
    required this.progress,
    required this.onPresetChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final displaySeconds = running ? remaining : selectedSeconds;
    final m = (displaySeconds ~/ 60).toString().padLeft(2, '0');
    final s = (displaySeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: running
              ? const Color(0xFF4CAF50).withOpacity(0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_bottom,
                  color: const Color(0xFF4CAF50), size: 18),
              const SizedBox(width: 8),
              Text('Rest Timer',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          // Progress ring
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      running
                          ? (progress < 0.25
                              ? AppColors.error
                              : const Color(0xFF4CAF50))
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$m:$s',
                      style: TextStyle(
                        color: running
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      running ? 'resting' : 'seconds',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Preset chips
          if (!running)
            Wrap(
              spacing: 8,
              children: presets.map((p) {
                final isSelected = p == selectedSeconds;
                return GestureDetector(
                  onTap: () => onPresetChanged?.call(p),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder),
                    ),
                    child: Text(
                      p >= 60 ? '${p ~/ 60}m' : '${p}s',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: running
                    ? AppColors.error.withOpacity(0.12)
                    : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(30),
                border: running
                    ? Border.all(color: AppColors.error.withOpacity(0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    running ? Icons.stop : Icons.play_arrow,
                    color: running ? AppColors.error : Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    running ? 'Cancel Rest' : 'Start Rest',
                    style: TextStyle(
                      color: running ? AppColors.error : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
