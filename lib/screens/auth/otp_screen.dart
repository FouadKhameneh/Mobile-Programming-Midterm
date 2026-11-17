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

/// Why the user is looking at an OTP screen.
enum OtpPurpose {
  /// Confirm ownership of the email after registration (or after a login that
  /// failed because the email was never verified).
  verifyEmail,

  /// Passwordless sign-in with a one-time code.
  passwordlessLogin,
}

/// Six-digit email verification step with resend countdown.
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.email,
    required this.purpose,
    required this.onBack,
    required this.onVerified,
    this.autoRequest = false,
    this.secondsRemaining,
    this.notice,
    this.noticeTone = AuthMessageTone.success,
  });

  final String email;
  final OtpPurpose purpose;
  final VoidCallback onBack;

  /// Called when the code was accepted but no session was created (the
  /// "email verified" case). When verification signs the user in, `AppRoot`
  /// switches screens automatically and this is not called.
  final VoidCallback onVerified;

  /// When true the screen requests the first code itself.
  final bool autoRequest;

  /// Seeds the resend countdown (e.g. from a previous OTP request).
  final int? secondsRemaining;

  /// Optional non-error note shown on arrival.
  final String? notice;

  /// Tone used for [notice]; a failed first send is surfaced as information.
  final AuthMessageTone noticeTone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();

  Timer? _timer;
  int _seconds = 0;
  bool _sending = false;
  bool _verifying = false;
  bool _verified = false;
  String? _error;
  String? _notice;
  late AuthMessageTone _noticeTone = widget.noticeTone;

  bool get _isVerifying => _verifying;
  bool get _isLogin => widget.purpose == OtpPurpose.passwordlessLogin;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    final seconds = widget.secondsRemaining;
    if (seconds != null && seconds > 0) {
      _seconds = seconds;
      _armTimer();
    }
    if (widget.autoRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendCode();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
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

  Future<void> _sendCode() async {
    if (_sending || _verifying) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final info = await auth.requestOtp(widget.email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _notice = info.message;
        _noticeTone = AuthMessageTone.success;
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
        _error = 'ارسال کد تأیید ناموفق بود. دوباره تلاش کنید.';
      });
    }
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _codeController.text.trim();
    final codeError = Validators.otpCode(code);
    if (codeError != null) {
      setState(() => _error = codeError);
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final result = await auth.verifyOtp(email: widget.email, code: code);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _verified = true;
      });
      if (result.auth == null) {
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (mounted) widget.onVerified();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = error.message;
      });
      _codeController.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'تأیید کد انجام نشد. دوباره تلاش کنید.';
      });
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verified) {
      return AuthStepBody(
        children: <Widget>[
          const SizedBox(height: 54),
          AuthSuccessView(
            title: _isLogin ? 'ورود موفق' : 'ایمیل تأیید شد',
            message: _isLogin
                ? 'در حال باز کردن حساب Soundify…'
                : 'حساب تو فعال شد. اکنون می‌توانی وارد شوی.',
          ),
        ],
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final message = _error ?? _notice;
    final bannerTone = _error != null ? AuthMessageTone.error : _noticeTone;

    return AuthStepBody(
      children: <Widget>[
        const SizedBox(height: 6),
        AuthPageHeader(
          kicker: 'تأیید هویت',
          title: _isLogin ? 'ورود با کد یکبارمصرف' : 'تأیید ایمیل',
          subtitle: _isLogin
              ? 'کد ۶ رقمی ارسال‌شده به ایمیل زیر را وارد کن تا وارد حساب شوی.'
              : 'کد ۶ رقمی ارسال‌شده به ایمیل زیر را وارد کن تا حسابت فعال شود.',
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GlassPill(
            icon: Icons.alternate_email_rounded,
            label: widget.email,
            trailing: TextButton(
              onPressed: _isVerifying ? null : widget.onBack,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'تغییر',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AuthMessageBanner(message: message, tone: bannerTone),
        OtpCodeField(
          controller: _codeController,
          autofocus: true,
          enabled: !_isVerifying,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        const SizedBox(height: 26),
        GradientButton(
          label: 'تأیید و ادامه',
          icon: Icons.verified_rounded,
          loading: _isVerifying,
          onPressed: _verify,
        ),
        const SizedBox(height: 20),
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
                  key: const ValueKey<String>('resend'),
                  onPressed: _sending ? null : _sendCode,
                  icon: _sending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('ارسال دوباره کد'),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'اگر کد را دریافت نکردی، پوشه اسپم یا هرزنامه را هم بررسی کن.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isVerifying ? null : widget.onBack,
          child: const Text('بازگشت'),
        ),
      ],
    );
  }
}
