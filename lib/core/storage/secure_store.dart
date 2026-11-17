import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, in-memory-cached access to credentials.
///
/// Access and refresh tokens are only ever written to the platform keystore
/// (Android Keystore-backed EncryptedSharedPreferences), never to plain
/// SharedPreferences.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'soundify_access_token';
  static const _refreshKey = 'soundify_refresh_token';
  static const _biometricKey = 'soundify_biometric_enabled';

  final FlutterSecureStorage _storage;

  String? _accessCache;
  String? _refreshCache;

  Future<String?> get accessToken async {
    if (_accessCache != null && _accessCache!.isNotEmpty) return _accessCache;
    _accessCache = await _storage.read(key: _accessKey);
    return _accessCache;
  }

  Future<String?> get refreshToken async {
    if (_refreshCache != null && _refreshCache!.isNotEmpty) return _refreshCache;
    _refreshCache = await _storage.read(key: _refreshKey);
    return _refreshCache;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessCache = accessToken;
    _refreshCache = refreshToken;
    await Future.wait(<Future<void>>[
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    _accessCache = null;
    _refreshCache = null;
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }

  Future<bool> get biometricEnabled async =>
      (await _storage.read(key: _biometricKey)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricKey, value: enabled ? 'true' : 'false');

  Future<bool> get hasSession async {
    final access = await accessToken;
    final refresh = await refreshToken;
    return (access?.isNotEmpty ?? false) && (refresh?.isNotEmpty ?? false);
  }
}
