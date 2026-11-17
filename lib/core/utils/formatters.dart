import 'package:intl/intl.dart';

const _faDigits = <String>['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

String toPersianDigits(Object? value) {
  final text = '$value';
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code >= 48 && code <= 57) {
      buffer.write(_faDigits[code - 48]);
    } else {
      buffer.write(text[i]);
    }
  }
  return buffer.toString();
}

String formatDuration(Duration duration) {
  final total = duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) return toPersianDigits('$hours:$mm:$ss');
  return toPersianDigits('$mm:$ss');
}

String formatCount(int value) {
  if (value >= 1000000) {
    return '${toPersianDigits((value / 1000000).toStringAsFixed(1).replaceAll('.0', ''))} میلیون';
  }
  if (value >= 1000) {
    return '${toPersianDigits((value / 1000).toStringAsFixed(1).replaceAll('.0', ''))} هزار';
  }
  return toPersianDigits(value);
}

String greetingForHour(int hour) {
  if (hour < 5) return 'شب بخیر';
  if (hour < 12) return 'صبح بخیر';
  if (hour < 17) return 'ظهر بخیر';
  if (hour < 20) return 'عصر بخیر';
  return 'شب بخیر';
}

String relativeDate(DateTime? date) {
  if (date == null) return '';
  try {
    final j = DateFormat.yMMMMd('fa').format(date.toLocal());
    return toPersianDigits(j);
  } catch (_) {
    return toPersianDigits(DateFormat('yyyy/MM/dd').format(date.toLocal()));
  }
}

String pluralTracks(int count) {
  if (count == 0) return 'بدون آهنگ';
  return '${toPersianDigits(count)} آهنگ';
}

String pluralPlaylists(int count) {
  if (count == 0) return 'بدون پلی‌لیست';
  return '${toPersianDigits(count)} پلی‌لیست';
}
