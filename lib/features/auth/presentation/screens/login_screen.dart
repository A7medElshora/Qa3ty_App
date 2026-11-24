import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/helpers/space_helper.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import '../cubits/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              context.go('/halls');
            } else if (state is AccountSuspendedState) {
              context.go('/suspended');
            } else if (state is SubscriptionExpiredState) {
              context.go('/subscription-expired');
            } else if (state is AuthErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style:
                        const TextStyle(fontFamily: AppTextStyles.fontFamily),
                  ),
                  backgroundColor: AppColors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.building2,
                            size: 40,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      verticalSpace(20),

                      // App Title
                      const Text(
                        'قاعتي | Qa3aty',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display,
                      ),
                      verticalSpace(6),
                      const Text(
                        'نظام إدارة قاعات الأفراح والمناسبات',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted,
                      ),
                      verticalSpace(36),

                      // Card with inputs
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'تسجيل الدخول',
                              style: AppTextStyles.cardTitle,
                            ),
                            verticalSpace(16),

                            // Username
                            AppTextField(
                              label: 'اسم المستخدم',
                              controller: _usernameController,
                              hint: 'أدخل اسم المستخدم',
                              prefixIcon:
                                  const Icon(LucideIcons.user, size: 18),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال اسم المستخدم';
                                }
                                return null;
                              },
                            ),
                            verticalSpace(14),

                            // Password
                            AppTextField(
                              label: 'كلمة المرور',
                              controller: _passwordController,
                              hint: 'أدخل كلمة المرور',
                              obscureText: _obscurePassword,
                              prefixIcon:
                                  const Icon(LucideIcons.lock, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                return null;
                              },
                            ),
                            verticalSpace(24),

                            // Submit Button
                            AppPrimaryButton(
                              text: 'دخول',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submit,
                            ),
                          ],
                        ),
                      ),

                      // Environment label in development
                      if (AppConfig.current.isDevelopment) ...[
                        verticalSpace(24),
                                 ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
