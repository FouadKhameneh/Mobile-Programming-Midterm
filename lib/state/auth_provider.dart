import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/preferences_service.dart';
import '../core/storage/secure_store.dart';
import '../models/auth_models.dart';
import '../models/user.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient api,
    required SecureStore secureStore,
    required PreferencesService prefs,
    LocalAuthentication? localAuth,
  })  : _api = api,
        _secure = secureStore,
        _prefs = prefs,
        _localAuth = localAuth ?? LocalAuthentication();

  final ApiClient _api;
  final SecureStore _secure;
  final PreferencesService _prefs;
  final LocalAuthentication _localAuth;

  AuthStatus _status = AuthStatus.initializing;
  User? _user;
  String? _error;
  bool _busy = false;
  bool _biometricEnabled = false;
  bool _biometricLocked = false;
  bool _biometricAvailable = false;
  String _lastEmail = '';

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get busy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitializing => _status == AuthStatus.initializing;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricLocked => _biometricLocked;
  bool get biometricAvailable => _biometricAvailable;
  String get lastEmail =>
      _lastEmail.isNotEmpty ? _lastEmail : (_prefs.lastEmail ?? '');

  Future<void> initialize() async {
    _status = AuthStatus.initializing;
    _error = null;
    notifyListeners();
    try {
      final hasSession = await _secure.hasSession;
      if (!hasSession) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      final user = await _api.me();
      _user = user;
      _status = AuthStatus.authenticated;
      _lastEmail = user.email;
      _biometricEnabled = await _secure.biometricEnabled;
      if (_biometricEnabled) {
        _biometricAvailable = await _checkBiometricAvailability();
        if (!_biometricAvailable) {
          _biometricEnabled = false;
          await _secure.setBiometricEnabled(false);
          _biometricLocked = false;
        } else {
          _biometricLocked = true;
        }
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _secure.clearTokens();
        _status = AuthStatus.unauthenticated;
      } else {
        // Keep the stored session around: a transient network failure should
        // not silently log the user out. The login screen offers a retry.
        _status = AuthStatus.unauthenticated;
        _error = e.message;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _error = 'راه‌اندازی نشست با خطا مواجه شد. دوباره تلاش کنید.';
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _runBusy(() async {
      final result = await _api.login(email: email, password: password);
      await _applyLogin(result);
      await _prefs.setLastEmail(_user?.email ?? email.trim());
    });
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    await _runBusy(() async {
      await _api.register(
        email: email,
        username: username,
        password: password,
        displayName: displayName,
      );
      _lastEmail = email.trim();
      await _prefs.setLastEmail(_lastEmail);
    });
  }

  Future<OtpRequestInfo> requestOtp(String email) async {
    final info = await _api.requestOtp(email);
    _lastEmail = email.trim();
    return info;
  }

  Future<OtpVerifyResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.verifyOtp(email: email, code: code);
      if (result.auth != null) {
        await _applyLogin(result.auth!);
        await _prefs.setLastEmail(_user?.email ?? email.trim());
      }
      return result;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<OtpRequestInfo> requestPasswordReset(String email) =>
      _api.requestPasswordReset(email);

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.confirmPasswordReset(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    _lastEmail = email.trim();
    await _prefs.setLastEmail(_lastEmail);
  }

  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    try {
      _user = await _api.me();
      notifyListeners();
    } catch (_) {
      // Non-fatal: cached profile stays visible.
    }
  }

  Future<void> _applyLogin(AuthResult result) async {
    await _secure.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    var user = result.user;
    if (user == null) {
      user = await _api.me();
    }
    _user = user;
    _status = AuthStatus.authenticated;
    _biometricLocked = false;
    _error = null;
    _biometricEnabled = await _secure.biometricEnabled;
    _biometricAvailable = await _checkBiometricAvailability();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _checkBiometricAvailability() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns `null` on success or a Persian explanation of why it failed.
  Future<String?> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final available = await _checkBiometricAvailability();
      _biometricAvailable = available;
      if (!available) {
        notifyListeners();
        return 'این دستگاه از ورود بیومتریک پشتیبانی نمی‌کند.';
      }
      try {
        final ok = await _localAuth.authenticate(
          localizedReason: 'برای فعال‌سازی ورود بیومتریک، هویت خود را تأیید کنید',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (!ok) {
          notifyListeners();
          return 'احراز هویت بیومتریک انجام نشد.';
        }
      } on LocalAuthException catch (e) {
        notifyListeners();
        return e.code == LocalAuthExceptionCode.noBiometricHardware
            ? 'سخت‌افزار بیومتریک در دسترس نیست.'
            : 'ورود بیومتریک ناموفق بود. دوباره تلاش کنید.';
      } catch (_) {
        return 'ورود بیومتریک در این دستگاه ممکن نیست.';
      }
      await _secure.setBiometricEnabled(true);
      _biometricEnabled = true;
      _biometricLocked = false;
      notifyListeners();
      return null;
    }
    await _secure.setBiometricEnabled(false);
    _biometricEnabled = false;
    _biometricLocked = false;
    notifyListeners();
    return null;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_biometricEnabled) {
      _biometricLocked = false;
      notifyListeners();
      return true;
    }
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'برای ورود به Soundify هویت خود را تأیید کنید',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        _biometricLocked = false;
        _error = null;
        notifyListeners();
        return true;
      }
      _error = 'احراز هویت بیومتریک انجام نشد.';
      notifyListeners();
      return false;
    } on LocalAuthException catch (e) {
      _error = e.code == LocalAuthExceptionCode.noBiometricHardware
          ? 'سخت‌افزار بیومتریک در دسترس نیست.'
          : 'ورود بیومتریک ناموفق بود.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'ورود بیومتریک انجام نشد.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _secure.clearTokens();
    await _secure.setBiometricEnabled(false);
    _biometricEnabled = false;
    _biometricLocked = false;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  /// Called by the network layer after the refresh token is rejected.
  void handleSessionExpired() {
    _secure.clearTokens();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _biometricEnabled = false;
    _biometricLocked = false;
    _error = 'نشست شما منقضی شد. دوباره وارد شوید.';
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }
}
