import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/providers/session_provider.dart';
import '../data/classes_repository.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_metrics.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_chip.dart';
import '../../../shared/fitviz_v2/widgets/v2_segmented_control.dart';
import '../../../shared/fitviz_v2/widgets/v2_pill_button.dart';
import '../../../shared/fitviz_v2/widgets/v2_empty_state.dart';

final _scheduleProviderV2 = FutureProvider<List<ClassScheduleModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(classesRepositoryProvider).getSchedule(); });

final _bookingsProviderV2 = FutureProvider<List<BookingModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(classesRepositoryProvider).getMyBookings(); });

class ClassesScreenV2 extends ConsumerStatefulWidget {
  const ClassesScreenV2({super.key});

  @override
  ConsumerState<ClassesScreenV2> createState() => _ClassesScreenV2State();
}

class _ClassesScreenV2State extends ConsumerState<ClassesScreenV2> {
  int _tab = 0;

  void _refreshAll() {
    ref.invalidate(_scheduleProviderV2);
    ref.invalidate(_bookingsProviderV2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Classes', style: FitVizV2Text.h1()),
              const SizedBox(height: 12),
              V2SegmentedControl(
                selectedIndex: _tab,
                labels: const ['Schedule', 'My Bookings'],
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 14),
              Expanded(child: _tab == 0 ? _ScheduleTab(onBooked: _refreshAll) : _BookingsTab(onCancelled: _refreshAll)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _errorState(Object e, WidgetRef ref, VoidCallback onRetry) {
  final is401 = e is DioException && e.response?.statusCode == 401;
  return V2EmptyState(
    icon: is401 ? FitVizV2Icon.lock : FitVizV2Icon.doc,
    title: is401 ? 'Session expired' : 'Could not load classes',
    message: is401 ? 'Please log in again.' : 'Pull down to retry.',
    ctaLabel: 'Retry',
    onCta: onRetry,
  );
}

class _ScheduleTab extends ConsumerWidget {
  final VoidCallback onBooked;
  const _ScheduleTab({required this.onBooked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(_scheduleProviderV2);
    return scheduleAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const V2EmptyState(
            icon: FitVizV2Icon.calendar,
            title: 'No classes scheduled',
            message: 'Check back soon — new sessions get added regularly.',
          );
        }
        return RefreshIndicator(
          color: FitVizV2Colors.accent,
          backgroundColor: FitVizV2Colors.surface,
          onRefresh: () async => ref.invalidate(_scheduleProviderV2),
          child: ListView.builder(
            itemCount: classes.length,
            itemBuilder: (_, i) {
              final cls = classes[i];
              return _ClassCard(
                cls: cls,
                onBook: () async {
                  try {
                    await ref
                        .read(classesRepositoryProvider)
                        .bookClass(cls.id, cls.nextDate ?? DateTime.now().toIso8601String().substring(0, 10));
                    onBooked();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class booked!'), backgroundColor: FitVizV2Colors.success),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to book: $e'), backgroundColor: FitVizV2Colors.danger),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
      error: (e, _) => _errorState(e, ref, () => ref.invalidate(_scheduleProviderV2)),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  final VoidCallback onCancelled;
  const _BookingsTab({required this.onCancelled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(_bookingsProviderV2);
    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return const V2EmptyState(
            icon: FitVizV2Icon.doc,
            title: 'No upcoming bookings',
            message: 'Browse the schedule to reserve your next class.',
          );
        }
        return RefreshIndicator(
          color: FitVizV2Colors.accent,
          backgroundColor: FitVizV2Colors.surface,
          onRefresh: () async => ref.invalidate(_bookingsProviderV2),
          child: ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (_, i) => _BookingCard(
              booking: bookings[i],
              onCancel: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: FitVizV2Colors.surface,
                    title: const Text('Cancel Booking', style: TextStyle(color: FitVizV2Colors.ink)),
                    content: const Text('Are you sure you want to cancel this class?',
                        style: TextStyle(color: FitVizV2Colors.inkDim)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes, Cancel', style: TextStyle(color: FitVizV2Colors.danger)),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                try {
                  await ref.read(classesRepositoryProvider).cancelBooking(bookings[i].id);
                  onCancelled();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled.'), backgroundColor: FitVizV2Colors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: FitVizV2Colors.danger),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
      error: (e, _) => _errorState(e, ref, () => ref.invalidate(_bookingsProviderV2)),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassScheduleModel cls;
  final VoidCallback onBook;
  const _ClassCard({required this.cls, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        border: Border.all(color: FitVizV2Colors.border),
        borderRadius: BorderRadius.circular(FitVizV2Radius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(cls.name, style: FitVizV2Text.body(size: 15, weight: FontWeight.w700))),
              if (cls.isBooked)
                const V2Chip(label: 'Booked', variant: V2ChipVariant.success)
              else if (cls.isFull)
                const V2Chip(label: 'Full', variant: V2ChipVariant.danger),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _metaRow(
                FitVizV2Icon.stopwatch,
                cls.endTime != null
                    ? '${FitDateUtils.formatTimeString(cls.startTime)} – ${FitDateUtils.formatTimeString(cls.endTime!)}'
                    : FitDateUtils.formatTimeString(cls.startTime),
              ),
              if (cls.dayOfWeek != null) _metaRow(FitVizV2Icon.calendar, cls.dayOfWeek!),
              if (cls.trainerName != null) _metaRow(FitVizV2Icon.user, cls.trainerName!),
              if (cls.capacity != null)
                _metaRow(FitVizV2Icon.grid, '${cls.spotsLeft} spots left',
                    color: cls.isFull ? FitVizV2Colors.danger : null),
            ],
          ),
          if (!cls.isBooked && !cls.isFull) ...[
            const SizedBox(height: 12),
            V2PillButton(label: 'Book Class', onTap: onBook),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(FitVizV2Icon icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FitVizV2IconView(icon, size: 12, color: color ?? FitVizV2Colors.inkDim),
        const SizedBox(width: 4),
        Text(text, style: FitVizV2Text.body(size: 12, color: color ?? FitVizV2Colors.inkDim)),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;
  const _BookingCard({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cls = booking.classInfo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        border: Border.all(color: FitVizV2Colors.border),
        borderRadius: BorderRadius.circular(FitVizV2Radius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cls?.name ?? 'Class', style: FitVizV2Text.body(size: 15, weight: FontWeight.w700)),
                if (cls != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    cls.endTime != null
                        ? '${FitDateUtils.formatTimeString(cls.startTime)} – ${FitDateUtils.formatTimeString(cls.endTime!)}'
                        : FitDateUtils.formatTimeString(cls.startTime),
                    style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim),
                  ),
                ],
                if (booking.status != null) ...[
                  const SizedBox(height: 4),
                  V2Chip(label: booking.status!.toUpperCase()),
                ],
              ],
            ),
          ),
          if (booking.status?.toUpperCase() != 'CANCELLED')
            GestureDetector(
              onTap: onCancel,
              child: Text('Cancel', style: FitVizV2Text.body(size: 13, weight: FontWeight.w600, color: FitVizV2Colors.danger)),
            ),
        ],
      ),
    );
  }
}
