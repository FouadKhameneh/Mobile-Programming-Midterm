import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';

/// A single track returned by the Soundify API.
@immutable
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.duration,
    required this.streamUrl,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final String streamUrl;
  final bool isFavorite;

  factory Track.fromJson(Map<String, dynamic> json) {
    final rawDuration = json['duration'] ?? json['duration_seconds'] ?? 0;
    var seconds = rawDuration is num
        ? rawDuration.toDouble()
        : double.tryParse('$rawDuration') ?? 0;
    // The API exposes seconds. Defensively support millisecond payloads too.
    if (seconds > 10000) seconds = seconds / 1000;
    final id = '${json['id'] ?? ''}';
    final stream = '${json['stream_url'] ?? json['streamUrl'] ?? ''}';
    return Track(
      id: id,
      title: '${json['title'] ?? 'بدون عنوان'}',
      artist: '${json['artist'] ?? 'هنرمند ناشناس'}',
      album: '${json['album'] ?? ''}',
      coverUrl: '${json['cover_url'] ?? json['coverUrl'] ?? ''}',
      duration: Duration(milliseconds: (seconds * 1000).round()),
      streamUrl: stream.isNotEmpty
          ? stream
          : '${AppConfig.apiBaseUrl}/tracks/$id/stream/',
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'cover_url': coverUrl,
        'duration': duration.inSeconds,
        'stream_url': streamUrl,
        'is_favorite': isFavorite,
      };

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    Duration? duration,
    String? streamUrl,
    bool? isFavorite,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
