import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/providers/session_provider.dart';
import '../data/progress_repository.dart';
import '../../progress_photos/progress_photo_sheet.dart';

final _metricsProvider = FutureProvider<List<BodyMetricModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(progressRepositoryProvider).getMyMetrics(); });

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(_metricsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkBg,
        onPressed: () => _showAddMetric(context, ref),
        child: const Icon(Icons.add),
      ),
      body: metricsAsync.when(
        data: (metrics) => metrics.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    const Text('No measurements yet',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showAddMetric(context, ref),
                      child: const Text('Add First Measurement'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_metricsProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (metrics.length >= 2) ...[
                      _WeightChart(metrics: metrics),
                      const SizedBox(height: 20),
                    ],
                    _LatestStats(latest: metrics.first),
                    const SizedBox(height: 20),
                    Text('History',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...metrics.map((m) => _MetricCard(metric: m)),
                    const SizedBox(height: 24),
                    const ProgressPhotosSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
        loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddMetric(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMetricSheet(
        onAdded: () => ref.invalidate(_metricsProvider),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<BodyMetricModel> metrics;
  const _WeightChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final weightData = metrics
        .where((m) => m.weight != null)
        .toList()
        .reversed
        .toList();
    if (weightData.isEmpty) return const SizedBox.shrink();

    final spots = weightData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight!);
    }).toList();

    final minY = weightData.map((m) => m.weight!).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = weightData.map((m) => m.weight!).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weight (kg)',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.cardBorder, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
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

class _LatestStats extends StatelessWidget {
  final BodyMetricModel latest;
  const _LatestStats({required this.latest});

  @override
  Widget build(BuildContext context) {
    final stats = <Map<String, dynamic>>[
      if (latest.weight != null)
        {'label': 'Weight', 'value': '${latest.weight} kg', 'icon': Icons.monitor_weight_outlined},
      if (latest.bmi != null)
        {'label': 'BMI', 'value': latest.bmi!.toStringAsFixed(1), 'icon': Icons.analytics_outlined},
      if (latest.bodyFat != null)
        {'label': 'Body Fat', 'value': '${latest.bodyFat}%', 'icon': Icons.pie_chart_outline},
      if (latest.muscleMass != null)
        {'label': 'Muscle', 'value': '${latest.muscleMass} kg', 'icon': Icons.fitness_center},
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Latest Stats', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: stats
              .map((s) => _StatTile(
                    label: s['label'] as String,
                    value: s['value'] as String,
                    icon: s['icon'] as IconData,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(value,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final BodyMetricModel metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(metric.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null)
            Text(
              FitDateUtils.formatDate(date),
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (metric.weight != null)
                _MetricChip('Weight', '${metric.weight} kg'),
              if (metric.bmi != null)
                _MetricChip('BMI', metric.bmi!.toStringAsFixed(1)),
              if (metric.bodyFat != null)
                _MetricChip('Body Fat', '${metric.bodyFat}%'),
              if (metric.muscleMass != null)
                _MetricChip('Muscle', '${metric.muscleMass} kg'),
            ],
          ),
          if (metric.notes != null) ...[
            const SizedBox(height: 8),
            Text(metric.notes!,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }
}

class _AddMetricSheet extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _AddMetricSheet({required this.onAdded});

  @override
  ConsumerState<_AddMetricSheet> createState() => _AddMetricSheetState();
}

class _AddMetricSheetState extends ConsumerState<_AddMetricSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _muscleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _muscleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(progressRepositoryProvider).addMetric(
            weight: _weightCtrl.text.isNotEmpty
                ? double.tryParse(_weightCtrl.text)
                : null,
            height: _heightCtrl.text.isNotEmpty
                ? double.tryParse(_heightCtrl.text)
                : null,
            bodyFat: _bodyFatCtrl.text.isNotEmpty
                ? double.tryParse(_bodyFatCtrl.text)
                : null,
            muscleMass: _muscleCtrl.text.isNotEmpty
                ? double.tryParse(_muscleCtrl.text)
                : null,
            notes:
                _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
          );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Measurement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Weight (kg)', suffixText: 'kg'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Height (cm)', suffixText: 'cm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bodyFatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Body Fat', suffixText: '%'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _muscleCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Muscle (kg)', suffixText: 'kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.darkBg))
                  : const Text('Save Measurement'),
            ),
          ],
        ),
      ),
    );
  }
}
