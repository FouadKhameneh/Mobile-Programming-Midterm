import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_colors.dart';

/// Album artwork with a graceful gradient/note fallback for missing or broken
/// remote images.
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.url,
    this.size = 56,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final String url;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final child = ClipRRect(
      borderRadius: radius,
      child: SizedBox.square(
        dimension: size,
        child: url.trim().isEmpty
            ? _Fallback(size: size)
            : CachedNetworkImage(
                imageUrl: url,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (context, url) => _Fallback(size: size),
                errorWidget: (context, url, error) => _Fallback(size: size),
              ),
      ),
    );
    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.coverFallback),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.38,
          color: Colors.white.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
