import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_log_service.dart';

class LogExerciseSheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final String planDate;

  const LogExerciseSheet({
    super.key,
    required this.exerciseName,
    required this.planDate,
  });

  @override
  ConsumerState<LogExerciseSheet> createState() => _LogExerciseSheetState();
}

class _LogExerciseSheetState extends ConsumerState<LogExerciseSheet> {
  final List<_SetRow> _rows = [_SetRow(setNumber: 1)];
  bool _saving = false;

  void _addSet() {
    setState(() => _rows.add(_SetRow(setNumber: _rows.length + 1)));
  }

  void _removeSet(int index) {
    if (_rows.length <= 1) return;
    setState(() => _rows.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final sets = _rows
        .map((r) => ExerciseSet(
              setNumber: r.setNumber,
              weightKg: double.tryParse(r.weightCtrl.text),
              reps: int.tryParse(r.repsCtrl.text),
            ))
        .toList();

    final log = ExerciseLog(
      exerciseName: widget.exerciseName,
      sets: sets,
      loggedAt: DateTime.now(),
      planDate: widget.planDate,
    );

    final isNewPR = await ref.read(workoutLogProvider.notifier).logExercise(log);

    if (!mounted) return;
    Navigator.pop(context);

    if (isNewPR && log.maxWeight != null) {
      _showPRCelebration(context, log.maxWeight!);
    }
  }

  void _showPRCelebration(BuildContext context, double weight) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'New PR! ${weight}kg on ${widget.exerciseName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(workoutLogProvider.select(
        (s) => s.records.where((r) => r.exerciseName == widget.exerciseName)
            .isNotEmpty
            ? s.records.firstWhere((r) => r.exerciseName == widget.exerciseName)
            : null));

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log Exercise',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      widget.exerciseName,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (record != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'PR: ${record.weightKg}kg',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text('Weight (kg)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Set rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _SetInputRow(
              row: _rows[i],
              onRemove: _rows.length > 1 ? () => _removeSet(i) : null,
            ),
          ),
          const SizedBox(height: 12),
          // Add set button
          GestureDetector(
            onTap: _addSet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.cardBorder, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 4),
                  Text('Add Set',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.darkBg))
                : const Text('Save Log'),
          ),
        ],
      ),
    );
  }
}

class _SetRow {
  final int setNumber;
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();

  _SetRow({required this.setNumber});
}

class _SetInputRow extends StatelessWidget {
  final _SetRow row;
  final VoidCallback? onRemove;

  const _SetInputRow({required this.row, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Set number badge
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${row.setNumber}',
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        // Weight input
        Expanded(
          child: TextField(
            controller: row.weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.textMuted),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Reps input
        Expanded(
          child: TextField(
            controller: row.repsCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.textMuted),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Remove button
        SizedBox(
          width: 28,
          child: onRemove != null
              ? GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close,
                      color: AppColors.textMuted, size: 16),
                )
              : null,
        ),
      ],
    );
  }
}
