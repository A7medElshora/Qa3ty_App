import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';

class CircleIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color? borderColor;
  final double size;
  final List<BoxShadow>? boxShadow;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor = AppColors.white,
    this.borderColor,
    this.size = 40,
    this.boxShadow,
  });

  factory CircleIconButton.primary({
    Key? key,
    required Widget icon,
    VoidCallback? onTap,
    double size = 40,
  }) {
    return CircleIconButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: AppColors.primary,
      size: size,
    );
  }

  factory CircleIconButton.white({
    Key? key,
    required Widget icon,
    VoidCallback? onTap,
    double size = 40,
  }) {
    return CircleIconButton(
      key: key,
      icon: icon,
      onTap: onTap,
      backgroundColor: AppColors.white,
      borderColor: AppColors.line,
      size: size,
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(26, 26, 51, 0.04),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.0) : null,
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
