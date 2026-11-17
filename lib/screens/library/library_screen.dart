import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import 'playlist_detail_screen.dart';
import 'widgets/library_widgets.dart';

/// The "کتابخانه من" tab: playlists grid plus the favourites list.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  String? _lastActionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryProvider>().loadLibrary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Surfaces provider-side action failures (favourite sync, delete, ...) once
  /// per message and clears them afterwards.
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
    }
  }

  Future<void> _openPlaylist(String playlistId) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => PlaylistDetailScreen(playlistId: playlistId),
      ),
    );
    if (!mounted) return;
    if (deleted == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('پلی‌لیست حذف شد.')));
    }
  }

  Future<void> _openCreatePlaylist() async {
    final created = await showPlaylistFormSheet(context);
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('پلی‌لیست «${created.name}» ساخته شد.'),
        action: SnackBarAction(
          label: 'مشاهده',
          onPressed: () => _openPlaylist(created.id),
        ),
      ),
    );
  }

  Future<void> _showPlaylistActions(Playlist playlist) async {
    final action = await showPlaylistActionsSheet(context, playlist: playlist);
    if (action == null || !mounted) return;
    if (action == PlaylistAction.edit) {
      await _editPlaylist(playlist);
    } else {
      await _deletePlaylist(playlist);
    }
  }

  Future<void> _editPlaylist(Playlist playlist) async {
    final updated = await showPlaylistFormSheet(context, initial: playlist);
    if (updated == null || !mounted) return;
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await library.deletePlaylist(playlist.id);
      messenger.showSnackBar(
        SnackBar(content: Text('پلی‌لیست «${playlist.name}» حذف شد.')),
      );
    } catch (_) {
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

  Future<void> _toggleFavorite(Track track) async {
    await context.read<LibraryProvider>().toggleFavorite(track);
  }

  Future<void> _playFavoritesAt(int index) async {
    final library = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();
    final tracks = List<Track>.of(library.favorites);
    if (tracks.isEmpty) return;
    await player.playQueue(tracks, initialIndex: index);
  }

  Future<void> _playAllFavorites() async {
    final library = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();
    final tracks = List<Track>.of(library.favorites);
    if (tracks.isEmpty) return;
    await player.playQueue(tracks, initialIndex: 0);
  }

  Future<void> _shuffleFavorites() async {
    final library = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();
    final tracks = List<Track>.of(library.favorites);
    if (tracks.isEmpty) return;
    tracks.shuffle(math.Random());
    await player.playQueue(tracks, initialIndex: 0);
  }

  void _showExploreHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'آهنگ‌های مورد علاقه را از صفحه خانه یا جستجو اضافه کنید.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    _handleActionError(library);
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
              _LibraryHeader(
                playlistCount: library.playlistCount,
                favoriteCount: library.favoriteCount,
                loading: library.loading,
                onCreate: _openCreatePlaylist,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: _buildTabBar(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: <Widget>[
                    _PlaylistsTab(
                      library: library,
                      onOpen: _openPlaylist,
                      onActions: _showPlaylistActions,
                      onCreate: _openCreatePlaylist,
                      onRefresh: _refresh,
                    ),
                    _FavoritesTab(
                      library: library,
                      currentTrackId: currentTrackId,
                      isPlaying: isPlaying,
                      onToggleFavorite: _toggleFavorite,
                      onPlayTrack: _playFavoritesAt,
                      onPlayAll: _playAllFavorites,
                      onShuffle: _shuffleFavorites,
                      onExplore: _showExploreHint,
                      onRefresh: _refresh,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.55)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(12),
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const <Widget>[
          Tab(height: 40, text: 'پلی‌لیست‌ها'),
          Tab(height: 40, text: 'علاقه‌مندی‌ها'),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.playlistCount,
    required this.favoriteCount,
    required this.loading,
    required this.onCreate,
  });

  final int playlistCount;
  final int favoriteCount;
  final bool loading;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'کتابخانه من',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${pluralPlaylists(playlistCount)} · '
                  '${toPersianDigits(favoriteCount)} علاقه‌مندی',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CreatePlaylistButton(onTap: onCreate),
        ],
      ),
    );
  }
}

class _CreatePlaylistButton extends StatelessWidget {
  const _CreatePlaylistButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'پلی‌لیست جدید',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({
    required this.library,
    required this.onOpen,
    required this.onActions,
    required this.onCreate,
    required this.onRefresh,
  });

  final LibraryProvider library;
  final ValueChanged<String> onOpen;
  final ValueChanged<Playlist> onActions;
  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      edgeOffset: 6,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          if (library.loading && library.playlists.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            sliver: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (library.playlists.isEmpty) {
      if (library.loading) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: LibraryLoadingState(),
          ),
        );
      }
      if (library.error != null) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: LibraryErrorState(
              message: library.error!,
              onRetry: () => library.loadLibrary(force: true),
            ),
          ),
        );
      }
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: LibraryEmptyState(
            icon: Icons.queue_music_rounded,
            title: 'هنوز پلی‌لیستی نساخته‌اید',
            message:
                'اولین پلی‌لیست خود را بسازید تا آهنگ‌های محبوبتان را '
                'در یک‌جا جمع کنید.',
            actionLabel: 'ساخت پلی‌لیست',
            onAction: onCreate,
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final playlist = library.playlists[index];
        return _PlaylistCard(
          playlist: playlist,
          onTap: () => onOpen(playlist.id),
          onActions: () => onActions(playlist),
        );
      }, childCount: library.playlists.length),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onActions,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onActions,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    PlaylistCover(
                      playlist: playlist,
                      borderRadius: BorderRadius.circular(16),
                      iconSize: 40,
                      showPrivacy: true,
                      showCount: true,
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _CardMenuButton(onTap: onActions),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.music_note_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pluralTracks(playlist.trackCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.30),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({
    required this.library,
    required this.currentTrackId,
    required this.isPlaying,
    required this.onToggleFavorite,
    required this.onPlayTrack,
    required this.onPlayAll,
    required this.onShuffle,
    required this.onExplore,
    required this.onRefresh,
  });

  final LibraryProvider library;
  final String? currentTrackId;
  final bool isPlaying;
  final ValueChanged<Track> onToggleFavorite;
  final ValueChanged<int> onPlayTrack;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;
  final VoidCallback onExplore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final favorites = library.favorites;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      edgeOffset: 6,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          if (library.loading && favorites.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ),
          if (favorites.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyOrError(context))
          else ...<Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              sliver: SliverToBoxAdapter(
                child: _PlayAllCard(
                  count: favorites.length,
                  onPlayAll: onPlayAll,
                  onShuffle: onShuffle,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final track = favorites[index];
                  final isCurrent = currentTrackId == track.id;
                  return LibraryTrackTile(
                    track: track,
                    isFavorite: library.isFavorite(track.id),
                    favoriteBusy: library.isFavoriteBusy(track.id),
                    isCurrent: isCurrent,
                    isPlaying: isPlaying && isCurrent,
                    onTap: () => onPlayTrack(index),
                    onFavorite: () => onToggleFavorite(track),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOrError(BuildContext context) {
    if (library.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: LibraryLoadingState(),
      );
    }
    if (library.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: LibraryErrorState(
          message: library.error!,
          onRetry: () => library.loadLibrary(force: true),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: LibraryEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'هنوز علاقه‌مندی ندارید',
        message:
            'آهنگ‌هایی که دوست دارید را با قلب کنار هر آهنگ ذخیره کنید '
            'تا همیشه در دسترس باشند.',
        actionLabel: 'کاوش موسیقی',
        onAction: onExplore,
      ),
    );
  }
}

class _PlayAllCard extends StatelessWidget {
  const _PlayAllCard({
    required this.count,
    required this.onPlayAll,
    required this.onShuffle,
  });

  final int count;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF7C3AED), Color(0xFFC026D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'پخش همه علاقه‌مندی‌ها',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${pluralTracks(count)} در صف پخش',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onShuffle,
            tooltip: 'پخش تصادفی',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
            ),
            icon: const Icon(Icons.shuffle_rounded, size: 20),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPlayAll,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF7C3AED),
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
