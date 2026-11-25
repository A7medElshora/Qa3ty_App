import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/status_banner.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import 'package:qa3ty_app/features/auth/presentation/cubits/auth_cubit.dart';
import '../cubits/halls_cubit.dart';
import '../widgets/hall_card.dart';

class HallsHomeScreen extends StatelessWidget {
  const HallsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HallsHomeView();
  }
}

class _HallsHomeView extends StatelessWidget {
  const _HallsHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 52, left: 16, right: 16),
          child: BlocBuilder<HallsCubit, HallsState>(
            builder: (context, state) {
              if (state is HallsLoading) {
                return AppSkeletonizer(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 14),
                        const AppSkeletonPanel(height: 205, lineCount: 4),
                        const SizedBox(height: 14),
                        const AppSkeletonPanel(height: 205, lineCount: 4),
                      ],
                    ),
                  ),
                );
              }
              if (state is HallsError) {
                return ErrorState(
                  message: state.message,
                  onRetry: () => context.read<HallsCubit>().loadHalls(),
                );
              }

              final halls = (state is HallsLoaded) ? state.halls : [];
              final upcomingEventsCount = halls.fold<int>(
                0,
                (int total, hall) =>
                    (total + hall.upcomingWeekEventsCount).toInt(),
              );

              // ── When halls exist: scrollable list ─────────────────────────────
              if (halls.isNotEmpty) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 14),
                      AlertStrip(
                        text: 'فعاليات قادمة خلال ٧ أيام: $upcomingEventsCount',
                        actionText: 'التقويم',
                        onActionTap: () => context.push('/calendar'),
                      ),
                      const SizedBox(height: 14),
                      ...halls.map(
                        (hall) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: HallCard(hall: hall),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          LegendItem(
                              status: DayStatus.available, label: 'متاح'),
                          LegendItem(status: DayStatus.paid, label: 'مدفوع'),
                          LegendItem(status: DayStatus.deposit, label: 'عربون'),
                          LegendItem(
                              status: DayStatus.tentative, label: 'مؤقت'),
                          LegendItem(status: DayStatus.blocked, label: 'محجوب'),
                        ],
                      ),
                    ],
                  ),
                );
              }

              // ── Empty state: full-height centered CTA ─────────────────────────
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Big icon in rounded box
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.18),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.building2,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Title
                            const Text(
                              'ابدأ بإضافة أول قاعة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Subtitle
                            const Text(
                              'سجّل قاعتك الأولى وابدأ إدارة\nحجوزاتها ومصروفاتها من مكان واحد',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                height: 1.7,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Big CTA button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () => _openHallForm(context),
                                icon: const Icon(LucideIcons.plus, size: 20),
                                label: const Text(
                                  'أضف أول قاعة الآن',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openHallForm(BuildContext context) async {
    await context.push('/halls/form');
    if (context.mounted) {
      await context.read<HallsCubit>().loadHalls();
    }
  }

  /// Shared header: greeting + "قاعاتي" title + action buttons
  Widget _buildHeader(BuildContext context) {
    final authState = ServicesLocator.authCubit.state;
    final fullName =
        authState is Authenticated ? authState.user.fullName.trim() : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName.isEmpty ? 'مرحباً' : 'مرحباً، $fullName',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'قاعاتي',
              style: AppTextStyles.display,
            ),
          ],
        ),
        Row(
          children: [
            CircleIconButton.primary(
              icon: const Icon(LucideIcons.plus,
                  size: 20, color: AppColors.white),
              onTap: () => _openHallForm(context),
            ),
            const SizedBox(width: 10),
            CircleIconButton.white(
              icon: const Icon(LucideIcons.search,
                  size: 20, color: AppColors.ink),
              onTap: () => context.push('/bookings'),
            ),
          ],
        ),
      ],
    );
  }
}
