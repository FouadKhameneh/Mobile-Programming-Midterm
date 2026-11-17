import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class DeviceSecurityReport {
  const DeviceSecurityReport({
    required this.isEmulator,
    required this.isRooted,
    this.manufacturer,
    this.model,
    this.androidVersion,
    this.details = const <String>[],
  });

  final bool isEmulator;
  final bool isRooted;
  final String? manufacturer;
  final String? model;
  final String? androidVersion;
  final List<String> details;

  bool get isCompromised => isEmulator || isRooted;
}

class DeviceSecurityService {
  static const MethodChannel _channel =
      MethodChannel('ir.soundify/device_security');

  Future<DeviceSecurityReport> inspect() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const DeviceSecurityReport(isEmulator: false, isRooted: false);
    }
    final details = <String>[];
    var isEmulator = false;
    String? manufacturer;
    String? model;
    String? version;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      manufacturer = info.manufacturer;
      model = info.model;
      version = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
      isEmulator = !info.isPhysicalDevice ||
          info.model.toLowerCase().contains('sdk_gphone') ||
          info.brand.toLowerCase().contains('generic') ||
          info.hardware.toLowerCase().contains('goldfish') ||
          info.hardware.toLowerCase().contains('ranchu');
      if (isEmulator) details.add('محیط اجرا شبیه‌ساز تشخیص داده شد');
    } catch (_) {
      details.add('اطلاعات دستگاه در دسترس نیست');
    }

    var isRooted = false;
    try {
      final result = await _channel.invokeMethod<bool>('isRooted') ?? false;
      isRooted = result;
      if (isRooted) details.add('نشانه‌های روت در سیستم‌عامل پیدا شد');
    } on MissingPluginException {
      isRooted = false;
    } catch (_) {
      // The native check is best-effort; the UI still shows a useful state.
    }

    return DeviceSecurityReport(
      isEmulator: isEmulator,
      isRooted: isRooted,
      manufacturer: manufacturer,
      model: model,
      androidVersion: version,
      details: List<String>.unmodifiable(details),
    );
  }
}
