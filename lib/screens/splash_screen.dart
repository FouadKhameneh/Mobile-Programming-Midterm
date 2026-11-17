import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import 'auth/widgets/brand_ui.dart';

/// Branded dark splash shown while the session is being restored.
///
/// The widget is purely visual: `AppRoot` owns initialization and decides when
/// to replace the splash with onboarding, the auth flow or the main shell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.message = 'در حال آماده‌سازی کتابخانه'});

  final String message;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Theme(
      data: soundifyBrandTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BrandBackdrop(
          child: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder:
                  (BuildContext context, double value, Widget? child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 3),
                  _LogoStage(animation: _controller),
                  const SizedBox(height: 34),
                  Text(
                    'Soundify',
                    style: textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'موسیقی، بی‌وقفه',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(flex: 2),
                  const SoundWaveBars(
                    barCount: 7,
                    height: 34,
                    barWidth: 4,
                    spacing: 5,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 22),
                  _LoadingLabel(
                    controller: _controller,
                    message: widget.message,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نسخه ${toPersianDigits('1.0.0')}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoStage extends StatelessWidget {
  const _LogoStage({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 212,
      height: 212,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final pulse = 0.5 + 0.5 * math.sin(animation.value * 2 * math.pi);
              final size = 190 + pulse * 26;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppColors.primaryDeep.withValues(alpha: 0.30 - pulse * 0.10),
                      AppColors.primaryDeep.withValues(alpha: 0),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                angle: animation.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: <Color>[
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.primary.withValues(alpha: 0.55),
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.accent.withValues(alpha: 0.45),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                  stops: const <double>[0.0, 0.24, 0.5, 0.76, 1.0],
                ),
              ),
            ),
          ),
          Container(
            width: 158,
            height: 158,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[Color(0xFF11131F), Color(0x0007080F)],
              ),
            ),
          ),
          const BrandMark(size: 112),
        ],
      ),
    );
  }
}

class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel({required this.controller, required this.message});

  final AnimationController controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 13,
          letterSpacing: 0.2,
        );
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message, style: style),
            const SizedBox(width: 6),
            ...List<Widget>.generate(3, (int index) {
              final phase = (controller.value + index * 0.14) % 1;
              final opacity =
                  0.2 + 0.8 * (0.5 + 0.5 * math.sin(2 * math.pi * phase));
              return Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: opacity),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
