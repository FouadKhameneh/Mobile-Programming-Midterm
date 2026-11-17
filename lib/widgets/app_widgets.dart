import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/app_colors.dart';

/// Rounded, glassy container used across the app.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ??
            (isDark
                ? AppColors.glassGradient
                : const LinearGradient(
                    colors: <Color>[Colors.white, Color(0xFFF4F1FB)],
                  )),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFE6E1F2)),
        ),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Primary call-to-action with the Soundify gradient and a built-in loader.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 54,
    this.expand = true,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;
  final bool expand;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.65,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.brandGradient,
          borderRadius: BorderRadius.circular(17),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: enabled ? onPressed : null,
        child: content,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Text field matching the app's visual language.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.maxLines = 1,
    this.textDirection,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final TextDirection? textDirection;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      maxLines: maxLines,
      textDirection: textDirection,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      style: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.add(const EdgeInsets.symmetric(vertical: 10)),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : scheme.outline.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.music_off_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDeep.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.7,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'اتصال برقرار نشد',
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 10,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + value * 2, 0),
              end: Alignment(1 + value * 2, 0),
              colors: <Color>[
                base.withValues(alpha: 0.65),
                base.withValues(alpha: 0.25),
                base.withValues(alpha: 0.65),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Row(
        children: <Widget>[
          const ShimmerBox(width: 56, height: 56, borderRadius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(
                  width: 150 + math.Random().nextInt(80).toDouble(),
                  height: 13,
                ),
                const SizedBox(height: 8),
                const ShimmerBox(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: error ? AppColors.danger : AppColors.mint,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(message)),
          ],
        ),
        action: action,
      ),
    );
}
