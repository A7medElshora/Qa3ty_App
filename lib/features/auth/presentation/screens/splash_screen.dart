import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/space_helper.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import '../cubits/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startCheck();
  }

  void _startCheck() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        context.read<AuthCubit>().checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/halls');
        } else if (state is Unauthenticated) {
          context.go('/login');
        } else if (state is AccountSuspendedState) {
          context.go('/suspended');
        } else if (state is SubscriptionExpiredState) {
          context.go('/subscription-expired');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: const Icon(
                  LucideIcons.building2,
                  size: 46,
                  color: AppColors.gold,
                ),
              ),
              verticalSpace(18),
              const Text(
                'قاعتي | Qa3aty',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
              ),
              verticalSpace(30),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              const Spacer(),
              Text(
                'All Rights Reserved © qa3ty_app 2026',
                style: AppStyle.font15_500Weight.copyWith(
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
              verticalSpace(24),
            ],
          ),
        ),
      ),
    );
  }
}
