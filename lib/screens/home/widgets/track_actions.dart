import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/playlist.dart';
import '../../../models/track.dart';
import '../../../state/library_provider.dart';
import '../../../state/player_provider.dart';
import '../../../widgets/app_widgets.dart';

String _messageFor(Object error) =>
    error is ApiException && error.message.trim().isNotEmpty
        ? error.message
        : 'مشکلی پیش آمد. دوباره تلاش کنید.';

/// Starts a queue and surfaces playback failures through a SnackBar.
///
/// [PlayerProvider] never throws into the widget tree; it records the failure
/// in `error`, so it is read and cleared here for exactly-once feedback.
Future<void> playQueueWithFeedback(
  BuildContext context,
  List<Track> queue, {
  int initialIndex = 0,
}) async {
  final player = context.read<PlayerProvider>();
  await player.playQueue(queue, initialIndex: initialIndex);
  if (!context.mounted) return;
  final error = player.error;
  if (error != null) {
    showAppSnack(context, error, error: true);
    player.clearError();
  }
}

/// Toggles a favorite. [LibraryProvider] applies the change optimistically and
/// records failures in `actionError`, so surface that as a SnackBar afterwards.
Future<void> toggleFavoriteWithFeedback(BuildContext context, Track track) async {
  final library = context.read<LibraryProvider>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  await library.toggleFavorite(track);
  final actionError = library.actionError;
  if (actionError != null && messenger != null) {
    messenger.showSnackBar(SnackBar(content: Text(actionError)));
    library.clearActionError();
  }
}

/// Opens the "add to playlist" bottom sheet and adds the track to the chosen
/// playlist. When the library has no playlists yet, shows a helpful hint
/// instead of an empty sheet.
Future<void> showAddToPlaylistSheet(BuildContext context, Track track) async {
  final library = context.read<LibraryProvider>();
  final playlists = List<Playlist>.of(library.playlists);

  if (playlists.isEmpty) {
    showAppSnack(
      context,
      'هنوز پلی‌لیستی نساخته‌اید. از بخش کتابخانه یک پلی‌لیست بسازید.',
    );
    return;
  }

  final Playlist? selected = await showModalBottomSheet<Playlist>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return _AddToPlaylistSheet(track: track, playlists: playlists);
    },
  );
  if (selected == null || !context.mounted) return;

  try {
    await library.addTrackToPlaylist(selected.id, track);
    if (!context.mounted) return;
    showAppSnack(context, '«${track.title}» به «${selected.name}» اضافه شد.');
  } catch (error) {
    if (!context.mounted) return;
    showAppSnack(context, _messageFor(error), error: true);
  }
}

class _AddToPlaylistSheet extends StatelessWidget {
  const _AddToPlaylistSheet({required this.track, required this.playlists});

  final Track track;
  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: const Icon(
                    Icons.playlist_add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'افزودن به پلی‌لیست',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: playlists.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (BuildContext context, int index) {
                  final playlist = playlists[index];
                  return _PlaylistTile(
                    playlist: playlist,
                    onTap: () => Navigator.of(context).pop(playlist),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceHigh.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pluralTracks(playlist.trackCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
