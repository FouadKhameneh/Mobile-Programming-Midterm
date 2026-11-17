import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/utils/json_utils.dart';
import 'package:soundify/models/playlist.dart';
import 'package:soundify/models/track.dart';

void main() {
  group('Track.fromJson', () {
    test('parses the documented API shape (duration in seconds)', () {
      final track = Track.fromJson(<String, dynamic>{
        'id': 'abc',
        'title': 'Paradise',
        'artist': 'Coldplay',
        'album': 'Mylo Xyloto',
        'cover_url': 'https://example.com/cover.jpg',
        'duration': 279,
        'stream_url': 'https://example.com/stream/',
        'is_favorite': true,
      });

      expect(track.id, 'abc');
      expect(track.title, 'Paradise');
      expect(track.artist, 'Coldplay');
      expect(track.album, 'Mylo Xyloto');
      expect(track.duration, const Duration(seconds: 279));
      expect(track.isFavorite, isTrue);
      expect(track.streamUrl, 'https://example.com/stream/');
    });

    test('defensively converts millisecond durations', () {
      final track = Track.fromJson(<String, dynamic>{
        'id': 'abc',
        'title': 'Test',
        'artist': 'Artist',
        'duration': 238000,
      });
      expect(track.duration, const Duration(seconds: 238));
    });

    test('builds a stream URL from the id when the API omits it', () {
      final track = Track.fromJson(<String, dynamic>{
        'id': 'track-id',
        'title': 'Test',
        'artist': 'Artist',
        'duration': 10,
      });
      expect(track.streamUrl, contains('/tracks/track-id/stream/'));
    });

    test('falls back to sensible labels for missing values', () {
      final track = Track.fromJson(<String, dynamic>{'id': 'x'});
      expect(track.title, 'بدون عنوان');
      expect(track.artist, 'هنرمند ناشناس');
      expect(track.album, '');
    });
  });

  group('Playlist.fromJson', () {
    test('parses track_count and embedded tracks', () {
      final playlist = Playlist.fromJson(<String, dynamic>{
        'id': 4,
        'name': 'Road trip',
        'description': 'For the highway',
        'is_public': false,
        'track_count': 1,
        'tracks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 't1',
            'title': 'Yellow',
            'artist': 'Coldplay',
            'duration': 267,
            'position': 0,
          },
        ],
      });

      expect(playlist.id, '4');
      expect(playlist.name, 'Road trip');
      expect(playlist.trackCount, 1);
      expect(playlist.tracks, hasLength(1));
      expect(playlist.tracks.first.track.title, 'Yellow');
      expect(playlist.tracks.first.position, 0);
    });

    test('accepts a wrapped track object', () {
      final playlist = Playlist.fromJson(<String, dynamic>{
        'id': 'p',
        'name': 'P',
        'tracks': <Map<String, dynamic>>[
          <String, dynamic>{
            'position': 2,
            'track': <String, dynamic>{
              'id': 't',
              'title': 'Song',
              'artist': 'Artist',
            },
          },
        ],
      });
      expect(playlist.tracks.single.track.id, 't');
      expect(playlist.tracks.single.position, 2);
    });
  });

  group('token and list normalization', () {
    test('parses flat token envelope', () {
      final pair = parseTokenPair(<String, dynamic>{
        'access': 'a',
        'refresh': 'r',
      });
      expect(pair?.accessToken, 'a');
      expect(pair?.refreshToken, 'r');
    });

    test('parses nested token envelope', () {
      final pair = parseTokenPair(<String, dynamic>{
        'tokens': <String, dynamic>{
          'access_token': 'a',
          'refresh_token': 'r',
        },
      });
      expect(pair?.accessToken, 'a');
      expect(pair?.refreshToken, 'r');
    });

    test('returns null for incomplete tokens', () {
      expect(parseTokenPair(<String, dynamic>{'access': 'a'}), isNull);
      expect(parseTokenPair(null), isNull);
    });

    test('parses paginated and raw track lists', () {
      final raw = <Map<String, dynamic>>[
        <String, dynamic>{'id': '1', 'title': 'A', 'artist': 'X'},
        <String, dynamic>{'id': '2', 'title': 'B', 'artist': 'Y'},
      ];
      expect(parseTrackList(raw), hasLength(2));
      expect(
        parseTrackList(<String, dynamic>{'count': 2, 'results': raw}),
        hasLength(2),
      );
    });

    test('skips invalid items in a track list', () {
      final tracks = parseTrackList(<dynamic>[
        <String, dynamic>{'id': '', 'title': 'Invalid'},
        <String, dynamic>{'id': 'ok', 'title': 'Valid', 'artist': 'A'},
      ]);
      expect(tracks, hasLength(1));
      expect(tracks.first.id, 'ok');
    });
  });
}
