import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../flavors/flavor_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/feedback_repository.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int? _npsScore;
  int _overallRating = 0;
  int? _cleanliness;
  int? _equipment;
  int? _staff;
  int? _trainers;
  final _commentCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Color _npsColor(int score) {
    if (score <= 6) return AppColors.error;
    if (score <= 8) return AppColors.warning;
    return AppColors.success;
  }

  String _npsLabel() {
    if (_npsScore == null) return '';
    if (_npsScore! <= 6) return 'Detractor';
    if (_npsScore! <= 8) return 'Passive';
    return 'Promoter';
  }

  Future<void> _submit() async {
    if (_npsScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recommendation score'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate your overall experience'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(feedbackRepositoryProvider).submitFeedback(
            npsScore: _npsScore!,
            overallRating: _overallRating,
            cleanliness: _cleanliness,
            equipment: _equipment,
            staff: _staff,
            trainers: _trainers,
            comment: _commentCtrl.text.trim(),
          );
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView(onDone: () => context.pop());

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Experience')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Text(
              'Your feedback helps us improve ${FlavorConfig.instance.appName} for everyone.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // ── NPS Score ──────────────────────────────────────────────────
            _SectionLabel('How likely are you to recommend us? *'),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Not likely',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                Text('Very likely',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(11, (i) {
                final selected = _npsScore == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _npsScore = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _npsColor(i)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? _npsColor(i)
                              : AppColors.cardBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$i',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_npsScore != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _npsLabel(),
                  style: TextStyle(
                    color: _npsColor(_npsScore!),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // ── Overall Rating ─────────────────────────────────────────────
            _SectionLabel('Overall Experience *'),
            const SizedBox(height: 10),
            _StarRating(
              value: _overallRating,
              size: 36,
              onChanged: (v) => setState(() => _overallRating = v),
            ),
            const SizedBox(height: 28),

            // ── Category Ratings ───────────────────────────────────────────
            _SectionLabel('Rate Specific Areas  (optional)'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _CategoryRatingTile(
                  label: 'Cleanliness',
                  icon: Icons.cleaning_services_outlined,
                  value: _cleanliness ?? 0,
                  onChanged: (v) => setState(() => _cleanliness = v == _cleanliness ? null : v),
                ),
                _CategoryRatingTile(
                  label: 'Equipment',
                  icon: Icons.fitness_center,
                  value: _equipment ?? 0,
                  onChanged: (v) => setState(() => _equipment = v == _equipment ? null : v),
                ),
                _CategoryRatingTile(
                  label: 'Staff',
                  icon: Icons.support_agent_outlined,
                  value: _staff ?? 0,
                  onChanged: (v) => setState(() => _staff = v == _staff ? null : v),
                ),
                _CategoryRatingTile(
                  label: 'Trainers',
                  icon: Icons.person_outline,
                  value: _trainers ?? 0,
                  onChanged: (v) => setState(() => _trainers = v == _trainers ? null : v),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Comment ────────────────────────────────────────────────────
            _SectionLabel('Additional Comments  (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentCtrl,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Share anything specific — what you loved or what we can improve...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────────
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.darkBg),
                    )
                  : const Text('Submit Feedback'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      );
}

class _StarRating extends StatelessWidget {
  final int value;
  final double size;
  final ValueChanged<int> onChanged;

  const _StarRating(
      {required this.value, this.size = 28, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? AppColors.primary : AppColors.textMuted,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

class _CategoryRatingTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  const _CategoryRatingTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < value;
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color:
                      filled ? AppColors.primary : AppColors.textMuted,
                  size: 18,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thank You')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline,
                    color: AppColors.primary, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'Feedback Submitted!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Thank you for helping us improve. Your feedback means a lot to us.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
