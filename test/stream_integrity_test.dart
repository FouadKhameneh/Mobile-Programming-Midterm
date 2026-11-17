import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/utils/stream_integrity.dart';

void main() {
  test('detects a server-side wrong-file duration mismatch', () {
    // Example observed on the course API: Pink Floyd "Poles Apart" is declared
    // 424s but the served MP3 is Coldplay - Paradise (~260s).
    expect(
      StreamIntegrity.isMismatch(
        expected: const Duration(seconds: 424),
        actual: const Duration(seconds: 260),
      ),
      isTrue,
    );
  });

  test('accepts normal metadata rounding differences', () {
    expect(
      StreamIntegrity.isMismatch(
        expected: const Duration(seconds: 279),
        actual: const Duration(seconds: 260),
      ),
      isFalse,
    );
    expect(
      StreamIntegrity.isMismatch(
        expected: const Duration(seconds: 238),
        actual: const Duration(seconds: 240),
      ),
      isFalse,
    );
  });

  test('ignores very short tracks where metadata is noisy', () {
    expect(
      StreamIntegrity.isMismatch(
        expected: const Duration(seconds: 15),
        actual: const Duration(seconds: 40),
      ),
      isFalse,
    );
  });

  test('uses an absolute tolerance for short tracks', () {
    expect(
      StreamIntegrity.isMismatch(
        expected: const Duration(seconds: 60),
        actual: const Duration(seconds: 100),
      ),
      isTrue,
    );
    expect(
      StreamIntegrity.isMismatch(
        expected: const Duration(seconds: 60),
        actual: const Duration(seconds: 80),
      ),
      isFalse,
    );
  });

  test('message names the track and both durations', () {
    final message = StreamIntegrity.describe(
      title: 'Poles Apart',
      artist: 'Pink Floyd',
      expected: const Duration(seconds: 424),
      actual: const Duration(seconds: 260),
    );
    expect(message, contains('Poles Apart'));
    expect(message, contains('Pink Floyd'));
    expect(message, contains('424s'));
    expect(message, contains('260s'));
  });
}
