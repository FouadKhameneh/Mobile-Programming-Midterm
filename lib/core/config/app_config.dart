/// Global, compile-time configuration for the Soundify app.
abstract final class AppConfig {
  static const String appName = 'Soundify';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://soundify.easyfound.ir/api/v1';
  static const String apiHost = 'https://soundify.easyfound.ir';
  static const String docsUrl = 'https://soundify.easyfound.ir/docs';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 35);
  static const Duration searchDebounce = Duration(milliseconds: 420);
  static const int otpResendSeconds = 60;

  static const String notificationChannelId = 'ir.soundify.playback';
  static const String notificationChannelName = 'Soundify playback';
}
