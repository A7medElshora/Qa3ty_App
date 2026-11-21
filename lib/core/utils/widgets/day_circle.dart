import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';

enum DayStatus {
  available,
  paid,
  deposit,
  tentative,
  blocked,
}

class DayCircle extends StatelessWidget {
  final int? dayNumber;
  final DayStatus status;
  final double size;
  final bool isSelected;
  final String? badgeText;
  final bool hasOverdueDot;
  final bool isDimmed;
  final VoidCallback? onTap;

  const DayCircle({
    super.key,
    this.dayNumber,
    required this.status,
    this.size = 34,
    this.isSelected = false,
    this.badgeText,
    this.hasOverdueDot = false,
    this.isDimmed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // When size is 14 (legend item), no numbers or badges
    final bool isSmallLegend = size <= 16;
    final double fontSize = size >= 36 ? 14 : 13;

    Widget circleContent = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDimmed ? 0.25 : 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DayCirclePainter(
              status: status,
              isSelected: isSelected,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: (!isSmallLegend && dayNumber != null)
                  ? Center(
                      child: Text(
                        dayNumber!.toArabicDigits(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(),
                          height: 1.0,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Overdue Dot at top-left
          if (!isSmallLegend && hasOverdueDot)
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),

          // Multi-booking badge at top-left
          if (!isSmallLegend && badgeText != null)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeText!.toArabicDigits(),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: circleContent,
      );
    }
    return circleContent;
  }

  Color _getTextColor() {
    switch (status) {
      case DayStatus.paid:
        return AppColors.white;
      case DayStatus.tentative:
        return AppColors.purple;
      case DayStatus.blocked:
        return AppColors.grey;
      case DayStatus.deposit:
      case DayStatus.available:
        return AppColors.ink;
    }
  }
}

class _DayCirclePainter extends CustomPainter {
  final DayStatus status;
  final bool isSelected;

  _DayCirclePainter({
    required this.status,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final fillPaint = Paint()..isAntiAlias = true;
    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    switch (status) {
      case DayStatus.available:
        fillPaint.color = AppColors.white;
        canvas.drawCircle(center, radius, fillPaint);

        strokePaint.color = AppColors.grey;
        strokePaint.strokeWidth = 1.5;
        canvas.drawCircle(center, radius - 0.75, strokePaint);
        break;

      case DayStatus.paid:
        fillPaint.color = AppColors.green;
        canvas.drawCircle(center, radius, fillPaint);
        break;

      case DayStatus.deposit:
        // Half amber, half white: horizontal gradient [amber, amber, white, white] at [0, 0.5, 0.5, 1]
        // Left to Right physically
        final rect = Rect.fromCircle(center: center, radius: radius);
        fillPaint.shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.amber,
            AppColors.amber,
            AppColors.white,
            AppColors.white,
          ],
          stops: [0.0, 0.5, 0.5, 1.0],
        ).createShader(rect);
        canvas.drawCircle(center, radius, fillPaint);

        strokePaint.color = AppColors.amber;
        strokePaint.strokeWidth = 1.5;
        canvas.drawCircle(center, radius - 0.75, strokePaint);
        break;

      case DayStatus.tentative:
        fillPaint.color = AppColors.white;
        canvas.drawCircle(center, radius, fillPaint);

        // Dashed border: purple 1.5, dash 3-3
        strokePaint.color = AppColors.purple;
        strokePaint.strokeWidth = 1.5;
        _drawDashedCircle(canvas, center, radius - 0.75, strokePaint, 3, 3);
        break;

      case DayStatus.blocked:
        fillPaint.color = AppColors.greyBg;
        canvas.drawCircle(center, radius, fillPaint);
        break;
    }

    // Selected border: primary 3.0
    if (isSelected) {
      final selectedPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..color = AppColors.primary
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius - 1.5, selectedPaint);
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final circumference = 2 * math.pi * radius;
    final totalDashLength = dashLength + gapLength;
    final count = (circumference / totalDashLength).floor();
    final angleStep = (2 * math.pi) / count;
    final dashAngle = angleStep * (dashLength / totalDashLength);

    for (int i = 0; i < count; i++) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayCirclePainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.isSelected != isSelected;
  }
}
