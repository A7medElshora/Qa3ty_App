import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/space_helper.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import '../cubits/auth_cubit.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  final String? message;

  const SubscriptionExpiredScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.amberBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    size: 44,
                    color: AppColors.amber,
                  ),
                ),
              ),
              verticalSpace(24),
              const Text(
                'انتهى الاشتراك',
                textAlign: TextAlign.center,
                style: AppTextStyles.display,
              ),
              verticalSpace(12),
              Text(
                message ??
                    'انتهت فترة اشتراك المنشأة في التطبيق. يرجى التواصل مع مطور التطبيق لتجديد الاشتراك واستعادة الصلاحيات.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              AppPrimaryButton(
                text: 'التواصل مع المطور للتجديد',
                icon: const Icon(LucideIcons.creditCard,
                    size: 18, color: AppColors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'يرجى التواصل مع مطور التطبيق عبر قناة الدعم المعتمدة لتجديد الاشتراك.',
                      ),
                    ),
                  );
                },
              ),
              verticalSpace(12),
              AppSecondaryButton(
                text: 'تسجيل الخروج',
                onPressed: () async {
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
