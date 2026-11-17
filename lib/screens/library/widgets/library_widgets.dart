import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/playlist.dart';
import '../../../models/track.dart';
import '../../../state/library_provider.dart';

/// Shared, self-contained premium widgets for the library feature.
///
/// They deliberately live inside `screens/library/widgets` so the library and
/// playlist-detail screens never depend on another teammate's shared widgets.

const List<List<Color>> _playlistPalettes = <List<Color>>[
  <Color>[Color(0xFF7C3AED), Color(0xFFDB2777)],
  <Color>[Color(0xFF0EA5E9), Color(0xFF22D3EE)],
  <Color>[Color(0xFF10B981), Color(0xFF84CC16)],
  <Color>[Color(0xFFF59E0B), Color(0xFFEF4444)],
  <Color>[Color(0xFF6366F1), Color(0xFFA78BFA)],
  <Color>[Color(0xFFEC4899), Color(0xFFF97316)],
  <Color>[Color(0xFF14B8A6), Color(0xFF3B82F6)],
];

/// Deterministic gradient palette for a playlist, keyed by its id so every
/// playlist keeps a stable, recognisable colour.
List<Color> playlistGradientColors(String seed) {
  var hash = 7;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _playlistPalettes[hash % _playlistPalettes.length];
}

LinearGradient playlistGradient(String seed) {
  final colors = playlistGradientColors(seed);
  return LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// A square track artwork with a graceful gradient fallback.
class TrackCover extends StatelessWidget {
  const TrackCover({
    super.key,
    required this.url,
    this.size = 48,
    this.radius = 12,
    this.iconSize,
  });

  final String url;
  final double size;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = _CoverFallback(size: size, iconSize: iconSize);
    final trimmed = url.trim();
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: trimmed.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: trimmed,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 220),
                placeholder: (context, url) => fallback,
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.size, this.iconSize});

  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.coverFallback),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: iconSize ?? size * 0.42,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Playlist artwork: a 2x2 collage of the first four track covers when
/// available, otherwise a rich gradient placeholder with a playlist glyph.
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    super.key,
    required this.playlist,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.iconSize = 38,
    this.showCount = false,
    this.showPrivacy = false,
  });

  final Playlist playlist;
  final BorderRadius borderRadius;
  final double iconSize;
  final bool showCount;
  final bool showPrivacy;

  @override
  Widget build(BuildContext context) {
    final coverUrls = playlist.tracks
        .map((ref) => ref.track.coverUrl.trim())
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList(growable: false);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (coverUrls.isEmpty)
            _GradientCover(seed: playlist.id, iconSize: iconSize)
          else
            _CoverCollage(urls: coverUrls, seed: playlist.id),
          Positioned(
            top: -34,
            left: -24,
            child: _Glow(
              size: 120,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -18,
            child: _Glow(
              size: 130,
              color: Colors.black.withValues(alpha: 0.22),
            ),
          ),
          if (showPrivacy)
            Positioned(
              top: 8,
              left: 8,
              child: _PrivacyBadge(isPublic: playlist.isPublic),
            ),
          if (showCount)
            Positioned(
              left: 8,
              bottom: 8,
              child: _CountBadge(count: playlist.trackCount),
            ),
        ],
      ),
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.seed, required this.iconSize});

  final String seed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: playlistGradient(seed)),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _CoverCollage extends StatelessWidget {
  const _CoverCollage({required this.urls, required this.seed});

  final List<String> urls;
  final String seed;

  Widget _cell(int index) {
    if (index >= urls.length) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: playlistGradient(seed)),
      );
    }
    return CachedNetworkImage(
      imageUrl: urls[index],
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 240),
      placeholder: (context, url) =>
          const ColoredBox(color: AppColors.surfaceHigh),
      errorWidget: (context, url, error) => DecoratedBox(
        decoration: BoxDecoration(gradient: playlistGradient(seed)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _cell(0)),
              Expanded(child: _cell(1)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _cell(2)),
              Expanded(child: _cell(3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: <Color>[color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'عمومی' : 'خصوصی',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.music_note_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            toPersianDigits(count),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny animated equalizer bars shown next to the current track.
class PlayingIndicator extends StatefulWidget {
  const PlayingIndicator({
    super.key,
    this.color = AppColors.primary,
    this.size = 16,
    this.playing = true,
    this.barCount = 3,
  });

  final Color color;
  final double size;
  final bool playing;
  final int barCount;

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(widget.barCount, (index) {
              final phase = progress * math.pi + index * 0.9;
              final height =
                  widget.size * (0.28 + 0.72 * ((math.sin(phase) + 1) / 2));
              return Container(
                width: math.max(2.0, widget.size * 0.16),
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// A premium, compact track row used by the favourites tab and playlist detail.
class LibraryTrackTile extends StatelessWidget {
  const LibraryTrackTile({
    super.key,
    required this.track,
    this.position,
    this.onTap,
    this.onFavorite,
    this.onRemove,
    this.isFavorite = false,
    this.favoriteBusy = false,
    this.isCurrent = false,
    this.isPlaying = false,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  final Track track;
  final int? position;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onRemove;
  final bool isFavorite;
  final bool favoriteBusy;
  final bool isCurrent;
  final bool isPlaying;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = isCurrent;

    return Padding(
      padding: margin,
      child: Material(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: <Widget>[
                if (position != null) ...<Widget>[
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: highlight && isPlaying
                          ? const PlayingIndicator(
                              size: 14,
                              color: AppColors.primary,
                            )
                          : Text(
                              toPersianDigits(position!),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: highlight
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TrackCover(url: track.coverUrl, size: 46, radius: 12),
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
                          fontWeight: FontWeight.w700,
                          color: highlight
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            '•',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            formatDuration(track.duration),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onFavorite != null)
                  IconButton(
                    onPressed: favoriteBusy ? null : onFavorite,
                    tooltip: isFavorite
                        ? 'حذف از علاقه‌مندی‌ها'
                        : 'افزودن به علاقه‌مندی‌ها',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 38,
                    ),
                    icon: favoriteBusy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: isFavorite
                                ? AppColors.pink
                                : AppColors.textMuted,
                          ),
                  ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    tooltip: 'حذف از پلی‌لیست',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 38,
                    ),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered empty-state block used by both library tabs and playlist detail.
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.glassGradient,
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(icon, size: 42, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.75,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          if (secondaryLabel != null && onSecondary != null) ...<Widget>[
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Error block with a retry affordance.
class LibraryErrorState extends StatelessWidget {
  const LibraryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 38,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'مشکلی پیش آمد',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('تلاش دوباره'),
          ),
        ],
      ),
    );
  }
}

/// Simple centered loading block; used when there is no cached content yet.
class LibraryLoadingState extends StatelessWidget {
  const LibraryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 16),
          Text(
            'در حال بارگذاری کتابخانه…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

enum PlaylistAction { edit, delete }

/// Bottom sheet with the destructive/editing actions for a playlist.
Future<PlaylistAction?> showPlaylistActionsSheet(
  BuildContext context, {
  required Playlist playlist,
}) {
  return showModalBottomSheet<PlaylistAction>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: PlaylistCover(
                      playlist: playlist,
                      borderRadius: BorderRadius.circular(14),
                      iconSize: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pluralTracks(playlist.trackCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const _ActionGlyph(
                icon: Icons.edit_rounded,
                color: AppColors.primary,
              ),
              title: const Text('ویرایش پلی‌لیست'),
              subtitle: const Text('نام، توضیحات و وضعیت عمومی'),
              onTap: () => Navigator.of(sheetContext).pop(PlaylistAction.edit),
            ),
            ListTile(
              leading: const _ActionGlyph(
                icon: Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              title: const Text(
                'حذف پلی‌لیست',
                style: TextStyle(color: AppColors.danger),
              ),
              subtitle: const Text('حذف پلی‌لیست و دسترسی به آن'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(PlaylistAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _ActionGlyph extends StatelessWidget {
  const _ActionGlyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Confirmation dialog for deleting a playlist.
Future<bool> showDeletePlaylistDialog(
  BuildContext context, {
  required String playlistName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: const Text('حذف پلی‌لیست؟'),
      content: Text(
        'پلی‌لیست «$playlistName» برای همیشه حذف می‌شود. '
        'این کار قابل بازگشت نیست.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Opens the create/edit playlist sheet. Returns the saved playlist, or `null`
/// when the user dismissed the sheet.
Future<Playlist?> showPlaylistFormSheet(
  BuildContext context, {
  Playlist? initial,
}) {
  return showModalBottomSheet<Playlist>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => PlaylistFormSheet(initial: initial),
  );
}

/// Create/edit form for a playlist. Performs the provider call itself so the
/// sheet can keep the user's input visible when the request fails.
class PlaylistFormSheet extends StatefulWidget {
  const PlaylistFormSheet({super.key, this.initial});

  final Playlist? initial;

  @override
  State<PlaylistFormSheet> createState() => _PlaylistFormSheetState();
}

class _PlaylistFormSheetState extends State<PlaylistFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.initial?.description ?? '');
  late bool _isPublic = widget.initial?.isPublic ?? false;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'نام پلی‌لیست را وارد کنید.';
    if (text.length < 2) return 'نام باید حداقل ۲ کاراکتر باشد.';
    if (text.length > 60) return 'نام نباید بیش از ۶۰ کاراکتر باشد.';
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 280) return 'توضیحات نباید بیش از ۲۸۰ کاراکتر باشد.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final library = context.read<LibraryProvider>();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final initial = widget.initial;
      final saved = initial == null
          ? await library.createPlaylist(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isPublic: _isPublic,
            )
          : await library.updatePlaylist(
              id: initial.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isPublic: _isPublic,
            );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error =
            library.actionError ??
            'ذخیره پلی‌لیست انجام نشد. دوباره تلاش کنید.';
      });
      library.clearActionError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.edit_rounded
                          : Icons.playlist_add_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _isEditing ? 'ویرایش پلی‌لیست' : 'پلی‌لیست جدید',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'نام و توضیحات پلی‌لیست را تغییر دهید'
                              : 'آهنگ‌های محبوبت را یک‌جا جمع کن',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'نام پلی‌لیست',
                  hintText: 'مثلاً شب‌های آرام',
                  prefixIcon: Icon(Icons.queue_music_rounded),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                maxLength: 280,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'توضیحات (اختیاری)',
                  hintText: 'درباره این پلی‌لیست بنویس…',
                  alignLabelWithHint: true,
                ),
                validator: _validateDescription,
              ),
              const SizedBox(height: 4),
              Material(
                color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  value: _isPublic,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _isPublic = value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  secondary: Icon(
                    _isPublic
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                    color: _isPublic ? AppColors.accent : AppColors.textMuted,
                  ),
                  title: const Text('پلی‌لیست عمومی'),
                  subtitle: const Text(
                    'پلی‌لیست شما برای همه قابل مشاهده باشد',
                  ),
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'ذخیره تغییرات' : 'ساخت پلی‌لیست'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
