import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/track.dart';

/// Hero tag shared by the mini player artwork and the full player artwork so
/// pushing the full player animates the cover smoothly.
const String playerArtworkHeroTag = 'soundify-player-artwork';

/// Resolves a (possibly relative) media URL returned by the API into an
/// absolute URL suitable for `CachedNetworkImage` / notification artwork.
///
/// Returns an empty string when [raw] cannot be parsed.
String resolveMediaUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return '';
  if (uri.hasScheme) return uri.toString();
  try {
    return Uri.parse(AppConfig.apiHost).resolveUri(uri).toString();
  } catch (_) {
    return '';
  }
}

/// A rounded cover artwork image with a graceful gradient fallback and an
/// optional gaussian blur (used for the full player's ambient background).
class PlayerArtwork extends StatelessWidget {
  const PlayerArtwork({
    super.key,
    required this.track,
    this.size,
    this.borderRadius = 24,
    this.blurSigma = 0,
    this.fit = BoxFit.cover,
    this.useHero = false,
    this.fallbackIconSize = 32,
  });

  final Track? track;
  final double? size;
  final double borderRadius;
  final double blurSigma;
  final BoxFit fit;
  final bool useHero;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = _ArtworkFallback(iconSize: fallbackIconSize);
    final url = track == null ? '' : resolveMediaUrl(track!.coverUrl);

    Widget content;
    if (url.isEmpty) {
      content = fallback;
    } else {
      content = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 260),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      );
    }

    if (blurSigma > 0) {
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      );
    }

    if (borderRadius > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    if (size != null) {
      content = SizedBox(width: size, height: size, child: content);
    }

    if (!useHero) return content;
    return Hero(tag: playerArtworkHeroTag, child: content);
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.coverFallback),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
