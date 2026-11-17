import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// A six-box OTP input backed by a single hidden text field.
///
/// The flow is RTL, so the first typed digit appears in the right-most box.
/// Persian digits are rendered inside the boxes while the underlying controller
/// always stores plain ASCII digits for the API.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = false,
    this.onCompleted,
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _shake = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -9)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -9, end: 8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 8, end: -5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -5, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ],
  ).animate(_shakeController);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0);
    }
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focusNode.hasFocus;

    return AnimatedBuilder(
      animation: _shake,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(_shake.value, 0),
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.enabled) _focusNode.requestFocus();
        },
        child: Stack(
          children: <Widget>[
            Row(
              textDirection: TextDirection.rtl,
              spacing: 8,
              children: List<Widget>.generate(widget.length, (int index) {
                final char = index < text.length ? text[index] : '';
                final isFilled = char.isNotEmpty;
                final isActive = focused && index == text.length;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppColors.primaryDeep.withValues(alpha: 0.20)
                          : AppColors.surfaceHigh.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.danger.withValues(alpha: 0.75)
                            : isActive
                                ? AppColors.primary
                                : isFilled
                                    ? AppColors.primary.withValues(alpha: 0.45)
                                    : Colors.white.withValues(alpha: 0.09),
                        width: isActive || widget.hasError ? 1.6 : 1.1,
                      ),
                      boxShadow: <BoxShadow>[
                        if (isActive)
                          BoxShadow(
                            color: AppColors.primaryDeep.withValues(alpha: 0.35),
                            blurRadius: 18,
                          ),
                      ],
                    ),
                    child: Center(
                      child: isFilled
                          ? Text(
                              toPersianDigits(char),
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : isActive
                              ? Container(
                                  width: 2,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                )
                              : null,
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.02,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  cursorColor: Colors.transparent,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                    height: 1,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isCollapsed: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: (String value) {
                    setState(() {});
                    widget.onChanged?.call(value);
                    if (value.length == widget.length) {
                      widget.onCompleted?.call(value);
                    }
                  },
                  onSubmitted: (String value) {
                    if (value.length == widget.length) {
                      widget.onCompleted?.call(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
