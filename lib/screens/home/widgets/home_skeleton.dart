import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';

/// Gentle pulse applied to every skeleton placeholder on a screen.
///
/// One animation controller drives the whole skeleton tree, which keeps the
/// loading state cheap while the catalog request is in flight.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 0.8)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// A single rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder rows that mimic [TrackRow] while the catalog loads.
class TrackRowsSkeleton extends StatelessWidget {
  const TrackRowsSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          count,
          (int index) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                const SkeletonBox(width: 52, height: 52, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SkeletonBox(height: 13, width: 148),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        height: 10,
                        width: index.isEven ? 104 : 128,
                      ),
                    ],
                  ),
                ),
                const SkeletonBox(width: 22, height: 22, radius: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home-specific skeleton: hero card, artist pills and the recent list.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SkeletonBox(height: 18, width: 130),
            SizedBox(height: 14),
            SkeletonBox(height: 226, radius: 26),
            SizedBox(height: 24),
            SkeletonBox(height: 18, width: 90),
            SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SkeletonBox(height: 36, width: 96, radius: 999),
                SkeletonBox(height: 36, width: 88, radius: 999),
                SkeletonBox(height: 36, width: 104, radius: 999),
              ],
            ),
            SizedBox(height: 24),
            SkeletonBox(height: 18, width: 110),
            SizedBox(height: 12),
            TrackRowsSkeleton(count: 4),
          ],
        ),
      ),
    );
  }
}
