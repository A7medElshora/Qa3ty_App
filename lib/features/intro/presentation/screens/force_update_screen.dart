import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/cubit/intro_app/intro_app_cubit.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with WidgetsBindingObserver {
  static const _backgroundHighlight = Color(0xFFFBF9F4);
  static const _innerShadow = Color.fromRGBO(43, 46, 92, 0.14);
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckUpdateRequirement();
    }
  }

  Future<void> _recheckUpdateRequirement() async {
    await ServicesLocator.introAppCubit.refreshRemoteConfig(forceFetch: true);
    if (!mounted) return;
    if (ServicesLocator.introAppCubit.state is! ForceUpdate) {
      context.go('/splash?refresh=1');
    }
  }

  Future<void> _openUpdateLink(String link) async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    final uri = Uri.tryParse(link);
    var opened = false;
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } on Exception {
        opened = false;
      }
    }

    if (!mounted) return;
    setState(() => _isLaunching = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح رابط التحديث، حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntroAppCubit, IntroAppState>(
      bloc: ServicesLocator.introAppCubit,
      builder: (context, updateState) {
        final forceUpdate = updateState is ForceUpdate ? updateState : null;
        final latestVersionName = forceUpdate?.latestVersionName.trim() ?? '';

        return PopScope(
          canPop: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.24),
                    radius: 0.85,
                    colors: [
                      _backgroundHighlight,
                      AppColors.background,
                    ],
                    stops: [0, 0.6],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 44),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.sizeOf(context).height -
                                    MediaQuery.paddingOf(context).vertical -
                                    180,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _updateIllustration(),
                                    const SizedBox(height: 40),
                                    const Text(
                                      'حدّث التطبيق',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'نسخة جديدة متاحة، حدّث للمتابعة',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.25),
                                offset: const Offset(0, 8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLaunching || forceUpdate == null
                                  ? null
                                  : () => _openUpdateLink(forceUpdate.appLink),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLaunching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text(
                                      'تحديث الآن',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (latestVersionName.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'الإصدار ${latestVersionName.toArabicDigits().replaceAll('.', '٫')}',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _updateIllustration() {
    return SizedBox(
      width: 208,
      height: 208,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 208,
            height: 208,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _innerShadow,
                  offset: Offset(0, 10),
                  blurRadius: 26,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                LucideIcons.arrowUp,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
