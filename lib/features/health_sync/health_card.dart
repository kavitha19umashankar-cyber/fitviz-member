import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import 'health_service.dart';

class HealthSyncCard extends ConsumerWidget {
  const HealthSyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthDataProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (!data.authorized) {
          return _PermissionPrompt(
            onTap: () async {
              await HealthService.requestPermissions();
              ref.invalidate(healthDataProvider);
            },
          );
        }
        return _HealthMetricsCard(data: data);
      },
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionPrompt({required this.onTap});

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
                color: const Color(0xFFFF3B30).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite, color: Color(0xFFFF3B30), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Apple Health',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Read steps, heart rate & calories from Apple Health',
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

class _HealthMetricsCard extends StatelessWidget {
  final HealthData data;
  const _HealthMetricsCard({required this.data});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.favorite, color: Color(0xFFFF3B30), size: 16),
              const SizedBox(width: 6),
              Text(
                'Apple Health',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (data.steps != null)
                Expanded(
                  child: _MetricPill(
                    icon: Icons.directions_walk,
                    value: _formatSteps(data.steps!),
                    label: 'Steps',
                    color: AppColors.primary,
                  ),
                ),
              if (data.heartRate != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(
                    icon: Icons.favorite_outline,
                    value: '${data.heartRate!.toInt()} bpm',
                    label: 'Avg HR',
                    color: AppColors.error,
                  ),
                ),
              ],
              if (data.caloriesBurned != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(
                    icon: Icons.local_fire_department_outlined,
                    value: '${data.caloriesBurned!.toInt()} kcal',
                    label: 'Burned',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
