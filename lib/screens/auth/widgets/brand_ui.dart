import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

/// Dark, branded theme shared by the splash, onboarding and auth surfaces.
///
/// These surfaces intentionally stay dark so the first-run experience keeps the
/// same premium identity even when the user later selects the light app theme.
final ThemeData soundifyBrandTheme = AppTheme.dark();

/// Full-screen midnight gradient with soft violet/cyan ambient glows.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0C0E1B),
            AppColors.background,
            Color(0xFF0B0712),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: -130,
            right: -90,
            child: _AmbientOrb(
              size: 340,
              color: AppColors.primaryDeep.withValues(alpha: 0.42),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -120,
            child: _AmbientOrb(
              size: 390,
              color: AppColors.accent.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 190,
            left: -180,
            child: _AmbientOrb(
              size: 320,
              color: AppColors.pink.withValues(alpha: 0.10),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// The Soundify logo mark rendered on a soft glass tile.
///
/// [logo_mark.png] is a white-on-transparent asset, so it always sits on the
/// dark brand canvas; [glow] adds a violet halo behind the tile.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 72,
    this.glow = true,
    this.tile = true,
  });

  final double size;
  final bool glow;
  final bool tile;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.3;
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: tile
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0x2BFFFFFF), Color(0x0AFFFFFF)],
                )
              : null,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Image.asset(
          'assets/images/logo_mark.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.graphic_eq_rounded,
            size: size * 0.52,
            color: AppColors.accent,
          ),
        ),
      ),
    );

    if (!glow) return mark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.45),
            blurRadius: size * 0.55,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      child: mark,
    );
  }
}

/// Translucent card used across the branded surfaces.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.075),
            Colors.white.withValues(alpha: 0.022),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Primary call to action with a violet → magenta gradient and loading state.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 56,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final fill = gradient ??
        const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[AppColors.primaryDeep, Color(0xFFC026D3)],
        );

    return AnimatedOpacity(
      opacity: enabled || loading ? 1 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: fill,
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            if (enabled)
              BoxShadow(
                color: AppColors.primaryDeep.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: height,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const SizedBox(
                          key: ValueKey<String>('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          key: const ValueKey<String>('label'),
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (icon != null) ...<Widget>[
                              Icon(icon, size: 20, color: Colors.white),
                              const SizedBox(width: 9),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AuthMessageTone { error, info, success }

/// Animated inline message used for server errors, hints and success notes.
class AuthMessageBanner extends StatelessWidget {
  const AuthMessageBanner({
    super.key,
    this.message,
    this.tone = AuthMessageTone.error,
  });

  final String? message;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null && message!.trim().isNotEmpty;
    final color = switch (tone) {
      AuthMessageTone.error => AppColors.danger,
      AuthMessageTone.info => AppColors.accent,
      AuthMessageTone.success => AppColors.mint,
    };
    final icon = switch (tone) {
      AuthMessageTone.error => Icons.error_outline_rounded,
      AuthMessageTone.info => Icons.info_outline_rounded,
      AuthMessageTone.success => Icons.check_circle_outline_rounded,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          alignment: AlignmentDirectional.topCenter,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: hasMessage
          ? Padding(
              key: ValueKey<String>('$tone:${message!}'),
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message!,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                          color: color.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(
              key: ValueKey<String>('empty'),
              width: double.infinity,
            ),
    );
  }
}

/// Themed form field with a leading icon, built on the app's
/// [InputDecorationTheme]. Email/username/password fields are forced LTR.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.enabled = true,
    this.obscureText = false,
    this.textDirection,
    this.textAlign,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final bool obscureText;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autofillHints: autofillHints,
      obscureText: obscureText,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      textDirection: textDirection,
      textAlign: textAlign ?? TextAlign.start,
      maxLength: maxLength,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      style: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: maxLength == null ? null : '',
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        suffixIcon: suffix,
      ),
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
    );
  }
}

/// Password field with a built-in visibility toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      suffix: IconButton(
        tooltip: _obscure ? 'نمایش رمز عبور' : 'پنهان کردن رمز عبور',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 20,
        ),
      ),
    );
  }
}

/// Three-segment password strength meter with a friendly Persian hint.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    final color = switch (strength) {
      1 => AppColors.danger,
      2 => AppColors.warning,
      3 => AppColors.mint,
      _ => AppColors.outline,
    };
    final hint = switch (strength) {
      1 => 'ضعیف — حرف و عدد را با هم ترکیب کنید',
      2 => 'متوسط — یک نماد مثل ! یا @ اضافه کنید',
      3 => 'قوی — این رمز عبور مطمئن است',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: List<Widget>.generate(3, (int index) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 5,
                margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index < strength
                      ? color
                      : Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: password.isEmpty
              ? const SizedBox(key: ValueKey<String>('empty'))
              : Padding(
                  key: ValueKey<int>(strength),
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Page heading used by every auth step.
class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.kicker,
    this.centered = false,
  });

  final String title;
  final String subtitle;
  final String? kicker;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        if (kicker != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[AppColors.accent, AppColors.primary],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  kicker!,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.35,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

/// Small glass chip used for email addresses, hints and illustration labels.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: 12,
        end: trailing == null ? 14 : 6,
        top: 9,
        bottom: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: color ?? AppColors.accent),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Centered scrollable body for an auth step, with keyboard padding so the
/// focused field is never trapped under the soft keyboard.
class AuthStepBody extends StatelessWidget {
  const AuthStepBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(22, 4, 22, 28),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding.add(EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// "یا" separator between the primary and alternative auth actions.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'یا'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        ),
      ],
    );
  }
}

/// Animated success panel used after verification / password reset.
class AuthSuccessView extends StatelessWidget {
  const AuthSuccessView({
    super.key,
    required this.title,
    this.message,
    this.action,
  });

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (BuildContext context, double value, Widget? child) {
            final t = value.clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.72 + 0.28 * t,
                child: child,
              ),
            );
          },
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.mint, AppColors.accent],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: Color(0xFF06231B),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        if (message != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.8,
            ),
          ),
        ],
        if (action != null) ...<Widget>[
          const SizedBox(height: 28),
          action!,
        ],
      ],
    );
  }
}

/// Continuously animated equalizer bars (no audio dependency).
class SoundWaveBars extends StatefulWidget {
  const SoundWaveBars({
    super.key,
    this.barCount = 5,
    this.height = 40,
    this.barWidth = 4.5,
    this.spacing = 5,
    this.color = AppColors.accent,
    this.active = true,
  });

  final int barCount;
  final double height;
  final double barWidth;
  final double spacing;
  final Color color;
  final bool active;

  @override
  State<SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<SoundWaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SoundWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List<Widget>.generate(widget.barCount, (int index) {
            final phase = index / widget.barCount;
            final wave =
                0.5 + 0.5 * math.sin(2 * math.pi * (_controller.value + phase));
            final factor = widget.active
                ? 0.26 + 0.74 * wave
                : 0.32 + 0.16 * (index % 3);
            return Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == widget.barCount - 1 ? 0 : widget.spacing,
              ),
              child: Container(
                width: widget.barWidth,
                height: widget.height * factor,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Gently floats its child up and down; used by onboarding illustrations.
class GentleFloat extends StatefulWidget {
  const GentleFloat({
    super.key,
    required this.child,
    this.distance = 7,
    this.duration = const Duration(milliseconds: 3200),
    this.phase = 0,
  });

  final Widget child;
  final double distance;
  final Duration duration;

  /// Starting point in the float cycle (0..1) so several widgets can bob
  /// out of sync without scheduling timers.
  final double phase;

  @override
  State<GentleFloat> createState() => _GentleFloatState();
}

class _GentleFloatState extends State<GentleFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.phase % 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final wave = math.sin(_controller.value * math.pi);
        return Transform.translate(
          offset: Offset(0, -widget.distance * wave),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
