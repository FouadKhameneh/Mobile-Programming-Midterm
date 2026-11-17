import '../../models/auth_models.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../models/user.dart';

Map<String, dynamic>? asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Normalizes the different token envelopes the API may return.
TokenPair? parseTokenPair(dynamic data) {
  final map = asMap(data);
  if (map == null) return null;
  final nested = asMap(map['tokens']);
  final access = (map['access'] ??
          map['access_token'] ??
          map['accessToken'] ??
          nested?['access'] ??
          nested?['access_token'])
      ?.toString();
  final refresh = (map['refresh'] ??
          map['refresh_token'] ??
          map['refreshToken'] ??
          nested?['refresh'] ??
          nested?['refresh_token'])
      ?.toString();
  if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
    return null;
  }
  return TokenPair(accessToken: access, refreshToken: refresh);
}

User? parseUser(dynamic data) {
  final map = asMap(data);
  if (map == null) return null;
  final nested = asMap(map['user']) ?? asMap(map['profile']) ?? asMap(map['data']);
  final target = nested ?? map;
  if (target['email'] == null && target['username'] == null) return null;
  return User.fromJson(target);
}

Track? parseTrack(dynamic data) {
  final map = asMap(data);
  if (map == null) return null;
  final nested = asMap(map['track']);
  return Track.fromJson(nested ?? map);
}

List<Track> parseTrackList(dynamic data) {
  dynamic raw = data;
  if (data is Map) {
    final map = asMap(data);
    raw = map?['results'] ?? map?['tracks'] ?? map?['items'] ?? map?['data'];
  }
  if (raw is! List) return const <Track>[];
  final tracks = <Track>[];
  for (final item in raw) {
    final map = asMap(item);
    if (map == null) continue;
    final track = parseTrack(map);
    if (track != null && track.id.isNotEmpty) tracks.add(track);
  }
  return tracks;
}

List<Playlist> parsePlaylistList(dynamic data) {
  dynamic raw = data;
  if (data is Map) {
    final map = asMap(data);
    raw = map?['results'] ?? map?['playlists'] ?? map?['items'] ?? map?['data'];
  }
  if (raw is! List) return const <Playlist>[];
  final playlists = <Playlist>[];
  for (final item in raw) {
    final map = asMap(item);
    if (map == null) continue;
    playlists.add(Playlist.fromJson(map));
  }
  return playlists;
}

int parseCount(dynamic data, {int fallback = 0}) {
  final map = asMap(data);
  final raw = map?['count'] ?? map?['total'] ?? fallback;
  return raw is num ? raw.toInt() : int.tryParse('$raw') ?? fallback;
}

String? extractErrorMessage(dynamic data, {String fallback = 'خطایی رخ داد.'}) {
  final map = asMap(data);
  if (map == null) return null;
  final error = map['error'];
  if (error is Map) return error['message']?.toString();
  if (error is String) return error;
  return map['message']?.toString() ?? map['detail']?.toString();
}
