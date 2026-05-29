import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import 'hydration_provider.dart';

class HydrationCard extends ConsumerWidget {
  const HydrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationProvider);
    final litres = (state.consumed / 1000).toStringAsFixed(1);
    final goalLitres = (state.goalMl / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isGoalMet
              ? const Color(0xFF29B6F6).withOpacity(0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined,
                  color: const Color(0xFF29B6F6), size: 18),
              const SizedBox(width: 8),
              Text(
                'Hydration',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${litres}L / ${goalLitres}L',
                style: TextStyle(
                  color: state.isGoalMet
                      ? const Color(0xFF29B6F6)
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fill bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.fraction,
              minHeight: 10,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isGoalMet
                    ? const Color(0xFF29B6F6)
                    : const Color(0xFF29B6F6).withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${state.glasses} glasses',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              if (state.isGoalMet) ...[
                const SizedBox(width: 6),
                const Text('Goal reached!',
                    style: TextStyle(
                        color: Color(0xFF29B6F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
              const Spacer(),
              // Remove glass
              if (state.glasses > 0)
                GestureDetector(
                  onTap: () => ref.read(hydrationProvider.notifier).removeGlass(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Icon(Icons.remove, size: 16, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(width: 8),
              // Add glass
              GestureDetector(
                onTap: () => ref.read(hydrationProvider.notifier).addGlass(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF29B6F6).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: const Color(0xFF29B6F6)),
                      const SizedBox(width: 4),
                      Text('250ml',
                          style: TextStyle(
                              color: const Color(0xFF29B6F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
