import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/providers/session_provider.dart';
import '../data/classes_repository.dart';

Widget _errorWidget(Object e, WidgetRef ref) {
  final is401 = e is DioException && e.response?.statusCode == 401;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            is401 ? Icons.lock_outline : Icons.wifi_off_outlined,
            color: AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            is401
                ? 'Session expired.\nPlease log in again.'
                : 'Could not load classes.\nPull down to retry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(_scheduleProvider);
              ref.invalidate(_bookingsProvider);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    ),
  );
}

final _scheduleProvider = FutureProvider<List<ClassScheduleModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(classesRepositoryProvider).getSchedule(); });

final _bookingsProvider = FutureProvider<List<BookingModel>>(
    (ref) { ref.watch(sessionVersionProvider); return ref.read(classesRepositoryProvider).getMyBookings(); });

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen>
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
        title: const Text('Classes'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Schedule'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ScheduleTab(onBooked: () {
            ref.invalidate(_scheduleProvider);
            ref.invalidate(_bookingsProvider);
          }),
          _BookingsTab(onCancelled: () {
            ref.invalidate(_scheduleProvider);
            ref.invalidate(_bookingsProvider);
          }),
        ],
      ),
    );
  }
}

class _ScheduleTab extends ConsumerWidget {
  final VoidCallback onBooked;
  const _ScheduleTab({required this.onBooked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(_scheduleProvider);
    return scheduleAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(
            child: Text('No classes scheduled',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(_scheduleProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (_, i) => _ClassCard(
              cls: classes[i],
              onBook: () async {
                try {
                  await ref
                      .read(classesRepositoryProvider)
                      .bookClass(classes[i].id, classes[i].nextDate ?? DateTime.now().toIso8601String().substring(0, 10));
                  onBooked();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Class booked!'),
                          backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to book: $e'),
                          backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _errorWidget(e, ref),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  final VoidCallback onCancelled;
  const _BookingsTab({required this.onCancelled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(_bookingsProvider);
    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return const Center(
            child: Text('No upcoming bookings',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(_bookingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (_, i) => _BookingCard(
              booking: bookings[i],
              onCancel: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.cardBg,
                    title: const Text('Cancel Booking'),
                    content: const Text('Are you sure you want to cancel this class?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Yes, Cancel',
                              style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm != true) return;
                try {
                  await ref
                      .read(classesRepositoryProvider)
                      .cancelBooking(bookings[i].id);
                  onCancelled();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking cancelled.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _errorWidget(e, ref),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cls.name,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
              if (cls.isBooked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Booked',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                )
              else if (cls.isFull)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Full',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                cls.endTime != null
                    ? '${FitDateUtils.formatTimeString(cls.startTime)} – ${FitDateUtils.formatTimeString(cls.endTime!)}'
                    : FitDateUtils.formatTimeString(cls.startTime),
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (cls.dayOfWeek != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(cls.dayOfWeek!,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ],
          ),
          if (cls.trainerName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(cls.trainerName!,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ],
          if (cls.capacity != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${cls.spotsLeft} spots left',
                  style: TextStyle(
                      color: cls.isFull
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontSize: 13),
                ),
              ],
            ),
          ],
          if (!cls.isBooked && !cls.isFull) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.darkBg),
                child: const Text('Book Class'),
              ),
            ),
          ],
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls?.name ?? 'Class',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                if (cls != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    cls.endTime != null
                        ? '${FitDateUtils.formatTimeString(cls.startTime)} – ${FitDateUtils.formatTimeString(cls.endTime!)}'
                        : FitDateUtils.formatTimeString(cls.startTime),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                if (booking.status != null) ...[
                  SizedBox(height: 4),
                  Text(
                    booking.status!.toUpperCase(),
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          if (booking.status?.toUpperCase() != 'CANCELLED')
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
