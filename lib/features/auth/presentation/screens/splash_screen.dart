import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qa3ty_app/core/cubit/intro_app/intro_app_cubit.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import '../cubits/auth_cubit.dart';

/// ألوان الـ Splash مطابقة لقيم Figma بالضبط.
/// لو AppColors عندك فيها نفس القيم استبدلها بها.
class _C {
  static const bg = Color(0xFFF6F3EC);
  static const navy = Color(0xFF2B2D5B);
  static const gold = Color(0xFFC9A24B);
  static const muted = Color(0xFF6B6F85);
  static const green = Color(0xFF2E9E6B);
  static const amber = Color(0xFFE8A317);
  static const grey = Color(0xFFC9CCD6);
  static const white = Colors.white;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ألوان الدوائر السبع النهائية (الأولى على اليمين): كما في فريم 00c
  static const _dotColors = <Color>[
    _C.green,
    _C.green,
    _C.amber,
    _C.green,
    _C.green,
    _C.amber,
    _C.green,
  ];

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  // نبض خفيف للدوائر لو البيانات لسه بتتحمل بعد انتهاء الأنيميشن
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _tileA = _iv(0.00, 0.35);
  late final Animation<double> _nameA = _iv(0.10, 0.45);
  late final Animation<double> _tagA = _iv(0.50, 0.80, Curves.easeOut);
  late final Animation<double> _loadFade = _iv(0.85, 1.00, Curves.easeOut);
  late final List<Animation<double>> _dots = List.generate(
    7,
    (i) => _iv(0.25 + i * 0.08, 0.40 + i * 0.08, Curves.easeOut),
  );

  AuthState? _authResult;
  bool _animDone = false;
  bool _introReady = false;
  bool _forceUpdateRequired = false;
  bool _dataReady = false;
  bool _failed = false;
  bool _navigated = false;
  String? _authFailureMessage;
  String _version = '١٫٠٫٠';

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _ctrl, curve: Interval(a, b, curve: c));

  @override
  void initState() {
    super.initState();
    _ctrl.forward().whenComplete(() {
      _animDone = true;
      if (!_dataReady && !_failed) _pulse.repeat(reverse: true);
      _tryNavigate();
    });
    _loadVersion();
    _initializeIntroBeforeAuth();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = _arabic(info.version));
    } catch (_) {}
  }

  Future<void> _initializeIntroBeforeAuth() async {
    await ServicesLocator.introAppCubit.initApp();
    if (!mounted) return;

    _forceUpdateRequired = ServicesLocator.introAppCubit.state is ForceUpdate;
    _introReady = true;
    if (_forceUpdateRequired) {
      _tryNavigate();
      return;
    }

    context.read<AuthCubit>().checkAuthStatus();
  }

  String _arabic(String s) {
    const d = '٠١٢٣٤٥٦٧٨٩';
    return s
        .replaceAllMapped(RegExp(r'\d'), (m) => d[int.parse(m[0]!)])
        .replaceAll('.', '٫');
  }

  /// يحمّل البيانات الأولية قبل الدخول للتطبيق.
  /// كل دالة لازم ترجع Future تكتمل بعد وصول البيانات للـ Cubit وترمي خطأ عند الفشل.
  Future<void> _loadInitialData() async {
    // TODO: استبدل بالـ Cubits الحقيقية عندك، مثال:
    // await Future.wait([
    //   context.read<HallsCubit>().loadHalls(),
    //   context.read<DashboardCubit>().loadSummary(),
    // ]).timeout(const Duration(seconds: 15));
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _onAuthState(AuthState state) async {
    _authResult = state;
    if (state is Authenticated) {
      _authFailureMessage = null;
      setState(() => _failed = false);
      try {
        await _loadInitialData();
        _dataReady = true;
      } catch (_) {
        if (!mounted) return;
        _pulse.stop();
        setState(() => _failed = true);
        return;
      }
    } else if (state is AuthErrorState) {
      _authFailureMessage = state.message;
      _dataReady = false;
      _pulse.stop();
      setState(() => _failed = true);
      return;
    } else {
      // الحالات الأخرى لا تحتاج بيانات
      _authFailureMessage = null;
      _dataReady = true;
    }
    _pulse.stop();
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_navigated || !mounted) return;
    if (!_animDone || !_introReady) return;
    if (_forceUpdateRequired) {
      _navigated = true;
      context.go('/force-update');
      return;
    }
    if (!_dataReady || _authResult == null) return;
    final s = _authResult!;
    String? route;
    if (s is Authenticated) {
      route = '/halls';
    } else if (s is Unauthenticated) {
      route = '/login';
    } else if (s is AccountSuspendedState) {
      route = '/suspended';
    } else if (s is SubscriptionExpiredState) {
      route = '/subscription-expired';
    }
    if (route == null) return;
    _navigated = true;
    context.go(route);
  }

  void _retry() {
    setState(() => _failed = false);
    _pulse.repeat(reverse: true);
    final s = _authResult;
    if (s is AuthErrorState || s == null) {
      context.read<AuthCubit>().checkAuthStatus();
    } else {
      _onAuthState(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _onAuthState(state),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: LayoutBuilder(
          builder: (context, box) {
            final s = box.maxHeight / 844; // التصميم المرجعي 390×844
            return AnimatedBuilder(
              animation: Listenable.merge([_ctrl, _pulse]),
              builder: (context, _) => Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ..._rings(),
                  _tile(300 * s),
                  _centered(440 * s, _name()),
                  _centered(508 * s, _latin()),
                  _line(542 * s),
                  _centered(558 * s, _tagline()),
                  _centered(704 * s, _loadingOrError()),
                  _centered(744 * s, _dotsRow()),
                  _centered(800 * s, _versionText()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- العناصر ----------

  Widget _centered(double top, Widget child) => Positioned(
        top: top,
        left: 0,
        right: 0,
        child: Center(child: child),
      );

  List<Widget> _rings() {
    // (left, top, radius, alpha) من Figma
    const rings = [
      (-60.0, -70.0, 170.0, 0.22),
      (260.0, -30.0, 120.0, 0.176),
      (-90.0, 640.0, 210.0, 0.154),
    ];
    return [
      for (final r in rings)
        Positioned(
          left: r.$1,
          top: r.$2,
          child: Container(
            width: r.$3 * 2,
            height: r.$3 * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _C.gold.withValues(alpha: r.$4),
                width: 1.5,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _tile(double top) {
    final t = _tileA.value;
    return Positioned(
      top: top + (1 - t) * 40, // يصعد 40px
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.9 + 0.1 * t,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: _C.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(43, 46, 92, 0.14),
                    offset: Offset(0, 10),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      LucideIcons.building2,
                      size: 58,
                      color: _C.navy,
                    ),
                  ),
                  Positioned(
                    left: 88,
                    top: 14,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: _C.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slideFade(Widget child) {
    final t = _nameA.value;
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 22), child: child),
    );
  }

  Widget _name() => _slideFade(const Text(
        'قاعتي',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 46,
          fontWeight: FontWeight.w700,
          color: _C.navy,
          height: 1.6,
        ),
      ));

  Widget _latin() => _slideFade(const Text(
        'QA3ATY',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.gold,
          letterSpacing: 6,
        ),
      ));

  Widget _line(double top) => Positioned(
        top: top,
        left: 0,
        right: 0,
        child: Center(
          child: _slideFade(Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: _C.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
        ),
      );

  Widget _tagline() => Opacity(
        opacity: _tagA.value,
        child: const Text(
          'إدارة قاعات الأفراح والمناسبات بذكاء',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _C.muted,
          ),
        ),
      );

  Widget _dotsRow() {
    final pulse = (_animDone && !_dataReady && !_failed)
        ? 0.55 + 0.45 * _pulse.value
        : 1.0;
    return Directionality(
      textDirection: TextDirection.rtl, // الدائرة الأولى على اليمين
      child: Opacity(
        opacity: pulse,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              _dot(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dot(int i) {
    final t = _dots[i].value;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(_C.white, _dotColors[i], t),
        border: Border.all(
          color: Color.lerp(_C.grey, Colors.transparent, t)!,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _loadingOrError() {
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تعذّر الاتصال بالخادم',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD64545),
            ),
          ),
          if (_authFailureMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _authFailureMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                color: _C.muted,
              ),
            ),
          ],
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _retry,
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.navy,
              ),
            ),
          ),
        ],
      );
    }
    final op = _dataReady ? 1 - _loadFade.value : 1.0;
    return Opacity(
      opacity: op,
      child: const Text(
        'جارٍ التحميل...',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _C.muted,
        ),
      ),
    );
  }

  Widget _versionText() => Opacity(
        opacity: 0.8,
        child: Text(
          'الإصدار $_version',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: _C.muted,
          ),
        ),
      );
}
