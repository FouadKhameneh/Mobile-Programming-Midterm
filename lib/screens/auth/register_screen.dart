import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../state/auth_provider.dart';
import 'widgets/brand_ui.dart';

/// Signature used when registration succeeded and the flow should move on to
/// email verification. [resendAfter] seeds the OTP countdown and [sendError]
/// carries a non-fatal problem with the first verification-code request.
typedef OnRegistered = void Function(
  String email,
  int? resendAfter,
  String? sendError,
);

/// Registration step: creates the account, then requests the first email
/// verification code before handing over to the OTP step.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onRegistered,
    required this.onBackToLogin,
    this.initialEmail,
  });

  final OnRegistered onRegistered;
  final ValueChanged<String> onBackToLogin;
  final String? initialEmail;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final email = _emailController.text.trim();
    final displayName = _displayNameController.text.trim();
    final auth = context.read<AuthProvider>();
    setState(() => _submitting = true);

    try {
      await auth.register(
        email: email,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        displayName: displayName.isEmpty ? null : displayName,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'ثبت‌نام انجام نشد. اتصال اینترنت را بررسی و دوباره تلاش کنید.';
      });
      return;
    }

    // The account exists now; request the verification code. A failure here is
    // not fatal: the OTP screen lets the user retry the resend.
    int? resendAfter;
    String? sendError;
    try {
      final info = await auth.requestOtp(email);
      resendAfter = info.resendAfter ?? 60;
    } on ApiException catch (error) {
      sendError = error.message;
      if (error.isRateLimited) resendAfter = 60;
    } catch (_) {
      sendError = 'ارسال کد تأیید ناموفق بود. در صفحه بعد دوباره تلاش کنید.';
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onRegistered(email, resendAfter, sendError);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuthStepBody(
      children: <Widget>[
        const SizedBox(height: 6),
        const AuthPageHeader(
          kicker: 'عضویت',
          title: 'ساخت حساب',
          subtitle:
              'چند لحظه بیشتر تا شروع موسیقی فاصله نداری؛ اطلاعاتت را کامل کن.',
        ),
        const SizedBox(height: 26),
        AuthMessageBanner(message: _error),
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
                    autofillHints: const <String>[AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _usernameController,
                    label: 'نام کاربری',
                    hint: 'username',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    textDirection: TextDirection.ltr,
                    validator: Validators.username,
                    autofillHints: const <String>[AutofillHints.newUsername],
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _displayNameController,
                    label: 'نام نمایشی (اختیاری)',
                    hint: 'مثلاً: آریا',
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _passwordController,
                    label: 'رمز عبور',
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
                    label: 'تکرار رمز عبور',
                    textInputAction: TextInputAction.done,
                    validator: (String? value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: 'ثبت‌نام و دریافت کد تأیید',
                    icon: Icons.person_add_alt_1_rounded,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          children: <Widget>[
            Text(
              'قبلاً ثبت‌نام کرده‌ای؟',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () =>
                  widget.onBackToLogin(_emailController.text.trim()),
              child: const Text('وارد شو'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'با ثبت‌نام، شرایط استفاده و حریم خصوصی Soundify را می‌پذیرید.',
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
