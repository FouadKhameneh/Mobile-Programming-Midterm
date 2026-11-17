import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import 'widgets/library_widgets.dart';

enum _DetailAction { edit, delete }

/// Full detail view for one playlist: hero header, track list, edit/delete and
/// playback commands. Pops with `true` when the playlist was deleted.
class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Playlist? _playlist;
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  String? _lastActionError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final library = context.read<LibraryProvider>();
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final detail = await library.getPlaylistDetail(widget.playlistId);
      if (!mounted) return;
      setState(() {
        _playlist = detail;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            library.actionError ??
            'بارگذاری پلی‌لیست انجام نشد. دوباره تلاش کنید.';
      });
      library.clearActionError();
    }
  }

  /// Merge the latest summary from the provider (name/count changes after edit)
  /// with the detailed track list we fetched for this screen.
  Playlist? _playlistForBuild(LibraryProvider library) {
    final local = _playlist;
    Playlist? summary;
    for (final item in library.playlists) {
      if (item.id == widget.playlistId) {
        summary = item;
        break;
      }
    }
    if (local == null) return summary;
    if (summary == null) return local;
    var trackCount = summary.trackCount;
    if (trackCount == 0 && local.tracks.isNotEmpty) {
      trackCount = local.tracks.length;
    }
    return local.copyWith(
      name: summary.name,
      description: summary.description,
      isPublic: summary.isPublic,
      trackCount: trackCount,
    );
  }

  void _handleActionError(LibraryProvider library) {
    final message = library.actionError;
    if (message == null) {
      _lastActionError = null;
      return;
    }
    if (message == _lastActionError) return;
    _lastActionError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      context.read<LibraryProvider>().clearActionError();
    });
  }

  Future<void> _refresh() async {
    final library = context.read<LibraryProvider>();
    await library.refresh();
    if (!mounted) return;
    final error = library.error;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await _load();
  }

  Future<void> _playAll(Playlist playlist) async {
    final tracks = playlist.tracks
        .map((ref) => ref.track)
        .toList(growable: false);
    if (tracks.isEmpty) return;
    await context.read<PlayerProvider>().playQueue(tracks, initialIndex: 0);
  }

  Future<void> _playTrackAt(Playlist playlist, int index) async {
    final tracks = playlist.tracks
        .map((ref) => ref.track)
        .toList(growable: false);
    if (tracks.isEmpty) return;
    var safeIndex = index;
    if (safeIndex < 0) safeIndex = 0;
    if (safeIndex >= tracks.length) safeIndex = tracks.length - 1;
    await context.read<PlayerProvider>().playQueue(
      tracks,
      initialIndex: safeIndex,
    );
  }

  Future<void> _shuffle(Playlist playlist) async {
    final tracks = playlist.tracks
        .map((ref) => ref.track)
        .toList(growable: false);
    if (tracks.isEmpty) return;
    final shuffled = List<Track>.of(tracks)..shuffle(math.Random());
    await context.read<PlayerProvider>().playQueue(shuffled, initialIndex: 0);
  }

  Future<void> _toggleFavorite(Track track) async {
    await context.read<LibraryProvider>().toggleFavorite(track);
  }

  Future<void> _removeTrack(Track track) async {
    final library = context.read<LibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await library.removeTrackFromPlaylist(
        playlistId: widget.playlistId,
        trackId: track.id,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            library.actionError ??
                'حذف آهنگ از پلی‌لیست انجام نشد. دوباره تلاش کنید.',
          ),
        ),
      );
      library.clearActionError();
      return;
    }
    if (!mounted) return;
    final current = _playlist;
    setState(() {
      if (current != null) {
        _playlist = current.copyWith(
          tracks: current.tracks
              .where((ref) => ref.track.id != track.id)
              .toList(growable: false),
          trackCount: current.trackCount > 0 ? current.trackCount - 1 : 0,
        );
      }
    });
    messenger.showSnackBar(
      SnackBar(content: Text('«${track.title}» از پلی‌لیست حذف شد.')),
    );
  }

  Future<void> _editPlaylist(Playlist playlist) async {
    final updated = await showPlaylistFormSheet(context, initial: playlist);
    if (updated == null || !mounted) return;
    final current = _playlist;
    setState(() {
      _playlist = (current ?? updated).copyWith(
        name: updated.name,
        description: updated.description,
        isPublic: updated.isPublic,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('پلی‌لیست «${updated.name}» ویرایش شد.')),
    );
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDeletePlaylistDialog(
      context,
      playlistName: playlist.name,
    );
    if (!confirmed || !mounted) return;
    final library = context.read<LibraryProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await library.deletePlaylist(playlist.id);
      if (!mounted) return;
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            library.actionError ?? 'حذف پلی‌لیست انجام نشد. دوباره تلاش کنید.',
          ),
        ),
      );
      library.clearActionError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    _handleActionError(library);
    final playlist = _playlistForBuild(library);
    final currentTrackId = context.select<PlayerProvider, String?>(
      (p) => p.currentTrack?.id,
    );
    final isPlaying = context.select<PlayerProvider, bool>((p) => p.playing);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _DetailTopBar(
                playlist: playlist,
                deleting: _deleting,
                onBack: () => Navigator.of(context).maybePop(),
                onEdit: playlist == null ? null : () => _editPlaylist(playlist),
                onDelete: playlist == null
                    ? null
                    : () => _deletePlaylist(playlist),
              ),
              if (_loading || _deleting)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _buildBody(playlist, library, currentTrackId, isPlaying),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    Playlist? playlist,
    LibraryProvider library,
    String? currentTrackId,
    bool isPlaying,
  ) {
    if (_loading && playlist == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (playlist == null) {
      return Center(
        child: SingleChildScrollView(
          child: LibraryErrorState(
            message: _error ?? 'پلی‌لیست پیدا نشد یا حذف شده است.',
            onRetry: _load,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _PlaylistHero(
              playlist: playlist,
              onPlay: () => _playAll(playlist),
              onShuffle: () => _shuffle(playlist),
            ),
          ),
          if (playlist.tracks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 30),
                child: LibraryEmptyState(
                  icon: Icons.music_off_rounded,
                  title: 'این پلی‌لیست هنوز آهنگی ندارد',
                  message:
                      'آهنگ‌های مورد علاقه‌ات را از بخش خانه یا جستجو پیدا کن '
                      'و به این پلی‌لیست اضافه کن.',
                  actionLabel: 'بازگشت به کتابخانه',
                  onAction: () => Navigator.of(context).maybePop(),
                ),
              ),
            )
          else ...<Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.queue_music_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'آهنگ‌های پلی‌لیست',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      pluralTracks(playlist.tracks.length),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              sliver: SliverList.builder(
                itemCount: playlist.tracks.length,
                itemBuilder: (context, index) {
                  final ref = playlist.tracks[index];
                  final track = ref.track;
                  final isCurrent = currentTrackId == track.id;
                  return LibraryTrackTile(
                    track: track,
                    position: (ref.position ?? index) + 1,
                    isFavorite: library.isFavorite(track.id),
                    favoriteBusy: library.isFavoriteBusy(track.id),
                    isCurrent: isCurrent,
                    isPlaying: isPlaying && isCurrent,
                    onTap: () => _playTrackAt(playlist, index),
                    onFavorite: () => _toggleFavorite(track),
                    onRemove: () => _removeTrack(track),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.playlist,
    required this.deleting,
    required this.onBack,
    this.onEdit,
    this.onDelete,
  });

  final Playlist? playlist;
  final bool deleting;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActions = onEdit != null && onDelete != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            tooltip: 'بازگشت',
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              playlist?.name ?? 'پلی‌لیست',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (hasActions)
            PopupMenuButton<_DetailAction>(
              enabled: !deleting,
              tooltip: 'گزینه‌های پلی‌لیست',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) {
                if (action == _DetailAction.edit) {
                  onEdit?.call();
                } else {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => const <PopupMenuEntry<_DetailAction>>[
                PopupMenuItem<_DetailAction>(
                  value: _DetailAction.edit,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.edit_rounded, size: 19),
                      SizedBox(width: 12),
                      Text('ویرایش پلی‌لیست'),
                    ],
                  ),
                ),
                PopupMenuItem<_DetailAction>(
                  value: _DetailAction.delete,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'حذف پلی‌لیست',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlaylistHero extends StatelessWidget {
  const _PlaylistHero({
    required this.playlist,
    required this.onPlay,
    required this.onShuffle,
  });

  final Playlist playlist;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = playlistGradientColors(playlist.id);
    final hasTracks = playlist.tracks.isNotEmpty;
    final description = playlist.description.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(palette[0], AppColors.surface, 0.35)!,
            Color.lerp(palette[1], AppColors.surface, 0.62)!,
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette[0].withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SizedBox(
              width: 150,
              height: 150,
              child: PlaylistCover(
                playlist: playlist,
                borderRadius: BorderRadius.circular(24),
                iconSize: 52,
                showCount: true,
                showPrivacy: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            playlist.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.65,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _HeroChip(
                icon: Icons.music_note_rounded,
                label: pluralTracks(playlist.trackCount),
              ),
              _HeroChip(
                icon: playlist.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_rounded,
                label: playlist.isPublic ? 'عمومی' : 'خصوصی',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasTracks ? onPlay : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text('پخش همه'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: hasTracks ? onShuffle : null,
                tooltip: 'پخش تصادفی',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.9),
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(54, 54),
                ),
                icon: const Icon(Icons.shuffle_rounded, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
