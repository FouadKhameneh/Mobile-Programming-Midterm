import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A tiny animated equalizer used as a "now playing" indicator.
///
/// The bars are driven by a single [AnimationController] (no external
/// dependency) and freeze into a compact idle shape when [playing] is false.
/// The animation automatically respects the platform "reduce motion"
/// accessibility flag.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    this.playing = true,
    this.color,
    this.barCount = 4,
    this.height = 18,
    this.barWidth = 3,
    this.gap = 3,
  }) : assert(barCount > 0, 'barCount must be positive');

  /// Whether the bars should animate (true while audio is playing).
  final bool playing;

  /// Bar color; defaults to the theme primary color.
  final Color? color;

  /// Number of bars.
  final int barCount;

  /// Total height of the widget (the tallest possible bar).
  final double height;

  /// Width of a single bar.
  final double barWidth;

  /// Horizontal space between bars.
  final double gap;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _reduceMotion = false;

  bool get _animating => widget.playing && !_reduceMotion;

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _syncAnimation();
  }

  void _syncAnimation() {
    if (_animating) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: widget.playing ? 'در حال پخش' : 'متوقف',
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var i = 0; i < widget.barCount; i++)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: i == 0 ? 0 : widget.gap,
                    ),
                    child: _Bar(
                      width: widget.barWidth,
                      height: (widget.height * _factorFor(i))
                          .clamp(2.0, widget.height)
                          .toDouble(),
                      color: color,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _factorFor(int index) {
    if (!_animating) {
      // Frozen, slightly uneven "paused" shape.
      return 0.2 + 0.07 * ((index * 5) % 4);
    }
    final phase = _controller.value + index * 0.19;
    final wave = 0.5 + 0.5 * math.sin(2 * math.pi * phase);
    return 0.22 + 0.78 * wave;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
