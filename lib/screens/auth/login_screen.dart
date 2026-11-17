import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../state/auth_provider.dart';
import 'widgets/brand_ui.dart';

/// Email + password sign-in step.
///
/// Successful logins are picked up by `AppRoot` through [AuthProvider.status];
/// this screen only reports the special "email is not verified yet" case so the
/// auth flow can jump to the OTP step.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onOtpLogin,
    required this.onUnverifiedEmail,
    this.initialEmail,
    this.notice,
  });

  final ValueChanged<String> onRegister;
  final ValueChanged<String> onForgotPassword;
  final ValueChanged<String> onOtpLogin;
  final ValueChanged<String> onUnverifiedEmail;
  final String? initialEmail;
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
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
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notice != null && widget.notice != oldWidget.notice) {
      _notice = widget.notice;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _notice = null;
    });
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final email = _emailController.text.trim();
    final auth = context.read<AuthProvider>();
    setState(() => _submitting = true);
    try {
      await auth.login(email: email, password: _passwordController.text);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (error is UnverifiedEmailException ||
          error.code == 'account_not_verified') {
        widget.onUnverifiedEmail(email);
        return;
      }
      setState(() => _error = error.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'ورود ناموفق بود. اتصال اینترنت را بررسی و دوباره تلاش کنید.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  void _handleOtpLogin() {
    final error = Validators.email(_emailController.text);
    if (error != null) {
      setState(() {
        _error = error;
        _notice = null;
      });
      return;
    }
    setState(() => _error = null);
    widget.onOtpLogin(_emailController.text.trim());
  }

  void _handleForgotPassword() {
    setState(() => _error = null);
    widget.onForgotPassword(_emailController.text.trim());
  }

  void _handleRegister() {
    setState(() => _error = null);
    widget.onRegister(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuthStepBody(
      children: <Widget>[
        const SizedBox(height: 6),
        const AuthPageHeader(
          kicker: 'حساب کاربری',
          title: 'خوش برگشتی',
          subtitle: 'برای ادامه، با ایمیل و رمز عبور وارد حساب Soundify خود شو.',
        ),
        const SizedBox(height: 26),
        AuthMessageBanner(
          message: _error ?? _notice,
          tone: _error != null
              ? AuthMessageTone.error
              : AuthMessageTone.info,
        ),
        GlassCard(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AuthTextField(
                    controller: _emailController,
                    label: 'ایمیل',
                    hint: 'name@example.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textDirection: TextDirection.ltr,
                    validator: Validators.email,
                    autofillHints: const <String>[
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                  ),
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _passwordController,
                    label: 'رمز عبور',
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    autofillHints: const <String>[AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('رمز عبور را فراموش کرده‌اید؟'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: 'ورود',
                    icon: Icons.login_rounded,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const OrDivider(),
        const SizedBox(height: 18),
        _GlassActionButton(
          label: 'ورود با کد یکبارمصرف',
          icon: Icons.password_rounded,
          onPressed: _handleOtpLogin,
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          children: <Widget>[
            Text(
              'حساب نداری؟',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: _handleRegister,
              child: const Text('ثبت‌نام کن'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'با ورود یا ثبت‌نام، شرایط استفاده و حریم خصوصی Soundify را می‌پذیرید.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: AppColors.accent),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
