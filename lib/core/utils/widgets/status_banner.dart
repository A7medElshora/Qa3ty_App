import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';

class StatusBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final Color dotColor;
  final Color textColor;
  final double borderRadius;

  const StatusBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundColor = AppColors.amberBg,
    this.dotColor = AppColors.amber,
    this.textColor = AppColors.amberText,
    this.borderRadius = 18,
  });

  factory StatusBanner.deposit({
    Key? key,
    required String title,
    String? subtitle,
  }) {
    return StatusBanner(
      key: key,
      title: title,
      subtitle: subtitle,
      backgroundColor: AppColors.amberBg,
      dotColor: AppColors.amber,
      textColor: AppColors.amberText,
      borderRadius: 18,
    );
  }

  factory StatusBanner.paid({
    Key? key,
    required String title,
    String? subtitle,
  }) {
    return StatusBanner(
      key: key,
      title: title,
      subtitle: subtitle,
      backgroundColor: AppColors.greenBg,
      dotColor: AppColors.green,
      textColor: AppColors.green,
      borderRadius: 18,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertStrip extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback? onActionTap;
  final Color backgroundColor;
  final Color dotColor;
  final Color textColor;
  final double borderRadius;

  const AlertStrip({
    super.key,
    required this.text,
    this.actionText = 'عرض',
    this.onActionTap,
    this.backgroundColor = AppColors.amberBg,
    this.dotColor = AppColors.amber,
    this.textColor = AppColors.ink,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
