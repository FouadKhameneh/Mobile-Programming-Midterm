import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/track.dart';
import '../../state/auth_provider.dart';
import '../../state/catalog_provider.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import '../../widgets/app_widgets.dart';
import '../search/search_screen.dart';
import 'widgets/artist_chips.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/track_actions.dart';
import 'widgets/track_row.dart';

/// Home tab: greeting header, featured carousel, artist shortcuts and the
/// recently added tracks list.
///
/// Everything is driven by [CatalogProvider] (network data) and reads
/// [AuthProvider]/[LibraryProvider]/[PlayerProvider] for personalization.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenNotifications,
  });

  /// When the shell provides a search tab switch it can pass this callback;
  /// otherwise the screen pushes [SearchScreen] itself.
  final VoidCallback? onOpenSearch;

  /// Optional notifications hook (decorative by default).
  final VoidCallback? onOpenNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _headerElevated = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final elevated =
        _scrollController.hasClients && _scrollController.offset > 12;
    if (elevated != _headerElevated) {
      setState(() => _headerElevated = elevated);
    }
  }

  void _bootstrap() {
    if (!mounted) return;
    final catalog = context.read<CatalogProvider>();
    if (!catalog.loaded && !catalog.loading) {
      catalog.load();
    }
  }

  Future<void> _refresh() async {
    final catalog = context.read<CatalogProvider>();
    await catalog.refresh();
    if (!mounted) return;
    final error = catalog.error;
    if (error != null) {
      showAppSnack(context, error, error: true);
    }
  }

  void _retry() {
    context.read<CatalogProvider>().load(force: true);
  }

  void _openSearch({String? initialQuery}) {
    if (initialQuery == null && widget.onOpenSearch != null) {
      widget.onOpenSearch!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            SearchScreen(initialQuery: initialQuery),
      ),
    );
  }

  Future<void> _playFeatured(int index) async {
    final catalog = context.read<CatalogProvider>();
    final featured = catalog.featured;
    if (index < 0 || index >= featured.length) return;
    final Track track = featured[index];
    final tracks = catalog.tracks;
    final trackIndex = tracks.indexWhere((Track t) => t.id == track.id);
    if (trackIndex >= 0) {
      await playQueueWithFeedback(context, tracks, initialIndex: trackIndex);
    } else {
      await playQueueWithFeedback(context, featured, initialIndex: index);
    }
  }

  Future<void> _playRecent(Track track) async {
    final catalog = context.read<CatalogProvider>();
    final queue =
        catalog.tracks.isNotEmpty ? catalog.tracks : catalog.recentlyAdded;
    if (queue.isEmpty) return;
    final index = queue.indexWhere((Track t) => t.id == track.id);
    await playQueueWithFeedback(
      context,
      queue,
      initialIndex: index < 0 ? 0 : index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final library = context.watch<LibraryProvider>();
    final currentTrackId =
        context.select<PlayerProvider, String?>((p) => p.currentTrack?.id);

    final hasContent = catalog.tracks.isNotEmpty || catalog.featured.isNotEmpty;
    final showSkeleton = !hasContent &&
        catalog.error == null &&
        (!catalog.loaded || catalog.loading);
    final showError =
        !hasContent && catalog.error != null && !catalog.loading;
    final showEmpty = !hasContent && !showSkeleton && !showError;

    final user = auth.user;
    final greeting = greetingForHour(DateTime.now().hour);
    final name = user?.name ?? 'دوست عزیز';
    final initial = user?.initials ?? 'S';
    final recentlyAdded = catalog.recentlyAdded;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: <Widget>[
            const _HomeBackdrop(),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceHigh,
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HomeHeaderDelegate(
                        elevated: _headerElevated,
                        child: HomeTopBar(
                          greeting: greeting,
                          name: name,
                          initial: initial,
                          onSearch: () => _openSearch(),
                          onNotifications: widget.onOpenNotifications ??
                              () => showAppSnack(
                                    context,
                                    'اعلان جدیدی ندارید.',
                                  ),
                        ),
                      ),
                    ),
                    if (catalog.error != null && hasContent)
                      SliverToBoxAdapter(
                        child: _InlineErrorBanner(
                          message: catalog.error!,
                          onRetry: _refresh,
                        ),
                      ),
                    if (showSkeleton)
                      const SliverToBoxAdapter(child: HomeSkeleton())
                    else if (showError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ErrorState(
                          message: catalog.error!,
                          onRetry: _retry,
                        ),
                      )
                    else if (showEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          title: 'هنوز آهنگی موجود نیست',
                          subtitle:
                              'کاتالوگ فعلاً خالی است. برای دریافت دوباره، پایین بکشید یا تلاش کنید.',
                          icon: Icons.library_music_outlined,
                          actionLabel: 'به‌روزرسانی',
                          onAction: _refresh,
                        ),
                      )
                    else ...<Widget>[
                      if (catalog.featured.isNotEmpty) ...<Widget>[
                        const SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'پیشنهاد ویژه',
                            subtitle: 'منتخب سردبیر برای امروز',
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FeaturedCarousel(
                            tracks: catalog.featured,
                            onPlay: _playFeatured,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 22)),
                      ],
                      if (catalog.artists.isNotEmpty) ...<Widget>[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'هنرمندان',
                            subtitle: 'بر اساس آهنگ‌های کاتالوگ',
                            actionLabel: 'همه',
                            onAction: () => _openSearch(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: ArtistChips(
                            artists: catalog.artists,
                            onSelected: (String artist) =>
                                _openSearch(initialQuery: artist),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 22)),
                      ],
                      if (recentlyAdded.isNotEmpty) ...<Widget>[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'تازه‌ها',
                            subtitle: 'جدیدترین آهنگ‌های سرویس',
                            actionLabel: 'مشاهده همه',
                            onAction: () => _openSearch(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList.builder(
                            itemCount: recentlyAdded.length,
                            itemBuilder: (BuildContext context, int index) {
                              final track = recentlyAdded[index];
                              final isCurrent = currentTrackId == track.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TrackRow(
                                  track: track,
                                  isFavorite:
                                      library.isFavorite(track.id),
                                  favoriteBusy:
                                      library.isFavoriteBusy(track.id),
                                  isPlaying: isCurrent,
                                  onTap: () {
                                    if (isCurrent) {
                                      context
                                          .read<PlayerProvider>()
                                          .togglePlayPause();
                                    } else {
                                      _playRecent(track);
                                    }
                                  },
                                  onFavorite: () =>
                                      toggleFavoriteWithFeedback(
                                          context, track),
                                  onMore: () =>
                                      showAddToPlaylistSheet(context, track),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.danger,
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.6,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'تلاش دوباره',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky greeting bar. It becomes a slightly opaque "glass" strip once the
/// content scrolls underneath, keeping the search shortcut within reach.
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.child,
    required this.elevated,
  });

  final Widget child;
  final bool elevated;

  static const double _extent = 76;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: elevated
            ? AppColors.background.withValues(alpha: 0.92)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: elevated
                ? AppColors.outline.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Center(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.elevated != elevated || oldDelegate.child != child;
  }
}

/// Soft radial brand glows behind the content.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          PositionedDirectional(
            top: -130,
            end: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.primaryDeep.withValues(alpha: 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 260,
            start: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.accent.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
