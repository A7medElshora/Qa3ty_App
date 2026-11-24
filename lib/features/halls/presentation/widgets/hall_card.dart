import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../../data/models/hall_model.dart';
import '../cubits/halls_cubit.dart';

class HallCard extends StatelessWidget {
  final Hall hall;
  final VoidCallback? onTap;

  const HallCard({
    super.key,
    required this.hall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () => context.push('/halls/${hall.id}/calendar'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1) Top row: Name & location on right, CapacityChip on left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hall.name,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hall.location,
                            style: AppTextStyles.muted,
                          ),
                        ],
                      ),
                    ),
                    CapacityChip(capacity: hall.capacity),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.line, height: 1, thickness: 1),
                const SizedBox(height: 12),

                // 2) Current week strip: 7 columns with space-between
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: hall.currentWeekSchedule.map((day) {
                    return Expanded(
                      child: Center(child: _buildDayColumn(context, day)),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 3) Bottom row: Bookings count on right, Remaining money on left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'هذا الأسبوع: ${hall.weekBookingsCount.toArabicDigits()} حجوزات',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (PermissionGuard.canViewReports)
                      Text(
                        'مستحق ${AppFormatters.formatMoney(hall.upcomingRemainingAmount)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, HallDaySchedule day) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day.dayName,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
            color: day.isToday ? AppColors.primary : AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        DayCircle(
          dayNumber: day.dayNumber,
          status: day.status,
          size: 34,
          onTap: () async {
            if (day.bookingId != null) {
              final wasCancelled =
                  await context.push<bool>('/bookings/${day.bookingId}');
              if (wasCancelled == true && context.mounted) {
                await context.read<HallsCubit>().loadHalls();
              }
            } else if (PermissionGuard.canManageBookings &&
                day.status == DayStatus.available) {
              context
                  .push('/bookings/new?hallId=${hall.id}&day=${day.dayNumber}');
            }
          },
        ),
      ],
    );
  }
}
