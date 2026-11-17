import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/track.dart';
import '../../state/catalog_provider.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import '../../state/search_provider.dart';
import '../../widgets/app_widgets.dart';
import '../home/widgets/artist_chips.dart';
import '../home/widgets/home_skeleton.dart';
import '../home/widgets/track_actions.dart';
import '../home/widgets/track_row.dart';

/// Search tab / pushed search screen.
///
/// The provider owns the debounce, so every keystroke only calls
/// [SearchProvider.search]; submitting the keyboard (or tapping a suggestion)
/// calls [SearchProvider.submit] to force an immediate request and remember the
/// query in the recent searches.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  /// Pre-fills the field and runs an immediate search (used by Home artist
  /// shortcuts and the "see all" affordances).
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialQuery?.trim() ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _bootstrap() {
    if (!mounted) return;
    final catalog = context.read<CatalogProvider>();
    if (!catalog.loaded && !catalog.loading) {
      catalog.load();
    }
    final initial = _controller.text.trim();
    if (initial.isNotEmpty) {
      context.read<SearchProvider>().submit(initial);
    }
  }

  void _applyQuery(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
    _focusNode.unfocus();
    context.read<SearchProvider>().submit(text);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {});
    _focusNode.unfocus();
    context.read<SearchProvider>().clear();
  }

  void _retry() {
    final text = _controller.text.trim().isNotEmpty
        ? _controller.text.trim()
        : context.read<SearchProvider>().query;
    if (text.isEmpty) {
      _bootstrap();
      return;
    }
    context.read<SearchProvider>().submit(text);
  }

  Future<void> _playResult(int index) async {
    final results = context.read<SearchProvider>().results;
    if (index < 0 || index >= results.length) return;
    await playQueueWithFeedback(context, results, initialIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final catalog = context.watch<CatalogProvider>();
    final library = context.watch<LibraryProvider>();
    final currentTrackId =
        context.select<PlayerProvider, String?>((p) => p.currentTrack?.id);
    final canPop = Navigator.of(context).canPop();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: <Widget>[
            const _SearchBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: <Widget>[
                        if (canPop) ...<Widget>[
                          _BackButton(onPressed: () => Navigator.maybePop(context)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: _buildSearchField()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildContent(
                      search: search,
                      catalog: catalog,
                      library: library,
                      currentTrackId: currentTrackId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final hasText = _controller.text.trim().isNotEmpty;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      textDirection: TextDirection.rtl,
      onChanged: (String value) {
        setState(() {});
        context.read<SearchProvider>().search(value);
      },
      onSubmitted: (String value) {
        final text = value.trim();
        if (text.isEmpty) return;
        _focusNode.unfocus();
        context.read<SearchProvider>().submit(text);
      },
      style: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 14,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'جستجوی آهنگ، هنرمند یا آلبوم...',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
        suffixIcon: hasText
            ? IconButton(
                onPressed: _clearSearch,
                tooltip: 'پاک کردن',
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
      ),
    );
  }

  Widget _buildContent({
    required SearchProvider search,
    required CatalogProvider catalog,
    required LibraryProvider library,
    required String? currentTrackId,
  }) {
    if (search.loading && search.results.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: const <Widget>[TrackRowsSkeleton(count: 6)],
      );
    }
    if (search.error != null && !search.loading) {
      return ErrorState(message: search.error!, onRetry: _retry);
    }
    if (!search.hasSearched) {
      return _buildDiscover(search, catalog);
    }
    if (search.results.isEmpty) {
      return EmptyState(
        title: 'نتیجه‌ای پیدا نشد',
        subtitle: search.query.isEmpty
            ? 'واژهٔ دیگری را امتحان کنید.'
            : 'برای «${search.query}» آهنگی پیدا نکردیم. واژهٔ دیگری را امتحان کنید.',
        icon: Icons.search_off_rounded,
        actionLabel: 'پاک کردن جستجو',
        onAction: _clearSearch,
      );
    }
    return _buildResults(
      search: search,
      library: library,
      currentTrackId: currentTrackId,
    );
  }

  Widget _buildResults({
    required SearchProvider search,
    required LibraryProvider library,
    required String? currentTrackId,
  }) {
    final results = search.results;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${toPersianDigits(results.length)} نتیجه برای «${search.query}»',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final Track track = results[index];
              final isCurrent = currentTrackId == track.id;
              return TrackRow(
                track: track,
                isFavorite: library.isFavorite(track.id),
                favoriteBusy: library.isFavoriteBusy(track.id),
                isPlaying: isCurrent,
                onTap: () {
                  if (isCurrent) {
                    context.read<PlayerProvider>().togglePlayPause();
                  } else {
                    _playResult(index);
                  }
                },
                onFavorite: () =>
                    toggleFavoriteWithFeedback(context, track),
                onMore: () => showAddToPlaylistSheet(context, track),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscover(SearchProvider search, CatalogProvider catalog) {
    final recents = search.recentSearches;
    final artists = catalog.artists;
    final artistsLoading = artists.isEmpty && catalog.loading;
    final isEmpty = recents.isEmpty && artists.isEmpty && !artistsLoading;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      children: <Widget>[
        if (recents.isNotEmpty) ...<Widget>[
          const SectionHeader(
            title: 'جستجوهای اخیر',
            padding: EdgeInsets.zero,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recents
                .map((String value) => _recentChip(value))
                .toList(growable: false),
          ),
          const SizedBox(height: 22),
        ],
        if (artists.isNotEmpty) ...<Widget>[
          const SectionHeader(
            title: 'هنرمندان پرطرفدار',
            padding: EdgeInsets.zero,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: artists
                .map(
                  (String artist) => ArtistChip(
                    name: artist,
                    onTap: () => _applyQuery(artist),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 22),
        ] else if (artistsLoading) ...<Widget>[
          const SectionHeader(
            title: 'هنرمندان پرطرفدار',
            padding: EdgeInsets.zero,
          ),
          const SkeletonPulse(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SkeletonBox(height: 36, width: 96, radius: 999),
                SkeletonBox(height: 36, width: 88, radius: 999),
                SkeletonBox(height: 36, width: 104, radius: 999),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (isEmpty)
          const EmptyState(
            title: 'جستجو را شروع کنید',
            subtitle:
                'نام آهنگ، هنرمند یا آلبومی را بنویسید تا نتایج را ببینید.',
            icon: Icons.manage_search_rounded,
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'برای جستجو، واژه‌ای تایپ کنید یا یکی از پیشنهادها را بزنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  height: 1.7,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentChip(String value) {
    return InputChip(
      label: Text(value),
      avatar: const Icon(
        Icons.history_rounded,
        size: 16,
        color: AppColors.textMuted,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 12,
        color: AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.55),
      side: BorderSide(color: AppColors.outline.withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      visualDensity: VisualDensity.compact,
      onPressed: () => _applyQuery(value),
      onDeleted: () => context.read<SearchProvider>().removeRecent(value),
      deleteIcon: const Icon(Icons.close_rounded, size: 15),
      deleteIconColor: AppColors.textMuted,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.textPrimary,
            size: 21,
          ),
        ),
      ),
    );
  }
}

/// Soft brand glow behind the search screen.
class _SearchBackdrop extends StatelessWidget {
  const _SearchBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          PositionedDirectional(
            top: -140,
            end: -90,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.primaryDeep.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -160,
            start: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.accent.withValues(alpha: 0.09),
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
