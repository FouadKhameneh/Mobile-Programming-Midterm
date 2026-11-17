import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import 'widgets/brand_ui.dart';

/// The steps hosted by [AuthFlowScreen].
enum AuthFlowStep { login, register, otp, forgot }

/// Single entry point for the whole authentication experience.
///
/// `AppRoot` only needs to render `const AuthFlowScreen()`: successful logins
/// are observed through `AuthProvider.status` by the root widget, while email
/// verification (which does not create a session) is handled internally by
/// returning to the login step.
class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    this.initialStep = AuthFlowStep.login,
    this.initialEmail,
  });

  final AuthFlowStep initialStep;
  final String? initialEmail;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  late AuthFlowStep _step = widget.initialStep;
  late String _email = widget.initialEmail?.trim() ?? '';
  AuthFlowStep _otpOrigin = AuthFlowStep.login;
  OtpPurpose _otpPurpose = OtpPurpose.verifyEmail;
  bool _otpAutoRequest = false;
  int? _otpResendAfter;
  String? _otpNotice;
  AuthMessageTone _otpNoticeTone = AuthMessageTone.success;
  String? _notice;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    if (_step == AuthFlowStep.otp) {
      _otpOrigin = AuthFlowStep.login;
      _otpAutoRequest = false;
    }
  }

  void _openRegister(String email) {
    setState(() {
      _email = email;
      _forward = true;
      _step = AuthFlowStep.register;
      _notice = null;
    });
  }

  void _openForgot(String email) {
    setState(() {
      _email = email;
      _forward = true;
      _step = AuthFlowStep.forgot;
      _notice = null;
    });
  }

  void _openOtp({
    required String email,
    required AuthFlowStep origin,
    required OtpPurpose purpose,
    bool autoRequest = false,
    int? resendAfter,
    String? notice,
    AuthMessageTone noticeTone = AuthMessageTone.success,
  }) {
    setState(() {
      _email = email;
      _forward = true;
      _step = AuthFlowStep.otp;
      _otpOrigin = origin;
      _otpPurpose = purpose;
      _otpAutoRequest = autoRequest;
      _otpResendAfter = resendAfter;
      _otpNotice = notice;
      _otpNoticeTone = noticeTone;
      _notice = null;
    });
  }

  void _backToLogin({String? email, String? notice}) {
    setState(() {
      if (email != null && email.trim().isNotEmpty) _email = email.trim();
      _forward = false;
      _step = AuthFlowStep.login;
      _notice = notice;
      _otpAutoRequest = false;
      _otpResendAfter = null;
      _otpNotice = null;
    });
  }

  void _handleBack() {
    switch (_step) {
      case AuthFlowStep.login:
        break;
      case AuthFlowStep.register:
      case AuthFlowStep.forgot:
        _backToLogin(email: _email);
      case AuthFlowStep.otp:
        setState(() {
          _forward = false;
          _step = _otpOrigin;
          _otpAutoRequest = false;
          _otpResendAfter = null;
          _otpNotice = null;
        });
    }
  }

  String? get _topBarTitle => switch (_step) {
        AuthFlowStep.login => null,
        AuthFlowStep.register => 'ساخت حساب',
        AuthFlowStep.forgot => 'بازیابی رمز عبور',
        AuthFlowStep.otp =>
          _otpPurpose == OtpPurpose.passwordlessLogin ? 'ورود با کد' : 'تأیید ایمیل',
      };

  Widget _buildStep() {
    switch (_step) {
      case AuthFlowStep.login:
        return LoginScreen(
          initialEmail: _email.isEmpty ? null : _email,
          notice: _notice,
          onRegister: _openRegister,
          onForgotPassword: _openForgot,
          onOtpLogin: (String email) => _openOtp(
            email: email.isEmpty ? _email : email,
            origin: AuthFlowStep.login,
            purpose: OtpPurpose.passwordlessLogin,
            autoRequest: true,
          ),
          onUnverifiedEmail: (String email) => _openOtp(
            email: email,
            origin: AuthFlowStep.login,
            purpose: OtpPurpose.verifyEmail,
            autoRequest: true,
            notice:
                'برای ادامه باید ایمیلت را تأیید کنی؛ کد تأیید را برایت ارسال کردیم.',
            noticeTone: AuthMessageTone.info,
          ),
        );
      case AuthFlowStep.register:
        return RegisterScreen(
          initialEmail: _email.isEmpty ? null : _email,
          onRegistered: (String email, int? resendAfter, String? sendError) {
            _openOtp(
              email: email,
              origin: AuthFlowStep.register,
              purpose: OtpPurpose.verifyEmail,
              resendAfter: resendAfter,
              notice: sendError ?? 'کد تأیید به ایمیلت ارسال شد.',
              noticeTone:
                  sendError == null ? AuthMessageTone.success : AuthMessageTone.info,
            );
          },
          onBackToLogin: (String email) => _backToLogin(email: email),
        );
      case AuthFlowStep.otp:
        return OtpScreen(
          email: _email,
          purpose: _otpPurpose,
          autoRequest: _otpAutoRequest,
          secondsRemaining: _otpResendAfter,
          notice: _otpNotice,
          noticeTone: _otpNoticeTone,
          onBack: _handleBack,
          onVerified: () => _backToLogin(
            email: _email,
            notice: 'ایمیلت با موفقیت تأیید شد. اکنون وارد شو.',
          ),
        );
      case AuthFlowStep.forgot:
        return ForgotPasswordScreen(
          initialEmail: _email.isEmpty ? null : _email,
          onCancel: (String email) => _backToLogin(email: email),
          onCompleted: () => _backToLogin(
            email: _email,
            notice: 'رمز عبور با موفقیت تغییر کرد. با رمز جدید وارد شو.',
          ),
        );
    }
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final begin = Offset(_forward ? -0.07 : 0.07, 0.0);
    final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(curved);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == AuthFlowStep.login,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _handleBack();
      },
      child: Theme(
        data: soundifyBrandTheme,
        child: Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: false,
          body: BrandBackdrop(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  _FlowTopBar(
                    showBack: _step != AuthFlowStep.login,
                    title: _topBarTitle,
                    onBack: _handleBack,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: _buildTransition,
                      layoutBuilder:
                          (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<AuthFlowStep>(_step),
                        child: _buildStep(),
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
}

class _FlowTopBar extends StatelessWidget {
  const _FlowTopBar({
    required this.showBack,
    required this.onBack,
    this.title,
  });

  final bool showBack;
  final VoidCallback onBack;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            if (showBack)
              _RoundIconButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'بازگشت',
                onTap: onBack,
              )
            else
              const BrandMark(size: 40, glow: false),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: showBack
                    ? Align(
                        key: ValueKey<String?>('title-$title'),
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          title ?? '',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Column(
                        key: const ValueKey<String>('brand'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Soundify',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'موسیقی، بی‌وقفه',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (showBack) const BrandMark(size: 36, glow: false),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.white.withValues(alpha: 0.055),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: 21, color: AppColors.textPrimary),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
