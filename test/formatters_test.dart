import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/utils/formatters.dart';

void main() {
  group('toPersianDigits', () {
    test('converts ASCII digits and keeps other characters', () {
      expect(toPersianDigits('Track 12:34'), 'Track ۱۲:۳۴');
      expect(toPersianDigits(2026), '۲۰۲۶');
    });
  });

  group('formatDuration', () {
    test('formats under an hour', () {
      expect(formatDuration(const Duration(seconds: 65)), '۰۱:۰۵');
      expect(formatDuration(Duration.zero), '۰۰:۰۰');
    });

    test('formats hours when needed', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
          '۱:۰۲:۰۳');
    });
  });

  group('formatCount', () {
    test('uses Persian thousands and millions labels', () {
      expect(formatCount(950), '۹۵۰');
      expect(formatCount(1500), '۱.۵ هزار');
      expect(formatCount(2500000), '۲.۵ میلیون');
    });
  });

  group('plural helpers', () {
    test('uses Persian copy for track counts', () {
      expect(pluralTracks(0), 'بدون آهنگ');
      expect(pluralTracks(3), '۳ آهنگ');
    });
  });

  group('greetingForHour', () {
    test('changes across the day', () {
      expect(greetingForHour(8), 'صبح بخیر');
      expect(greetingForHour(13), 'ظهر بخیر');
      expect(greetingForHour(18), 'عصر بخیر');
      expect(greetingForHour(23), 'شب بخیر');
    });
  });
}
