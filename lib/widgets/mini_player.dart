import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../screens/player/full_player_screen.dart';
import '../screens/player/widgets/player_artwork.dart';
import '../state/player_provider.dart';
import 'equalizer_bars.dart';

/// Floating mini player that sits above the bottom navigation bar.
///
/// It renders nothing when no track is loaded, adapts to the ambient theme and
/// opens the full player on tap. Drop it into `MainShell` right above the
/// `NavigationBar` (or position it `bottom: navBarHeight` in a `Stack`).
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, this.onTap});

  /// Overrides the default "open the full player" behaviour.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.textSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark
        ? AppColors.outline.withValues(alpha: 0.85)
        : scheme.outlineVariant.withValues(alpha: 0.9);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? <Color>[
                        AppColors.surfaceHigh.withValues(alpha: 0.98),
                        AppColors.backgroundElevated.withValues(alpha: 0.98),
                      ]
                    : <Color>[Colors.white, const Color(0xFFF1EEFA)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: InkWell(
              onTap: onTap ?? () => _openFullPlayer(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 6, 9),
                    child: Row(
                      children: <Widget>[
                        PlayerArtwork(
                          track: track,
                          size: 46,
                          borderRadius: 14,
                          useHero: true,
                          fallbackIconSize: 22,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.35),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey<String>(track.id),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: <Widget>[
                                    if (player.error != null) ...<Widget>[
                                      Tooltip(
                                        message: player.error!,
                                        child: const Icon(
                                          Icons.error_outline_rounded,
                                          size: 13,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: secondaryColor,
                                              height: 1.3,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (player.playing)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: EqualizerBars(
                              playing: player.playing,
                              color: scheme.primary,
                              height: 15,
                              barWidth: 2.5,
                              gap: 2.5,
                            ),
                          ),
                        _MiniPlayButton(player: player),
                        const SizedBox(width: 2),
                        IconButton(
                          tooltip: 'بعدی',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          iconSize: 26,
                          color: isDark
                              ? AppColors.textPrimary
                              : scheme.onSurface,
                          onPressed: player.hasNext
                              ? () {
                                  player.next();
                                }
                              : null,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(21),
                    ),
                    child: LinearProgressIndicator(
                      value: player.progress,
                      minHeight: 2.6,
                      backgroundColor: borderColor.withValues(alpha: 0.55),
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FullPlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }
}

class _MiniPlayButton extends StatelessWidget {
  const _MiniPlayButton({required this.player});

  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton.filled(
        tooltip: player.playing ? 'توقف' : 'پخش',
        padding: EdgeInsets.zero,
        onPressed: () {
          player.togglePlayPause();
        },
        style: IconButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: player.loading
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  player.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  key: ValueKey<bool>(player.playing),
                  size: 24,
                ),
        ),
      ),
    );
  }
}
