import 'package:dio/dio.dart';

/// A user-facing API failure with a Persian message plus the server error code.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final dynamic details;

  bool get isNetworkError =>
      code == 'network_error' || code == 'timeout_error' || statusCode == null;

  bool get isUnauthorized => statusCode == 401;

  bool get isRateLimited => statusCode == 429 || code == 'rate_limited';

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? code;
    String? message;
    dynamic details;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final rawError = map['error'];
      if (rawError is Map) {
        final err = Map<String, dynamic>.from(rawError);
        code = err['code']?.toString();
        message = err['message']?.toString();
        details = err['details'];
      } else if (rawError is String) {
        message = rawError;
      }
      message ??= map['message']?.toString() ?? map['detail']?.toString();
      code ??= map['code']?.toString();
      // Some validation errors come back as field -> [messages].
      if (message == null && map.isNotEmpty) {
        final first = map.entries.first;
        final value = first.value;
        if (value is List && value.isNotEmpty) {
          message = value.first.toString();
        } else if (value is String) {
          message = value;
        }
        details = map;
      }
    }

    if (message == null || message.trim().isEmpty) {
      switch (status) {
        case 400:
          message = 'اطلاعات ارسال‌شده معتبر نیست.';
        case 401:
          message = 'نشست شما منقضی شده است. دوباره وارد شوید.';
        case 403:
          message = 'اجازه دسترسی به این بخش وجود ندارد.';
        case 404:
          message = 'موردی یافت نشد.';
        case 409:
          message = 'این مورد از قبل وجود دارد.';
        case 429:
          message = 'تعداد درخواست‌ها زیاد است. کمی بعد دوباره تلاش کنید.';
        case 500:
        case 502:
        case 503:
          message = 'سرور در دسترس نیست. دوباره تلاش کنید.';
        default:
          message = 'خطایی رخ داد. دوباره تلاش کنید.';
      }
    }

    if (status == null) {
      code ??= 'network_error';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        code = 'timeout_error';
        message = 'اتصال به سرور زمان‌بر شد. اتصال اینترنت را بررسی کنید.';
      } else {
        message = 'اتصال به سرور برقرار نشد. اتصال اینترنت را بررسی کنید.';
      }
    }

    return ApiException(
      message: localizeServerMessage(message, code),
      code: code,
      statusCode: status,
      details: details,
    );
  }

  /// Maps known API error codes/messages to polished Persian copy.
  static String localizeServerMessage(String message, String? code) {
    switch (code) {
      case 'account_not_verified':
        return 'ایمیل شما هنوز تأیید نشده است. کد تأیید را وارد کنید.';
      case 'invalid_credentials':
        return 'ایمیل یا رمز عبور اشتباه است.';
      case 'rate_limited':
        return 'کمی صبر کنید؛ ارسال دوباره کد هنوز مجاز نیست.';
      case 'invalid_code':
      case 'invalid_otp':
        return 'کد واردشده صحیح یا معتبر نیست.';
      case 'expired_code':
      case 'otp_expired':
        return 'کد منقضی شده است. کد جدید دریافت کنید.';
      case 'already_favorited':
        return 'این آهنگ از قبل در علاقه‌مندی‌هاست.';
      case 'email_exists':
      case 'already_exists':
        return 'ایمیل یا نام کاربری قبلاً ثبت شده است.';
      case 'weak_password':
        return 'رمز عبور باید حداقل ۸ کاراکتر باشد.';
      case 'invalid_json':
        return 'درخواست نامعتبر است. دوباره تلاش کنید.';
      case 'unauthorized':
      case 'token_expired':
        return 'نشست شما منقضی شده است. دوباره وارد شوید.';
    }
    // The backend's message may already be Persian; keep it then.
    if (message.trim().isEmpty) return 'خطایی رخ داد. دوباره تلاش کنید.';
    return message;
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

class UnverifiedEmailException extends ApiException {
  UnverifiedEmailException(this.email)
      : super(
          message: 'ایمیل شما هنوز تأیید نشده است. کد تأیید را وارد کنید.',
          code: 'account_not_verified',
          statusCode: 403,
        );

  final String email;
}
