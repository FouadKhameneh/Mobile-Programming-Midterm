import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../state/auth_provider.dart';
import 'auth/widgets/brand_ui.dart';

/// Branded lock screen shown when a stored session is protected by biometrics.
///
/// It attempts a biometric unlock once, right after the first frame. If the
/// user gives up, "ورود با رمز عبور" clears the session and returns to login.
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _attempting = false;
  bool _autoTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoUnlock());
  }

  Future<void> _autoUnlock() async {
    if (_autoTriggered || !mounted) return;
    _autoTriggered = true;
    final auth = context.read<AuthProvider>();
    if (!auth.biometricEnabled) return;
    await _attempt(auth);
  }

  Future<void> _attempt(AuthProvider auth) async {
    if (_attempting) return;
    setState(() => _attempting = true);
    await auth.unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _attempting = false);
  }

  Future<void> _retry() async {
    final auth = context.read<AuthProvider>();
    await _attempt(auth);
  }

  Future<void> _usePassword() async {
    if (_attempting) return;
    final auth = context.read<AuthProvider>();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final greeting = user != null ? 'سلام ${user.name}' : 'خوش برگشتی';
    final textTheme = Theme.of(context).textTheme;

    return Theme(
      data: soundifyBrandTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BrandBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const BrandMark(size: 54, glow: false),
                          const SizedBox(height: 14),
                          Text(
                            'Soundify',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 34),
                          _PulseFingerprint(active: _attempting),
                          const SizedBox(height: 32),
                          Text(
                            greeting,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'برای ادامه، هویت خود را با اثر انگشت یا چهره تأیید کن.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.85,
                            ),
                          ),
                          if (user != null && user.email.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 18),
                            GlassPill(
                              icon: Icons.alternate_email_rounded,
                              label: user.email,
                            ),
                          ],
                          const SizedBox(height: 26),
                          AuthMessageBanner(message: auth.error),
                          GradientButton(
                            label: 'ورود بیومتریک',
                            icon: Icons.fingerprint_rounded,
                            loading: _attempting,
                            onPressed: _attempting ? null : _retry,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _attempting ? null : _usePassword,
                              icon: const Icon(
                                Icons.password_rounded,
                                size: 19,
                                color: AppColors.accent,
                              ),
                              label: const Text('ورود با رمز عبور'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.04),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'حساب تو با احراز هویت همین دستگاه محافظت می‌شود؛ رمز عبور همیشه در دسترس است.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseFingerprint extends StatefulWidget {
  const _PulseFingerprint({required this.active});

  final bool active;

  @override
  State<_PulseFingerprint> createState() => _PulseFingerprintState();
}

class _PulseFingerprintState extends State<_PulseFingerprint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...List<Widget>.generate(3, (int index) {
                final progress = (_controller.value + index / 3) % 1;
                final size = 118 + 66 * progress;
                final opacity =
                    (1 - progress) * (widget.active ? 0.5 : 0.32);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: opacity),
                      width: 1.4,
                    ),
                  ),
                );
              }),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF7C3AED), Color(0xFFC026D3)],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primaryDeep.withValues(alpha: 0.5),
                      blurRadius: 34,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: math.sin(_controller.value * 2 * math.pi) * 0.02,
                  child: Icon(
                    widget.active
                        ? Icons.fingerprint_rounded
                        : Icons.lock_outline_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
