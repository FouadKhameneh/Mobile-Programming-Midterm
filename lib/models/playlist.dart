import 'package:flutter/foundation.dart';

import 'track.dart';

@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.trackCount,
    this.tracks = const <TrackRef>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isPublic;
  final int trackCount;
  final List<TrackRef> tracks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    final tracks = <TrackRef>[];
    if (rawTracks is List) {
      for (final item in rawTracks) {
        if (item is Map<String, dynamic>) {
          tracks.add(TrackRef.fromJson(item));
        } else if (item is Map) {
          tracks.add(TrackRef.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final count = json['track_count'] ?? json['trackCount'] ?? tracks.length;
    return Playlist(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? 'پلی‌لیست'}',
      description: '${json['description'] ?? ''}',
      isPublic: json['is_public'] == true || json['isPublic'] == true,
      trackCount: count is num ? count.toInt() : int.tryParse('$count') ?? tracks.length,
      tracks: List<TrackRef>.unmodifiable(tracks),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse('$value');
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    bool? isPublic,
    int? trackCount,
    List<TrackRef>? tracks,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      trackCount: trackCount ?? this.trackCount,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// A track inside a playlist. The API embeds the whole track object and adds a
/// position; we keep the track plus the optional position.
@immutable
class TrackRef {
  const TrackRef({required this.track, this.position});

  final Track track;
  final int? position;

  factory TrackRef.fromJson(Map<String, dynamic> json) {
    final nested = json['track'];
    final trackJson = nested is Map
        ? Map<String, dynamic>.from(nested)
        : Map<String, dynamic>.from(json);
    final position = json['position'];
    return TrackRef(
      track: Track.fromJson(trackJson),
      position: position is num ? position.toInt() : int.tryParse('$position'),
    );
  }
}
