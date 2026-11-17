import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/preferences_service.dart';
import '../models/track.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({required ApiClient api, required PreferencesService prefs})
      : _api = api,
        _prefs = prefs,
        _recent = List<String>.from(prefs.recentSearches);

  final ApiClient _api;
  final PreferencesService _prefs;

  Timer? _debounce;
  CancelToken? _cancelToken;
  int _requestId = 0;

  String _query = '';
  List<Track> _results = const <Track>[];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  List<String> _recent;

  String get query => _query;
  List<Track> get results => _results;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasSearched => _hasSearched;
  List<String> get recentSearches => List<String>.unmodifiable(_recent);

  void search(String value) {
    _query = value.trim();
    _debounce?.cancel();
    if (_query.isEmpty) {
      _cancelToken?.cancel();
      _results = const <Track>[];
      _hasSearched = false;
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _debounce = Timer(AppConfig.searchDebounce, () => _perform(_query));
    notifyListeners();
  }

  Future<void> submit(String value) {
    _query = value.trim();
    _debounce?.cancel();
    if (_query.isEmpty) return Future<void>.value();
    return _perform(_query, remember: true);
  }

  Future<void> _perform(String query, {bool remember = false}) async {
    final id = ++_requestId;
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;
    _loading = true;
    _error = null;
    _hasSearched = true;
    notifyListeners();
    try {
      final page = await _api.tracks(
        query: query,
        pageSize: 40,
        cancelToken: token,
      );
      if (id != _requestId) return;
      _results = page.items;
      if (remember || page.items.isNotEmpty) {
        await _remember(query);
      }
    } on ApiException catch (e) {
      if (id != _requestId || token.isCancelled) return;
      _error = e.message;
      _results = const <Track>[];
    } catch (_) {
      if (id != _requestId) return;
      _error = 'جست‌وجو انجام نشد. دوباره تلاش کنید.';
    } finally {
      if (id == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _remember(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    _recent.removeWhere((e) => e.toLowerCase() == value.toLowerCase());
    _recent.insert(0, value);
    if (_recent.length > 8) _recent = _recent.take(8).toList();
    await _prefs.setRecentSearches(_recent);
    notifyListeners();
  }

  Future<void> removeRecent(String value) async {
    _recent.remove(value);
    await _prefs.setRecentSearches(_recent);
    notifyListeners();
  }

  void clear() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    _query = '';
    _results = const <Track>[];
    _hasSearched = false;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}
