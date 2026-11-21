import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/status_banner.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../cubits/halls_cubit.dart';
import '../widgets/hall_card.dart';

class HallsHomeScreen extends StatelessWidget {
  const HallsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HallsCubit(ServicesLocator.hallsRepo)..loadHalls(),
      child: const _HallsHomeView(),
    );
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
                return const Center(child: CircularProgressIndicator());
              }
              if (state is HallsError) {
                return ErrorState(
                  message: state.message,
                  onRetry: () => context.read<HallsCubit>().loadHalls(),
                );
              }

              final halls = (state is HallsLoaded) ? state.halls : [];

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Header: Greeting & Title on right, Actions (+ and search) on left
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً، أحمد',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.muted,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'قاعاتي',
                              style: AppTextStyles.display,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Add button (Indigo, + icon)
                            CircleIconButton.primary(
                              icon: const Icon(
                                LucideIcons.plus,
                                size: 20,
                                color: AppColors.white,
                              ),
                              onTap: () => context.push('/halls/form'),
                            ),
                            const SizedBox(width: 10),
                            // Search button (White)
                            CircleIconButton.white(
                              icon: const Icon(
                                LucideIcons.search,
                                size: 20,
                                color: AppColors.ink,
                              ),
                              onTap: () => context.push('/bookings'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2) AlertStrip: Due amounts alert
                    AlertStrip(
                      text: '٢ فعاليات خلال ٧ أيام عليها مبالغ متبقية',
                      actionText: 'عرض',
                      onActionTap: () => context.push('/bookings?filter=due'),
                    ),

                    const SizedBox(height: 14),

                    // 3) Hall Cards
                    ...halls.map((hall) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: HallCard(hall: hall),
                      );
                    }),

                    // 4) Legend: Centered row with spacing 14
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        LegendItem(status: DayStatus.available, label: 'متاح'),
                        LegendItem(status: DayStatus.paid, label: 'مدفوع'),
                        LegendItem(status: DayStatus.deposit, label: 'عربون'),
                        LegendItem(status: DayStatus.tentative, label: 'مؤقت'),
                        LegendItem(status: DayStatus.blocked, label: 'محجوب'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
