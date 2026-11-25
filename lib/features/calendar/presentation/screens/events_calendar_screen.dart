import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';

class EventsCalendarScreen extends StatefulWidget {
  const EventsCalendarScreen({super.key});

  @override
  State<EventsCalendarScreen> createState() => _EventsCalendarScreenState();
}

class _EventsCalendarScreenState extends State<EventsCalendarScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final bookings = await ServicesLocator.bookingsRepo.getBookings();
      if (!mounted) return;
      final events = bookings
          .where(
              (booking) => booking.status != BookingLifecycleStatus.cancelled)
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
      setState(() {
        _bookings = events;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, List<Booking>> get _bookingsByHall {
    final grouped = <String, List<Booking>>{};
    for (final booking in _bookings) {
      grouped.putIfAbsent(booking.hallId, () => []).add(booking);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsByHall = _bookingsByHall;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 52,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: AppHeader(
                title: 'تقويم الفعاليات',
                subtitle: 'كل الفعاليات مرتبة حسب القاعة والتاريخ',
                onBackTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const AppListSkeleton(itemCount: 5)
                  : _errorMessage != null
                      ? ErrorState(
                          message: _errorMessage!,
                          onRetry: _loadEvents,
                        )
                      : _bookings.isEmpty
                          ? const EmptyState(
                              title: 'لا توجد فعاليات مسجلة',
                              subtitle: 'ستظهر الحجوزات النشطة هنا حسب القاعة.',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadEvents,
                              child: ListView(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 8,
                                  bottom: 96,
                                ),
                                children: bookingsByHall.values.expand((items) {
                                  return [
                                    _hallHeader(items.first),
                                    const SizedBox(height: 8),
                                    ...items.map(_eventCard),
                                    const SizedBox(height: 12),
                                  ];
                                }).toList(),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hallHeader(Booking booking) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          const Icon(LucideIcons.building2, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(booking.hallName, style: AppTextStyles.cardTitle),
          ),
          Text(
            '${_bookingsByHall[booking.hallId]?.length ?? 0} فعاليات',
            style: AppTextStyles.muted,
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: () => context.push('/bookings/${booking.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          child: const Icon(LucideIcons.calendarDays,
              size: 18, color: AppColors.primary),
        ),
        title: Text(booking.customerName, style: AppTextStyles.cardTitle),
        subtitle: Text(
          '${AppFormatters.formatFullDate(booking.eventDate)} · ${booking.eventType}\n${booking.timeRange}',
          style: AppTextStyles.muted,
        ),
        isThreeLine: true,
        trailing: const Icon(LucideIcons.chevronLeft, color: AppColors.muted),
      ),
    );
  }
}
