import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // between 0.0 and 1.0
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final double borderRadius;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.fillColor = AppColors.green,
    this.backgroundColor = AppColors.line,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      // In RTL, filling from right is the natural start
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: clampedProgress,
        heightFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
