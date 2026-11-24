import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/space_helper.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubits/auth_cubit.dart';

class AccountSuspendedScreen extends StatelessWidget {
  final String? message;

  const AccountSuspendedScreen({super.key, this.message});

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
                    color: AppColors.redBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldAlert,
                    size: 44,
                    color: AppColors.red,
                  ),
                ),
              ),
              verticalSpace(24),
              const Text(
                'الحساب موقوف',
                textAlign: TextAlign.center,
                style: AppTextStyles.display,
              ),
              verticalSpace(12),
              Text(
                message ?? 'تم إيقاف حساب هذه المنشأة من قِبل إدارة النظام. يرجى التواصل مع الدعم الفني للمزيد من التفاصيل.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              AppPrimaryButton(
                text: 'تواصل مع الدعم الفني',
                icon: const Icon(LucideIcons.phoneCall, size: 18, color: AppColors.white),
                onPressed: () async {
                  final uri = Uri.parse('tel:01000000000');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
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
