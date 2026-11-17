import 'package:flutter/foundation.dart';

/// Client-side guard against a broken API/data combination where the
/// `/tracks/:id/stream` endpoint returns a byte stream belonging to a different
/// track (this happens on the course server for some imported catalog entries).
///
/// The server exposes `duration` metadata for each track. Once the audio engine
/// has loaded the real stream, its duration is compared with that metadata. A
/// large mismatch is a strong signal that the wrong audio file is being served,
/// so playback is stopped rather than silently playing another artist's song.
abstract final class StreamIntegrity {
  static const double toleranceRatio = 0.25;
  static const Duration minimumComparable = Duration(seconds: 30);
  static const Duration minimumAbsoluteTolerance = Duration(seconds: 30);

  static const String mismatchMessage =
      'فایل صوتی این آهنگ با اطلاعات آن در سرور هم‌خوانی ندارد؛ به‌جای این آهنگ '
      'یک فایل دیگر سرو شده است (خطای دادهٔ سرور). پخش متوقف شد تا آهنگ اشتباه '
      'پخش نشود. لطفاً قطعهٔ دیگری انتخاب کنید یا با مدیر سرور تماس بگیرید.';

  /// Returns `true` when [actual] is so far from [expected] that the stream is
  /// almost certainly a different audio file.
  static bool isMismatch({
    required Duration expected,
    required Duration actual,
  }) {
    if (expected < minimumComparable || actual < minimumComparable) {
      return false;
    }
    final expectedMs = expected.inMilliseconds;
    final actualMs = actual.inMilliseconds;
    final ratioTolerance = (expectedMs * toleranceRatio).round();
    final tolerance = ratioTolerance > minimumAbsoluteTolerance.inMilliseconds
        ? ratioTolerance
        : minimumAbsoluteTolerance.inMilliseconds;
    return (actualMs - expectedMs).abs() > tolerance;
  }

  static String describe({
    required String title,
    required String artist,
    required Duration expected,
    required Duration actual,
  }) {
    final expectedText = '${expected.inSeconds}s';
    final actualText = '${actual.inSeconds}s';
    return '«$title» از $artist در سرور با مدت اعلام‌شدهٔ $expectedText ذخیره '
        'شده، اما فایل صوتی دریافتی $actualText است. این نشانهٔ سرو شدن فایل '
        'اشتباه توسط سرور است.';
  }
}
