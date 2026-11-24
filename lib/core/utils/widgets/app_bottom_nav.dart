import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';

class NavItemData {
  final IconData icon;
  final String label;
  final int branchIndex;
  final bool hasBadge;

  const NavItemData({
    required this.icon,
    required this.label,
    required this.branchIndex,
    this.hasBadge = false,
  });
}

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with TickerProviderStateMixin {
  static const List<NavItemData> _items = [
    NavItemData(
      icon: LucideIcons.building2,
      label: 'القاعات',
      branchIndex: 0,
    ),
    NavItemData(
      icon: LucideIcons.receipt,
      label: 'المصروفات',
      branchIndex: 1,
    ),
    NavItemData(
      icon: LucideIcons.bell,
      label: 'الإشعارات',
      branchIndex: 2,
      hasBadge: true,
    ),
    NavItemData(
      icon: LucideIcons.users,
      label: 'العملاء',
      branchIndex: 3,
    ),
    NavItemData(
      icon: LucideIcons.ellipsis,
      label: 'المزيد',
      branchIndex: 4,
    ),
  ];

  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final visibleItems = _items
        .where(
          (item) => item.branchIndex != 1 || PermissionGuard.canManageExpenses,
        )
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(26, 26, 51, 0.08),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 12,
        left: 8,
        right: 8,
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: List.generate(visibleItems.length, (index) {
            final item = visibleItems[index];
            final isSelected = widget.currentIndex == item.branchIndex;

            return Expanded(
              flex: isSelected ? 4 : 2,
              child: Center(
                child: _buildAnimatedNavItem(
                  index: item.branchIndex,
                  item: item,
                  isSelected: isSelected,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem({
    required int index,
    required NavItemData item,
    required bool isSelected,
  }) {
    final isTapped = _tappedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _tappedIndex = index),
      onTapUp: (_) {
        setState(() => _tappedIndex = null);
        widget.onTap(index);
      },
      onTapCancel: () => setState(() => _tappedIndex = null),
      child: AnimatedScale(
        scale: isTapped ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.fastOutSlowIn,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 10 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedRotation(
                    turns: isSelected ? 0.03 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    child: Icon(
                      item.icon,
                      size: 20,
                      color:
                          isSelected ? AppColors.white : AppColors.tabInactive,
                    ),
                  ),
                  if (item.hasBadge && !isSelected)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.white, width: 1.2),
                        ),
                      ),
                    ),
                ],
              ),

              // Animated Text Label on expansion
              if (isSelected)
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
