import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'day_circle.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

enum BookingServiceStatus {
  booked, // محجوز أخضر
  notBooked, // غير محجوز amber
  optional, // اختياري رمادي
  depositOnly, // عربون فقط amber
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
  });

  factory StatusChip.fromStatus(BookingServiceStatus status, {VoidCallback? onTap}) {
    switch (status) {
      case BookingServiceStatus.booked:
        return StatusChip(
          label: 'محجوز',
          backgroundColor: AppColors.greenBg,
          textColor: AppColors.green,
          onTap: onTap,
        );
      case BookingServiceStatus.notBooked:
        return StatusChip(
          label: 'غير محجوز',
          backgroundColor: AppColors.amberBg,
          textColor: AppColors.amberText,
          onTap: onTap,
        );
      case BookingServiceStatus.optional:
        return StatusChip(
          label: 'اختياري',
          backgroundColor: AppColors.greyBg,
          textColor: AppColors.muted,
          onTap: onTap,
        );
      case BookingServiceStatus.depositOnly:
        return StatusChip(
          label: 'عربون فقط',
          backgroundColor: AppColors.amberBg,
          textColor: AppColors.amberText,
          onTap: onTap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: chip,
      );
    }
    return chip;
  }
}

class CapacityChip extends StatelessWidget {
  final int capacity;

  const CapacityChip({
    super.key,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.users,
            size: 14,
            color: AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            '${capacity.toArabicDigits()} مقعد',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final DayStatus status;
  final String label;

  const LegendItem({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DayCircle(
          status: status,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
