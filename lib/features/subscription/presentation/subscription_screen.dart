import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/theme/app_theme.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../../core/providers/session_provider.dart';
import '../data/subscription_repository.dart';

final _currentSubProvider = FutureProvider<SubscriptionStatusModel?>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(dashboardRepositoryProvider).getMySubscription(); });

final _subscriptionHistoryProvider =
    FutureProvider<List<SubscriptionHistoryModel>>(
        (ref) { ref.watch(sessionVersionProvider); return ref.read(subscriptionRepositoryProvider).getSubscriptionHistory(); });

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _PlansTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

class _PlansTab extends ConsumerWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSub = ref.watch(_currentSubProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (currentSub != null)
          _CurrentSubCard(subscription: currentSub)
        else
          const Center(
            child: Text('No active subscription',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
      ],
    );
  }
}

class _CurrentSubCard extends StatelessWidget {
  final SubscriptionStatusModel subscription;
  const _CurrentSubCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final isActive = subscription.status.toUpperCase() == 'ACTIVE';
    final endDate = subscription.endDate != null
        ? DateTime.tryParse(subscription.endDate!)
        : null;
    final daysLeft =
        endDate != null ? FitDateUtils.daysUntil(endDate) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isActive
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.verified_outlined : Icons.warning_outlined,
                color: isActive ? AppColors.primary : AppColors.error,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Current: ${subscription.planName}',
                style: TextStyle(
                    color: isActive ? AppColors.primary : AppColors.error,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 6),
            Text(
              isActive
                  ? '$daysLeft days remaining (expires ${FitDateUtils.formatDate(endDate!)})'
                  : 'Expired on ${FitDateUtils.formatDate(endDate!)}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_subscriptionHistoryProvider);
    return historyAsync.when(
      data: (subs) {
        if (subs.isEmpty) {
          return const Center(
            child: Text('No subscription history',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subs.length,
          itemBuilder: (_, i) => _SubscriptionHistoryCard(sub: subs[i]),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SubscriptionHistoryCard extends StatelessWidget {
  final SubscriptionHistoryModel sub;
  const _SubscriptionHistoryCard({required this.sub});

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.primary;
      case 'TOPUP':
        return const Color(0xFF4FC3F7);
      case 'EXPIRED':
        return AppColors.textMuted;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return Icons.verified_outlined;
      case 'TOPUP':
        return Icons.queue_outlined;
      case 'EXPIRED':
        return Icons.history_outlined;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(sub.status);
    final startDt = sub.startDate != null ? DateTime.tryParse(sub.startDate!) : null;
    final endDt = sub.endDate != null ? DateTime.tryParse(sub.endDate!) : null;

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_statusIcon(sub.status), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.planName,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 3),
                if (startDt != null && endDt != null)
                  Text(
                    '${FitDateUtils.formatDate(startDt)}  →  ${FitDateUtils.formatDate(endDt)}',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub.status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (sub.amountPaid != null)
            Text(
              '₹${sub.amountPaid!.toInt()}',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
        ],
      ),
    );
  }
}
