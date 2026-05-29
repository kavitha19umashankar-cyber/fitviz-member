import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import 'wellness_provider.dart';

class WellnessCard extends ConsumerWidget {
  const WellnessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessProvider);

    if (state.checkedInToday) {
      return _CheckedInCard(state: state);
    }

    return _CheckInPromptCard(
      onTap: () => _showCheckIn(context, ref),
    );
  }

  void _showCheckIn(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WellnessCheckInSheet(ref: ref),
    );
  }
}

class _CheckInPromptCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CheckInPromptCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.mood, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to do your daily check-in',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CheckedInCard extends StatelessWidget {
  final WellnessState state;
  const _CheckedInCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final energyEmojis = ['', '😴', '😐', '🙂', '😊', '🔥'];
    final moodEmojis = ['', '😔', '😐', '🙂', '😊', '😁'];
    final energy = state.energy ?? 3;
    final mood = state.mood ?? 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Text(
                "Today's Wellness",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _WellnessPill(
                  label: 'Energy', emoji: energyEmojis[energy], value: energy),
              const SizedBox(width: 10),
              _WellnessPill(
                  label: 'Mood', emoji: moodEmojis[mood], value: mood),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.workoutRecommendation,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessPill extends StatelessWidget {
  final String label;
  final String emoji;
  final int value;
  const _WellnessPill(
      {required this.label, required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text('$value/5',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WellnessCheckInSheet extends StatefulWidget {
  final WidgetRef ref;
  const _WellnessCheckInSheet({required this.ref});

  @override
  State<_WellnessCheckInSheet> createState() => _WellnessCheckInSheetState();
}

class _WellnessCheckInSheetState extends State<_WellnessCheckInSheet> {
  int _energy = 3;
  int _mood = 3;

  final _energyLabels = ['', 'Exhausted', 'Tired', 'Okay', 'Good', 'Energised'];
  final _moodLabels = ['', 'Low', 'Meh', 'Okay', 'Happy', 'Great'];
  final _energyEmojis = ['', '😴', '😐', '🙂', '😊', '🔥'];
  final _moodEmojis = ['', '😔', '😐', '🙂', '😊', '😁'];

  Future<void> _save() async {
    await widget.ref.read(wellnessProvider.notifier).checkIn(
          energy: _energy,
          mood: _mood,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("How are you feeling?",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            "This helps us suggest the right workout intensity for you.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          // Energy
          _ScaleRow(
            label: 'Energy Level',
            emojis: _energyEmojis,
            labelTexts: _energyLabels,
            value: _energy,
            onChanged: (v) => setState(() => _energy = v),
          ),
          const SizedBox(height: 20),
          // Mood
          _ScaleRow(
            label: 'Mood',
            emojis: _moodEmojis,
            labelTexts: _moodLabels,
            value: _mood,
            onChanged: (v) => setState(() => _mood = v),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Check-In'),
          ),
        ],
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  final String label;
  final List<String> emojis;
  final List<String> labelTexts;
  final int value;
  final ValueChanged<int> onChanged;

  const _ScaleRow({
    required this.label,
    required this.emojis,
    required this.labelTexts,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(labelTexts[value],
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final idx = i + 1;
            final isSelected = idx == value;
            return GestureDetector(
              onTap: () => onChanged(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emojis[idx],
                        style: TextStyle(fontSize: isSelected ? 26 : 22)),
                    const SizedBox(height: 2),
                    Text('$idx',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
