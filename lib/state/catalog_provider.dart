import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/track.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider({required ApiClient api}) : _api = api;

  final ApiClient _api;

  List<Track> _featured = const <Track>[];
  List<Track> _tracks = const <Track>[];
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  List<Track> get featured => _featured;
  List<Track> get tracks => _tracks;
  bool get loading => _loading;
  String? get error => _error;
  bool get loaded => _loaded;

  List<String> get artists {
    final seen = <String>{};
    final result = <String>[];
    for (final track in _tracks) {
      final artist = track.artist.trim();
      if (artist.isNotEmpty && seen.add(artist)) result.add(artist);
      if (result.length >= 12) break;
    }
    return result;
  }

  List<Track> get recentlyAdded {
    if (_tracks.length <= 12) return _tracks;
    return _tracks.sublist(_tracks.length - 12).reversed.toList();
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final featuredFuture = _api.featuredTracks();
      final tracksFuture = _api.tracks(pageSize: 30);
      _featured = await featuredFuture;
      final page = await tracksFuture;
      _tracks = page.items;
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'دریافت کاتالوگ با خطا مواجه شد. دوباره تلاش کنید.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
