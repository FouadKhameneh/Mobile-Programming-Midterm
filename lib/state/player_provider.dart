import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../core/config/app_config.dart';
import '../models/track.dart';

/// The single source of truth for audio playback in Soundify.
///
/// Wraps exactly one [AudioPlayer] (which is started in background mode by
/// `JustAudioBackground.init` in `main.dart`) and exposes an immutable,
/// UI-friendly snapshot of its state to the widget tree.
///
/// The provider never throws into the widget tree: every player call is
/// guarded, and failures are surfaced through [error] instead of crashing the
/// app. A failed stream simply results in an error banner that the player UI
/// can display, plus the notification / queue staying intact so the listener
/// can skip to another track.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _bindStreams();
    unawaited(_configureAudioSession());
  }

  final AudioPlayer _player;

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  List<Track> _queue = const <Track>[];
  int _currentIndex = -1;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  bool _disposed = false;

  /// Incremented for every new playback request so that a slow/failed previous
  /// request can never overwrite the state of the current one.
  int _requestToken = 0;

  static const String _playbackErrorMessage =
      'پخش این قطعه ممکن نشد. اتصال اینترنت یا نشانی فایل را بررسی کنید.';

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  /// The track that is currently loaded (may be paused or ended).
  Track? get currentTrack {
    final index = _currentIndex;
    if (index < 0 || index >= _queue.length) return null;
    return _queue[index];
  }

  /// Immutable snapshot of the active queue.
  List<Track> get queue => _queue;

  /// Index of [currentTrack] inside [queue], or `-1` when nothing is loaded.
  int get currentIndex => _currentIndex;

  /// Whether a track is loaded and can be controlled.
  bool get hasTrack => currentTrack != null;

  /// Whether the player is actually producing audio right now.
  bool get playing => _playing;

  /// Whether the current track is loading or buffering.
  bool get loading => _loading;

  /// Current playback position.
  Duration get position => _position;

  /// Duration of the current track. Falls back to the metadata duration while
  /// the player is still preparing the stream.
  Duration get duration {
    if (_duration > Duration.zero) return _duration;
    return currentTrack?.duration ?? Duration.zero;
  }

  /// Normalized playback progress in the `0.0 .. 1.0` range.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (_position.inMilliseconds / total).clamp(0.0, 1.0).toDouble();
  }

  /// Whether the player can advance to the next queue item.
  bool get hasNext => currentTrack != null && _currentIndex < _queue.length - 1;

  /// Whether the player can go back to the previous queue item.
  bool get hasPrevious => currentTrack != null && _currentIndex > 0;

  /// Human readable, Persian error message for the last failure, if any.
  String? get error => _error;

  /// Convenience for UI: whether an error is currently surfaced.
  bool get hasError => _error != null;

  // ---------------------------------------------------------------------------
  // Playback commands
  // ---------------------------------------------------------------------------

  /// Replaces the queue and starts playing at [initialIndex].
  Future<void> playQueue(List<Track> tracks, {int initialIndex = 0}) async {
    if (_disposed) return;
    final requested = initialIndex >= 0 && initialIndex < tracks.length
        ? tracks[initialIndex]
        : null;
    final playable = tracks
        .where(
          (track) =>
              track.streamUrl.trim().isNotEmpty &&
              _resolveUri(track.streamUrl) != null,
        )
        .toList(growable: false);
    if (playable.isEmpty) {
      _error = 'هیچ آهنگ قابل پخشی در این فهرست پیدا نشد.';
      _loading = false;
      _safeNotify();
      return;
    }

    // Filtering invalid streams may shift indices: locate the requested track
    // again so the listener always gets the track they tapped.
    var index = requested == null
        ? initialIndex
        : playable.indexWhere((track) => track.id == requested.id);
    if (index < 0) index = initialIndex;
    if (index < 0) index = 0;
    if (index >= playable.length) index = playable.length - 1;

    final token = ++_requestToken;
    _queue = List<Track>.unmodifiable(playable);
    _currentIndex = index;
    _position = Duration.zero;
    _duration = playable[index].duration;
    _loading = true;
    _error = null;
    _safeNotify();

    try {
      final sources = <AudioSource>[
        for (final track in playable) _sourceFor(track),
      ];
      final reportedDuration = await _player.setAudioSources(
        sources,
        initialIndex: index,
        initialPosition: Duration.zero,
        preload: true,
      );
      if (_disposed || token != _requestToken) return;
      if (reportedDuration != null && reportedDuration > Duration.zero) {
        _duration = reportedDuration;
      }
      _loading = false;
      _safeNotify();
      await _player.play();
    } on PlayerInterruptedException {
      // A newer request replaced this one; the newer call owns the state.
      return;
    } on PlayerException {
      if (token == _requestToken) _failPlayback();
    } catch (_) {
      if (token == _requestToken) _failPlayback();
    }
  }

  /// Plays a single [track], optionally inside the context of [queue].
  ///
  /// When [queue] is given the track is located inside it so that next/previous
  /// and the notification queue behave correctly. If the track is not part of
  /// [queue] it is played on its own.
  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    if (_disposed) return;
    final list = <Track>[
      if (queue != null && queue.isNotEmpty) ...queue else track,
    ];
    var index = list.indexWhere((item) => item.id == track.id);
    if (index < 0) {
      list.insert(0, track);
      index = 0;
    }

    final sameQueue = listEquals(_queue, list);
    final sameTrack = currentTrack?.id == track.id;
    if (sameQueue && sameTrack && index == _currentIndex) {
      _error = null;
      if (!_player.playing) {
        if (_player.processingState == ProcessingState.completed) {
          await seek(Duration.zero);
        }
        await _resume();
      }
      _safeNotify();
      return;
    }

    await playQueue(list, initialIndex: index);
  }

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    if (_disposed || currentTrack == null) return;
    // After a failed load, the play button acts as "retry".
    if (_error != null && _queue.isNotEmpty) {
      await playQueue(_queue, initialIndex: _currentIndex);
      return;
    }
    try {
      _error = null;
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        await _player.play();
        return;
      }
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } on PlayerException {
      _failPlayback();
    } catch (_) {
      _failPlayback();
    }
  }

  /// Advances to the next queue item.
  Future<void> next() async {
    if (_disposed) return;
    final target = _currentIndex + 1;
    if (_currentIndex < 0 || target >= _queue.length) return;
    // Skipping is not possible while the player is preparing a source, and
    // after a failure the player may be stuck on a broken URL. In both cases
    // rebuild the queue around the target track instead.
    if (_error != null ||
        _player.processingState == ProcessingState.loading ||
        !_player.hasNext) {
      await playQueue(_queue, initialIndex: target);
      return;
    }
    try {
      _error = null;
      await _player.seekToNext();
    } on PlayerException {
      _failPlayback();
    } catch (_) {
      _failPlayback();
    }
  }

  /// Goes back to the previous queue item. Mirrors the common music-player
  /// behaviour of restarting the current track when it has been playing for
  /// more than a few seconds.
  Future<void> previous() async {
    if (_disposed || currentTrack == null) return;
    if (_error != null || _player.processingState == ProcessingState.loading) {
      final target = _currentIndex > 0 ? _currentIndex - 1 : _currentIndex;
      await playQueue(_queue, initialIndex: target);
      return;
    }
    try {
      _error = null;
      if (_position > const Duration(seconds: 3)) {
        await seek(Duration.zero);
        return;
      }
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else {
        await seek(Duration.zero);
      }
    } on PlayerException {
      _failPlayback();
    } catch (_) {
      _failPlayback();
    }
  }

  /// Seeks to [position], clamped to the current track's duration.
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    var target = position;
    if (target < Duration.zero) target = Duration.zero;
    final total = duration;
    if (total > Duration.zero && target > total) target = total;
    _position = target;
    _safeNotify();
    try {
      await _player.seek(target);
    } on PlayerException {
      _failPlayback();
    } catch (_) {
      _failPlayback();
    }
  }

  /// Stops playback, clears the queue and removes the media notification.
  Future<void> stop() async {
    if (_disposed) return;
    _requestToken++;
    _queue = const <Track>[];
    _currentIndex = -1;
    _playing = false;
    _loading = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _error = null;
    _safeNotify();
    try {
      await _player.stop();
    } catch (_) {
      // The queue is already cleared; nothing else to do.
      return;
    }
  }

  /// Jumps within the active queue and resumes playback.
  Future<void> skipToIndex(int index) async {
    if (_disposed) return;
    if (index < 0 || index >= _queue.length || index == _currentIndex) return;
    if (_error != null || _player.processingState == ProcessingState.loading) {
      await playQueue(_queue, initialIndex: index);
      return;
    }
    try {
      _error = null;
      await _player.seek(Duration.zero, index: index);
      if (!_player.playing) {
        await _player.play();
      }
    } on PlayerException {
      _failPlayback();
    } catch (_) {
      _failPlayback();
    }
  }

  /// Clears a surfaced error (used by the UI after showing it once).
  void clearError() {
    if (_error == null) return;
    _error = null;
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _resume() async {
    try {
      await _player.play();
    } on PlayerException {
      _failPlayback();
    } catch (_) {
      _failPlayback();
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {
      // Non fatal: the platform default configuration still allows playback.
      return;
    }
  }

  void _bindStreams() {
    _subscriptions.add(_player.playerStateStream.listen(_handlePlayerState));
    _subscriptions.add(_player.positionStream.listen(_handlePosition));
    _subscriptions.add(_player.durationStream.listen(_handleDuration));
    _subscriptions.add(_player.currentIndexStream.listen(_handleCurrentIndex));
    _subscriptions.add(
      _player.errorStream.listen((PlayerException error) => _failPlayback()),
    );
    // Error events that never reach [errorStream] (e.g. stream-level failures)
    // are also surfaced here so the UI can react.
    _subscriptions.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) => _failPlayback(),
      ),
    );
  }

  void _handlePlayerState(PlayerState state) {
    if (_disposed) return;
    final isCompleted = state.processingState == ProcessingState.completed;
    final isBuffering =
        state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering;
    final playing = isCompleted ? false : state.playing;
    if (playing == _playing && isBuffering == _loading) return;
    _playing = playing;
    _loading = isBuffering;
    if (isCompleted) {
      final total = duration;
      if (total > Duration.zero) _position = total;
    }
    _safeNotify();
  }

  void _handlePosition(Duration position) {
    if (_disposed || position == _position) return;
    _position = position;
    _safeNotify();
  }

  void _handleDuration(Duration? duration) {
    if (_disposed) return;
    final next = duration ?? currentTrack?.duration ?? Duration.zero;
    if (next == _duration) return;
    _duration = next;
    _safeNotify();
  }

  void _handleCurrentIndex(int? index) {
    if (_disposed || index == null) return;
    if (index < 0 || index >= _queue.length || index == _currentIndex) return;
    _currentIndex = index;
    _position = Duration.zero;
    _duration = currentTrack?.duration ?? Duration.zero;
    _error = null;
    _safeNotify();
  }

  void _failPlayback() {
    if (_disposed) return;
    _playing = false;
    _loading = false;
    final message = _playbackErrorMessage;
    if (_error == message) {
      _safeNotify();
      return;
    }
    _error = message;
    _safeNotify();
  }

  /// Builds the background-aware source for [track] with a `MediaItem` tag so
  /// the lock-screen / notification shows the right metadata and cover.
  AudioSource _sourceFor(Track track) {
    final streamUri = _resolveUri(track.streamUrl)!;
    final id = track.id.trim().isNotEmpty ? track.id.trim() : '$streamUri';
    return AudioSource.uri(
      streamUri,
      tag: MediaItem(
        id: id,
        title: track.title,
        artist: track.artist,
        album: track.album.trim().isEmpty ? null : track.album,
        artUri: _resolveUri(track.coverUrl),
        duration: track.duration > Duration.zero ? track.duration : null,
      ),
    );
  }

  /// Resolves a (possibly relative) URL returned by the API into an absolute
  /// URI. Returns `null` when the value cannot be parsed.
  Uri? _resolveUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.hasScheme) return uri;
    try {
      return Uri.parse(AppConfig.apiHost).resolveUri(uri);
    } catch (_) {
      return null;
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_player.dispose());
    super.dispose();
  }
}
