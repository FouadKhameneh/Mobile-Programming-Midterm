import 'dart:math' as math;

import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/track.dart';
import '../../state/player_provider.dart';
import '../../widgets/equalizer_bars.dart';
import 'widgets/player_artwork.dart';

/// Premium, full-screen "now playing" experience.
///
/// The screen is always rendered with the dark Soundify palette (even in light
/// mode) because it is a media surface: blurred ambient cover, deep canvas,
/// large glowing artwork and RTL layout. All playback state comes from
/// [PlayerProvider]; the screen itself is stateless with respect to audio.
class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key, this.isFavorite = false, this.onFavorite});

  /// Initial favorite state for the placeholder heart button.
  final bool isFavorite;

  /// Called when the user taps the favorite button. When omitted the heart
  /// still toggles locally so the interaction feels alive.
  final VoidCallback? onFavorite;

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  late bool _favorite = widget.isFavorite;
  double? _dragProgress;
  String? _dragTrackId;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.currentTrack;

    // Drop any in-flight drag when the track changes underneath us.
    if (_dragTrackId != null && _dragTrackId != track?.id) {
      _dragProgress = null;
      _dragTrackId = null;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              PlayerArtwork(
                track: track,
                borderRadius: 0,
                blurSigma: 44,
                fallbackIconSize: 140,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.background.withValues(alpha: 0.5),
                      AppColors.background.withValues(alpha: 0.82),
                      AppColors.background,
                    ],
                    stops: const <double>[0, 0.55, 1],
                  ),
                ),
              ),
              SafeArea(
                child: track == null
                    ? _buildEmptyState(context)
                    : _buildPlayer(context, player, track),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    PlayerProvider player,
    Track track,
  ) {
    return Column(
      children: <Widget>[
        _TopBar(
          player: player,
          onClose: () => Navigator.maybePop(context),
          onQueue: () => _openQueue(context, player),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 6, 28, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(
                  constraints.maxWidth,
                  math.min(constraints.maxHeight, 380.0),
                );
                return Center(
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primaryDeep.withValues(
                              alpha: 0.42,
                            ),
                            blurRadius: 52,
                            spreadRadius: 2,
                            offset: const Offset(0, 22),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: PlayerArtwork(
                        track: track,
                        borderRadius: 30,
                        useHero: true,
                        fallbackIconSize: 84,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTrackInfo(player, track),
              if (player.error != null) ...<Widget>[
                const SizedBox(height: 12),
                _ErrorBanner(message: player.error!),
              ],
              const SizedBox(height: 14),
              _buildSeekBar(context, player),
              const SizedBox(height: 6),
              _buildControls(player),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackInfo(PlayerProvider player, Track track) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey<String>(track.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 23,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (track.album.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    track.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: _favorite ? 'حذف از موردعلاقه‌ها' : 'افزودن به موردعلاقه‌ها',
          onPressed: _toggleFavorite,
          iconSize: 26,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              _favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey<bool>(_favorite),
              color: _favorite ? AppColors.pink : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar(BuildContext context, PlayerProvider player) {
    final total = player.duration;
    final progress = (_dragProgress ?? player.progress)
        .clamp(0.0, 1.0)
        .toDouble();
    final shownPosition = _dragProgress != null && total > Duration.zero
        ? Duration(
            milliseconds: (total.inMilliseconds * _dragProgress!).round(),
          )
        : player.position;

    return Column(
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.6,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.outline,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: progress,
            onChanged: (value) {
              setState(() {
                _dragTrackId = player.currentTrack?.id;
                _dragProgress = value;
              });
            },
            onChangeEnd: (value) {
              final target = total > Duration.zero
                  ? Duration(
                      milliseconds: (total.inMilliseconds * value).round(),
                    )
                  : Duration.zero;
              setState(() {
                _dragProgress = null;
                _dragTrackId = null;
              });
              player.seek(target);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: <Widget>[
              Text(
                formatDuration(shownPosition),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                formatDuration(total),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          tooltip: 'قبلی',
          onPressed:
              player.hasPrevious || player.position > const Duration(seconds: 3)
              ? () {
                  player.previous();
                }
              : null,
          iconSize: 38,
          color: AppColors.textPrimary,
          disabledColor: AppColors.textMuted.withValues(alpha: 0.45),
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        const SizedBox(width: 22),
        _MainPlayButton(player: player),
        const SizedBox(width: 22),
        IconButton(
          tooltip: 'بعدی',
          onPressed: player.hasNext
              ? () {
                  player.next();
                }
              : null,
          iconSize: 38,
          color: AppColors.textPrimary,
          disabledColor: AppColors.textMuted.withValues(alpha: 0.45),
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'بستن',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 30,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.music_off_rounded,
                    size: 54,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'آهنگی در حال پخش نیست',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'از کتابخانه یک آهنگ انتخاب کنید تا پخش شروع شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFavorite() {
    setState(() => _favorite = !_favorite);
    widget.onFavorite?.call();
  }

  Future<void> _openQueue(BuildContext context, PlayerProvider player) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      // The sheet paints its own drag handle inside the rounded container.
      showDragHandle: false,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: player,
          builder: (context, child) => _QueueSheet(player: player),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Top bar
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.player,
    required this.onClose,
    required this.onQueue,
  });

  final PlayerProvider player;
  final VoidCallback onClose;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'بستن',
            onPressed: onClose,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'در حال پخش',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                EqualizerBars(
                  playing: player.playing,
                  color: AppColors.primary,
                  height: 13,
                  barWidth: 2.6,
                  gap: 3,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'صف پخش',
            onPressed: onQueue,
            icon: const Icon(
              Icons.queue_music_rounded,
              size: 26,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Play / pause button
// -----------------------------------------------------------------------------

class _MainPlayButton extends StatelessWidget {
  const _MainPlayButton({required this.player});

  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.16),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: player.currentTrack == null
              ? null
              : () {
                  player.togglePlayPause();
                },
          child: SizedBox(
            width: 76,
            height: 76,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: player.loading
                    ? const SizedBox(
                        key: ValueKey<String>('loading'),
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey<bool>(player.playing),
                        size: 42,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Error banner
// -----------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11.5,
                height: 1.6,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Queue sheet
// -----------------------------------------------------------------------------

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.player});

  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.62;
    final queue = player.queue;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.queue_music_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'صف پخش',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  pluralTracks(queue.length),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: queue.isEmpty
                ? const Center(
                    child: Text(
                      'صف پخش خالی است',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrent = index == player.currentIndex;
                      return _QueueTile(
                        track: track,
                        index: index,
                        isCurrent: isCurrent,
                        playing: player.playing,
                        onTap: () {
                          player.skipToIndex(index);
                          Navigator.of(context).maybePop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.playing,
    required this.onTap,
  });

  final Track track;
  final int index;
  final bool isCurrent;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent
          ? AppColors.primary.withValues(alpha: 0.09)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 24,
                child: Center(
                  child: isCurrent
                      ? EqualizerBars(
                          playing: playing,
                          color: AppColors.primary,
                          height: 13,
                          barWidth: 2.2,
                          gap: 2.2,
                        )
                      : Text(
                          toPersianDigits(index + 1),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              PlayerArtwork(
                track: track,
                size: 42,
                borderRadius: 10,
                fallbackIconSize: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatDuration(track.duration),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
