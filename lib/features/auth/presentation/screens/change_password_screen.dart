import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/space_helper.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ServicesLocator.authRepo.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تغيير كلمة المرور بنجاح.',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(
                  title: 'تغيير كلمة المرور',
                  subtitle: 'تحديث كلمة المرور الخاصة بحساب الإدارة',
                ),
                verticalSpace(20),

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
                      // Current Password
                      AppTextField(
                        label: 'كلمة المرور الحالية',
                        controller: _currentController,
                        hint: 'أدخل كلمة المرور الحالية',
                        obscureText: _obscureCurrent,
                        prefixIcon: const Icon(LucideIcons.lock, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال كلمة المرور الحالية' : null,
                      ),
                      verticalSpace(16),

                      // New Password (API requires min 12 chars)
                      AppTextField(
                        label: 'كلمة المرور الجديدة (١٢ حرفاً على الأقل)',
                        controller: _newController,
                        hint: 'أدخل كلمة المرور الجديدة',
                        obscureText: _obscureNew,
                        prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 12) {
                            return 'كلمة المرور يجب ألا تقل عن ١٢ حرفاً';
                          }
                          return null;
                        },
                      ),
                      verticalSpace(16),

                      // Confirm Password
                      AppTextField(
                        label: 'تأكيد كلمة المرور الجديدة',
                        controller: _confirmController,
                        hint: 'أعد إدخال كلمة المرور الجديدة',
                        obscureText: _obscureConfirm,
                        prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (val) {
                          if (val != _newController.text) {
                            return 'كلمتا المرور غير متطابقتين';
                          }
                          return null;
                        },
                      ),
                      verticalSpace(24),

                      AppPrimaryButton(
                        text: 'حفظ كلمة المرور',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
