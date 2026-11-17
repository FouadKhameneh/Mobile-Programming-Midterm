import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../state/auth_provider.dart';
import 'widgets/brand_ui.dart';
import 'widgets/otp_code_field.dart';

/// Two-step password recovery: request a code, then set a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onCancel,
    required this.onCompleted,
    this.initialEmail,
  });

  /// Returns to the login step, carrying the email typed so far.
  final ValueChanged<String> onCancel;

  /// Called after the password was reset successfully.
  final VoidCallback onCompleted;

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  Timer? _timer;
  int _step = 0;
  int _seconds = 0;
  bool _busy = false;
  bool _sending = false;
  bool _completed = false;
  String? _error;
  String? _notice;

  String get _email => _emailController.text.trim();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? _savedEmail();
  }

  String _savedEmail() {
    try {
      return context.read<AuthProvider>().lastEmail;
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    if (_seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_seconds <= 1) {
        timer.cancel();
        _timer = null;
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    _seconds = seconds > 0 ? seconds : 0;
    _armTimer();
    if (mounted) setState(() {});
  }

  Future<void> _requestCode() async {
    final form = _emailFormKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final info = await auth.requestPasswordReset(_email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = info.message;
        _step = 1;
      });
      _startCountdown(info.resendAfter ?? 60);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'ارسال کد بازیابی ناموفق بود. دوباره تلاش کنید.';
      });
    }
  }

  Future<void> _resendCode() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final info = await auth.requestPasswordReset(_email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _notice = info.message;
      });
      _startCountdown(info.resendAfter ?? 60);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
      if (error.isRateLimited) _startCountdown(60);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'ارسال دوباره کد ناموفق بود.';
      });
    }
  }

  Future<void> _confirmReset() async {
    if (_busy) return;
    setState(() => _error = null);
    final form = _resetFormKey.currentState;
    if (form == null || !form.validate()) return;
    final codeError = Validators.otpCode(_codeController.text);
    if (codeError != null) {
      setState(() => _error = codeError);
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() => _busy = true);
    try {
      await auth.confirmPasswordReset(
        email: _email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _completed = true;
        _error = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1700));
      if (mounted) widget.onCompleted();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
      _codeController.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'تغییر رمز عبور انجام نشد. دوباره تلاش کنید.';
      });
    }
  }

  void _backToEmailStep() {
    setState(() {
      _step = 0;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return AuthStepBody(
        children: <Widget>[
          const SizedBox(height: 54),
          AuthSuccessView(
            title: 'رمز عبور تغییر کرد',
            message: 'اکنون می‌توانی با رمز عبور جدید وارد حساب شوی.',
            action: GradientButton(
              label: 'بازگشت به ورود',
              icon: Icons.login_rounded,
              onPressed: widget.onCompleted,
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.05, 0.01),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _step == 0
          ? _buildEmailStep(context)
          : _buildResetStep(context),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuthStepBody(
      key: const ValueKey<String>('forgot-email'),
      children: <Widget>[
        const SizedBox(height: 6),
        const AuthPageHeader(
          kicker: 'بازیابی حساب',
          title: 'رمز عبور را فراموش کردی؟',
          subtitle:
              'ایمیل حساب خود را وارد کن تا کد بازیابی برایت ارسال شود. سپس می‌توانی رمز جدید تعیین کنی.',
        ),
        const SizedBox(height: 26),
        AuthMessageBanner(message: _error),
        GlassCard(
          child: Form(
            key: _emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AuthTextField(
                  controller: _emailController,
                  label: 'ایمیل',
                  hint: 'name@example.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _requestCode(),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'ارسال کد بازیابی',
                  icon: Icons.mark_email_read_outlined,
                  loading: _busy,
                  onPressed: _requestCode,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'کد بازیابی چند دقیقه اعتبار دارد؛ اگر دریافت نشد می‌توانی دوباره درخواست کنی.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => widget.onCancel(_email),
          child: const Text('بازگشت به ورود'),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildResetStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = _error ?? _notice;
    final bannerTone = _error != null
        ? AuthMessageTone.error
        : AuthMessageTone.success;

    return AuthStepBody(
      key: const ValueKey<String>('forgot-reset'),
      children: <Widget>[
        const SizedBox(height: 6),
        const AuthPageHeader(
          kicker: 'بازیابی حساب',
          title: 'تعیین رمز عبور جدید',
          subtitle:
              'کدی که به ایمیلت فرستادیم و رمز عبور جدیدت را وارد کن. رمز جدید باید حداقل ۸ کاراکتر و شامل حرف و عدد باشد.',
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GlassPill(
            icon: Icons.alternate_email_rounded,
            label: _email,
            trailing: TextButton(
              onPressed: _busy ? null : _backToEmailStep,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('تغییر', style: TextStyle(fontSize: 11.5)),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AuthMessageBanner(message: message, tone: bannerTone),
        GlassCard(
          child: Form(
            key: _resetFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                OtpCodeField(
                  controller: _codeController,
                  enabled: !_busy,
                  hasError: _error != null,
                ),
                const SizedBox(height: 22),
                PasswordField(
                  controller: _passwordController,
                  label: 'رمز عبور جدید',
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                PasswordStrengthMeter(password: _passwordController.text),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmController,
                  label: 'تکرار رمز عبور جدید',
                  textInputAction: TextInputAction.done,
                  validator: (String? value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _confirmReset(),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'ذخیره رمز عبور',
                  icon: Icons.lock_reset_rounded,
                  loading: _busy,
                  onPressed: _confirmReset,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _seconds > 0
              ? Text(
                  'ارسال دوباره کد تا ${toPersianDigits(_seconds)} ثانیه دیگر',
                  key: ValueKey<int>(_seconds),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.7,
                  ),
                )
              : TextButton.icon(
                  key: const ValueKey<String>('resend-reset'),
                  onPressed: _sending ? null : _resendCode,
                  icon: _sending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accent,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('ارسال دوباره کد'),
                ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy ? null : () => widget.onCancel(_email),
          child: const Text('بازگشت به ورود'),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
