import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/track.dart';
import '../../../widgets/cover_art.dart';

/// A compact, RTL-friendly track row used by Home ("تازه‌ها") and Search.
///
/// Playback, favorite and "more" affordances live in one place, and covers fall
/// back to a branded gradient when the network image is unavailable.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    this.isFavorite = false,
    this.isPlaying = false,
    this.favoriteBusy = false,
    this.onTap,
    this.onFavorite,
    this.onMore,
    this.trailing,
  });

  final Track track;

  /// Whether the track is in the library's favorites.
  final bool isFavorite;

  /// Whether this track is the one currently loaded in the player.
  final bool isPlaying;

  /// While a favorite request is in flight the heart shows a tiny spinner.
  final bool favoriteBusy;

  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMore;

  /// Optional extra trailing widget (e.g. a "remove" button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.primaryDeep.withValues(alpha: 0.16)
                : AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPlaying
                  ? AppColors.primary.withValues(alpha: 0.42)
                  : AppColors.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: <Widget>[
              _CoverWithStatus(url: track.coverUrl, isPlaying: isPlaying),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isPlaying
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        Text(
                          '  •  ${formatDuration(track.duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...<Widget>[
                _MiniAction(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.pink : AppColors.textMuted,
                  tooltip: isFavorite
                      ? 'حذف از علاقه‌مندی‌ها'
                      : 'افزودن به علاقه‌مندی‌ها',
                  onPressed: onFavorite,
                  busy: favoriteBusy,
                ),
                _MiniAction(
                  icon: Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                  tooltip: 'گزینه‌های بیشتر',
                  onPressed: onMore,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverWithStatus extends StatelessWidget {
  const _CoverWithStatus({required this.url, required this.isPlaying});

  final String url;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CoverArt(url: url, size: 52, borderRadius: 14),
          if (isPlaying)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: busy ? null : onPressed,
      tooltip: tooltip,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20, color: color),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
