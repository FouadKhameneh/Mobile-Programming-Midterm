import 'dart:async';

import 'package:dio/dio.dart';

import '../../models/auth_models.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../models/user.dart';
import '../config/app_config.dart';
import '../storage/secure_store.dart';
import '../utils/json_utils.dart';
import 'api_exception.dart';

/// Centralized Dio client with secure token injection and transparent
/// refresh-token rotation. A failed refresh notifies the auth layer once.
class ApiClient {
  ApiClient({required SecureStore secureStore}) : _secureStore = secureStore {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.connectTimeout,
        headers: <String, dynamic>{'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: <String, dynamic>{'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isAuthEndpoint(options.path)) {
            final token = await _secureStore.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final status = error.response?.statusCode;
          final alreadyRetried = request.extra['soundify_retried'] == true;
          final canRefresh = status == 401 &&
              !alreadyRetried &&
              !_isAuthEndpoint(request.path) &&
              await _secureStore.hasSession;
          if (!canRefresh) {
            handler.next(error);
            return;
          }
          final refreshed = await _refreshTokens();
          if (!refreshed) {
            handler.next(error);
            return;
          }
          try {
            final token = await _secureStore.accessToken;
            request.extra['soundify_retried'] = true;
            request.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch<dynamic>(request);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  final SecureStore _secureStore;
  late final Dio _dio;
  late final Dio _refreshDio;
  Future<bool>? _refreshInFlight;

  /// Set by the app wiring to switch the UI back to the login flow.
  void Function()? onSessionExpired;

  bool _isAuthEndpoint(String path) {
    if (path.contains('/auth/token/refresh')) return false;
    return path.contains('/auth/');
  }

  Future<bool> _refreshTokens() {
    final running = _refreshInFlight;
    if (running != null) return running;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refresh = await _secureStore.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      await _expireSession();
      return false;
    }
    try {
      final response = await _refreshDio.post<dynamic>(
        '/auth/token/refresh/',
        data: <String, dynamic>{'refresh': refresh},
      );
      final pair = parseTokenPair(response.data);
      if (pair == null) {
        await _expireSession();
        return false;
      }
      await _secureStore.saveTokens(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
      );
      return true;
    } on DioException {
      await _expireSession();
      return false;
    }
  }

  Future<void> _expireSession() async {
    await _secureStore.clearTokens();
    onSessionExpired?.call();
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      _request(
        () => _dio.get<dynamic>(
          path,
          queryParameters: query,
          cancelToken: cancelToken,
        ),
      );

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) =>
      _request(() => _dio.post<dynamic>(path, data: data, queryParameters: query));

  Future<Response<dynamic>> patch(String path, {Object? data}) =>
      _request(() => _dio.patch<dynamic>(path, data: data));

  Future<Response<dynamic>> delete(String path) =>
      _request(() => _dio.delete<dynamic>(path));

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  // ---- Auth ---------------------------------------------------------------

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      '/auth/login/',
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
    final pair = parseTokenPair(response.data);
    if (pair == null) {
      throw ApiException(
        message: 'پاسخ سرور برای ورود نامعتبر بود. دوباره تلاش کنید.',
        code: 'invalid_response',
      );
    }
    return AuthResult(tokens: pair, user: parseUser(response.data));
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    await post(
      '/auth/register/',
      data: <String, dynamic>{
        'email': email.trim(),
        'username': username.trim(),
        'password': password,
        if (displayName != null && displayName.trim().isNotEmpty)
          'display_name': displayName.trim(),
      },
    );
  }

  Future<OtpRequestInfo> requestOtp(String email) async {
    final response = await post(
      '/auth/otp/request/',
      data: <String, dynamic>{'email': email.trim()},
    );
    final map = asMap(response.data) ?? <String, dynamic>{};
    return OtpRequestInfo(
      message: map['message']?.toString() ?? 'کد تأیید ارسال شد.',
      expiresIn: _asInt(map['expires_in']),
      resendAfter: _asInt(map['resend_after']),
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await post(
      '/auth/otp/verify/',
      data: <String, dynamic>{
        'email': email.trim(),
        'code': code.trim(),
      },
    );
    final map = asMap(response.data) ?? <String, dynamic>{};
    final pair = parseTokenPair(response.data);
    final verified = map['verified'] == true || pair != null;
    return OtpVerifyResult(
      verified: verified,
      auth: pair == null
          ? null
          : AuthResult(tokens: pair, user: parseUser(response.data)),
      message: map['message']?.toString(),
    );
  }

  Future<OtpRequestInfo> requestPasswordReset(String email) async {
    final response = await post(
      '/auth/password/reset/request/',
      data: <String, dynamic>{'email': email.trim()},
    );
    final map = asMap(response.data) ?? <String, dynamic>{};
    return OtpRequestInfo(
      message: map['message']?.toString() ?? 'کد بازیابی ارسال شد.',
      expiresIn: _asInt(map['expires_in']),
      resendAfter: _asInt(map['resend_after']),
    );
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await post(
      '/auth/password/reset/confirm/',
      data: <String, dynamic>{
        'email': email.trim(),
        'code': code.trim(),
        'new_password': newPassword,
      },
    );
  }

  Future<User> me() async {
    final response = await get('/users/me/');
    final user = parseUser(response.data);
    if (user == null) {
      throw ApiException(
        message: 'اطلاعات کاربری دریافت نشد.',
        code: 'invalid_response',
      );
    }
    return user;
  }

  // ---- Catalog ------------------------------------------------------------

  Future<List<Track>> featuredTracks() async {
    final response = await get('/tracks/featured/');
    return parseTrackList(response.data);
  }

  Future<ApiPage<Track>> tracks({
    String? query,
    int page = 1,
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async {
    final response = await get(
      '/tracks/',
      query: <String, dynamic>{
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'page': page,
        'page_size': pageSize,
      },
      cancelToken: cancelToken,
    );
    final map = asMap(response.data);
    if (map == null || map['results'] is! List) {
      final tracks = parseTrackList(response.data);
      return ApiPage<Track>(items: tracks, count: tracks.length);
    }
    final items = parseTrackList(map);
    final count = _asInt(map['count']) ?? items.length;
    return ApiPage<Track>(
      items: items,
      count: count,
      next: map['next']?.toString(),
      previous: map['previous']?.toString(),
    );
  }

  // ---- Playlists ----------------------------------------------------------

  Future<ApiPage<Playlist>> playlists() async {
    final response = await get('/playlists/');
    final items = parsePlaylistList(response.data);
    return ApiPage<Playlist>(
      items: items,
      count: parseCount(response.data, fallback: items.length),
    );
  }

  Future<Playlist> playlist(String id) async {
    final response = await get('/playlists/$id/');
    final map = asMap(response.data);
    if (map == null) {
      throw ApiException(message: 'پلی‌لیست دریافت نشد.', code: 'invalid_response');
    }
    return Playlist.fromJson(map);
  }

  Future<Playlist> createPlaylist({
    required String name,
    String description = '',
    bool isPublic = false,
  }) async {
    final response = await post(
      '/playlists/',
      data: <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'is_public': isPublic,
      },
    );
    final map = asMap(response.data);
    if (map == null) {
      throw ApiException(message: 'پلی‌لیست ساخته نشد.', code: 'invalid_response');
    }
    // Some servers wrap the object.
    return Playlist.fromJson(asMap(map['playlist']) ?? map);
  }

  Future<Playlist> updatePlaylist({
    required String id,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final response = await patch(
      '/playlists/$id/',
      data: <String, dynamic>{
        if (name != null) 'name': name.trim(),
        if (description != null) 'description': description.trim(),
        if (isPublic != null) 'is_public': isPublic,
      },
    );
    final map = asMap(response.data);
    if (map == null) {
      throw ApiException(message: 'پلی‌لیست ویرایش نشد.', code: 'invalid_response');
    }
    return Playlist.fromJson(asMap(map['playlist']) ?? map);
  }

  Future<void> deletePlaylist(String id) => delete('/playlists/$id/');

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    await post(
      '/playlists/$playlistId/tracks/',
      data: <String, dynamic>{'track_id': trackId},
    );
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    await delete('/playlists/$playlistId/tracks/$trackId/');
  }

  // ---- Favorites ----------------------------------------------------------

  Future<List<Track>> favorites() async {
    final response = await get('/favorites/');
    return parseTrackList(response.data);
  }

  Future<void> addFavorite(String trackId) async {
    await post('/favorites/', data: <String, dynamic>{'track_id': trackId});
  }

  Future<void> removeFavorite(String trackId) async {
    await delete('/favorites/$trackId/');
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
