import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'auth_provider.dart';

class LibraryProvider extends ChangeNotifier {
  LibraryProvider({required ApiClient api, required AuthProvider auth})
      : _api = api,
        _auth = auth {
    _lastSignedIn = _auth.isAuthenticated;
    _auth.addListener(_onAuthChanged);
    if (_lastSignedIn) loadLibrary();
  }

  final ApiClient _api;
  final AuthProvider _auth;

  bool _lastSignedIn = false;
  List<Playlist> _playlists = const <Playlist>[];
  List<Track> _favorites = const <Track>[];
  final Set<String> _favoriteIds = <String>{};
  final Set<String> _favoriteBusy = <String>{};
  final Map<String, Playlist> _detailCache = <String, Playlist>{};
  bool _loading = false;
  bool _loaded = false;
  bool _busy = false;
  String? _error;
  String? _actionError;

  List<Playlist> get playlists => _playlists;
  List<Track> get favorites => _favorites;
  bool get loading => _loading;
  bool get loaded => _loaded;
  bool get busy => _busy;
  String? get error => _error;
  String? get actionError => _actionError;
  int get favoriteCount => _favoriteIds.length;
  int get playlistCount => _playlists.length;

  void _onAuthChanged() {
    final signedIn = _auth.isAuthenticated;
    if (signedIn == _lastSignedIn) return;
    _lastSignedIn = signedIn;
    if (signedIn) {
      loadLibrary();
    } else {
      _reset();
    }
  }

  void _reset() {
    _playlists = const <Playlist>[];
    _favorites = const <Track>[];
    _favoriteIds.clear();
    _detailCache.clear();
    _loaded = false;
    _error = null;
    _actionError = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> loadLibrary({bool force = false}) async {
    if (!_auth.isAuthenticated) return;
    if (_loading) return;
    if (_loaded && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final playlists = await _api.playlists();
      final favorites = await _api.favorites();
      _playlists = playlists.items;
      _favorites = favorites;
      _favoriteIds
        ..clear()
        ..addAll(favorites.map((t) => t.id));
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'دریافت کتابخانه با خطا مواجه شد. دوباره تلاش کنید.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadLibrary(force: true);

  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);
  bool isFavoriteBusy(String trackId) => _favoriteBusy.contains(trackId);

  Future<void> toggleFavorite(Track track) async {
    if (!_auth.isAuthenticated) return;
    if (!_favoriteBusy.add(track.id)) return;
    final wasFavorite = _favoriteIds.contains(track.id);
    // Optimistic update for an instant, responsive heart.
    if (wasFavorite) {
      _favoriteIds.remove(track.id);
      _favorites = _favorites.where((t) => t.id != track.id).toList();
    } else {
      _favoriteIds.add(track.id);
      _favorites = <Track>[track.copyWith(isFavorite: true), ..._favorites];
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await _api.removeFavorite(track.id);
      } else {
        await _api.addFavorite(track.id);
      }
    } on ApiException catch (e) {
      // A 409 means the desired state already exists; treat it as success.
      if (e.statusCode != 409) {
        if (wasFavorite) {
          _favoriteIds.add(track.id);
          _favorites = <Track>[track.copyWith(isFavorite: true), ..._favorites];
        } else {
          _favoriteIds.remove(track.id);
          _favorites = _favorites.where((t) => t.id != track.id).toList();
        }
        _actionError = e.message;
      }
    } catch (_) {
      if (wasFavorite) {
        _favoriteIds.add(track.id);
      } else {
        _favoriteIds.remove(track.id);
      }
      _actionError = 'همگام‌سازی علاقه‌مندی با سرور انجام نشد.';
    } finally {
      _favoriteBusy.remove(track.id);
      notifyListeners();
    }
  }

  Future<Playlist> createPlaylist({
    required String name,
    String description = '',
    bool isPublic = false,
  }) async {
    _busy = true;
    _actionError = null;
    notifyListeners();
    try {
      final playlist = await _api.createPlaylist(
        name: name,
        description: description,
        isPublic: isPublic,
      );
      _playlists = <Playlist>[playlist, ..._playlists];
      _loaded = true;
      return playlist;
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Playlist> updatePlaylist({
    required String id,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    _busy = true;
    _actionError = null;
    notifyListeners();
    try {
      final updated = await _api.updatePlaylist(
        id: id,
        name: name,
        description: description,
        isPublic: isPublic,
      );
      _playlists = _playlists.map((p) => p.id == id ? updated : p).toList();
      final existingDetail = _detailCache[id];
      _detailCache[id] = updated.copyWith(
        tracks: existingDetail?.tracks ?? updated.tracks,
      );
      return updated;
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(String id) async {
    _actionError = null;
    try {
      await _api.deletePlaylist(id);
      _playlists = _playlists.where((p) => p.id != id).toList();
      _detailCache.remove(id);
      notifyListeners();
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    }
  }

  Future<Playlist> getPlaylistDetail(String id) async {
    final cached = _detailCache[id];
    if (cached != null && cached.tracks.isNotEmpty) return cached;
    try {
      final playlist = await _api.playlist(id);
      _detailCache[id] = playlist;
      _playlists = _playlists
          .map((p) => p.id == id
              ? p.copyWith(
                  trackCount: playlist.trackCount,
                  name: playlist.name,
                  description: playlist.description,
                )
              : p)
          .toList();
      notifyListeners();
      return playlist;
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    _actionError = null;
    try {
      await _api.addTrackToPlaylist(
        playlistId: playlistId,
        trackId: track.id,
      );
      _playlists = _playlists
          .map((p) => p.id == playlistId
              ? p.copyWith(trackCount: p.trackCount + 1)
              : p)
          .toList();
      final detail = _detailCache[playlistId];
      if (detail != null) {
        final exists = detail.tracks.any((t) => t.track.id == track.id);
        if (!exists) {
          _detailCache[playlistId] = detail.copyWith(
            tracks: <TrackRef>[
              ...detail.tracks,
              TrackRef(track: track, position: detail.tracks.length),
            ],
            trackCount: detail.trackCount + 1,
          );
        }
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode != 409) {
        _actionError = e.message;
        rethrow;
      }
    }
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    _actionError = null;
    try {
      await _api.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
      _playlists = _playlists
          .map((p) => p.id == playlistId
              ? p.copyWith(
                  trackCount: (p.trackCount - 1).clamp(0, 99999).toInt(),
                )
              : p)
          .toList();
      final detail = _detailCache[playlistId];
      if (detail != null) {
        _detailCache[playlistId] = detail.copyWith(
          tracks:
              detail.tracks.where((t) => t.track.id != trackId).toList(),
          trackCount: (detail.trackCount - 1).clamp(0, 99999).toInt(),
        );
      }
      notifyListeners();
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    }
  }

  void clearActionError() {
    if (_actionError == null) return;
    _actionError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
