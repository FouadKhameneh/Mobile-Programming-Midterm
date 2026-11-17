/// Validation helpers with friendly Persian messages.
abstract final class Validators {
  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'ایمیل را وارد کنید.';
    if (!_email.hasMatch(text)) return 'ایمیل معتبر نیست.';
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'نام کاربری را وارد کنید.';
    if (text.length < 3) return 'نام کاربری باید حداقل ۳ کاراکتر باشد.';
    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(text)) {
      return 'فقط حروف انگلیسی، عدد، نقطه و زیرخط مجاز است.';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'رمز عبور را وارد کنید.';
    if (text.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد.';
    if (!RegExp(r'[A-Za-z]').hasMatch(text) ||
        !RegExp(r'[0-9]').hasMatch(text)) {
      return 'رمز عبور باید شامل حرف و عدد باشد.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'تکرار رمز عبور را وارد کنید.';
    if (value != password) return 'رمز عبور و تکرار آن یکسان نیستند.';
    return null;
  }

  static String? otpCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'کد تأیید را وارد کنید.';
    if (text.length != 6 || int.tryParse(text) == null) {
      return 'کد تأیید باید ۶ رقم باشد.';
    }
    return null;
  }

  static String? requiredName(String? value) {
    if (value == null || value.trim().isEmpty) return 'این فیلد الزامی است.';
    return null;
  }

  /// 0 = empty, 1 = weak, 2 = medium, 3 = strong
  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    if (value.length >= 12) score++;
    if (score <= 2) return 1;
    if (score <= 3) return 2;
    return 3;
  }
}
