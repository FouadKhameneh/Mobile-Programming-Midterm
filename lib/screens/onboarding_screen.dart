import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../state/settings_provider.dart';
import 'auth/widgets/brand_ui.dart';

/// Three-step RTL onboarding shown on first launch.
///
/// The first-launch gate lives in `AppRoot`; finishing (or skipping) marks
/// onboarding as seen through [SettingsProvider.completeOnboarding].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      kicker: 'جست‌وجو',
      title: 'هر آهنگ، در یک لحظه',
      description:
          'نتایج همزمان با تایپ می‌رسند؛ بین آهنگ‌ها، هنرمندان و آلبوم‌ها جست‌وجو کن و همان لحظه پخش را شروع کن.',
    ),
    _SlideData(
      kicker: 'امنیت',
      title: 'حساب تو، امن و آرام',
      description:
          'ورود بیومتریک، ذخیره امن توکن‌ها و نشست‌های محافظت‌شده؛ خیالت از حساب Soundify راحت باشد.',
    ),
    _SlideData(
      kicker: 'پخش',
      title: 'موسیقی، هیچ‌وقت قطع نمی‌شود',
      description:
          'با قفل شدن صفحه یا عوض کردن اپ، پخش ادامه دارد؛ از اعلان هم می‌توانی آهنگ را جلو و عقب ببری.',
    ),
  ];

  final PageController _pageController = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await context.read<SettingsProvider>().completeOnboarding();
    } catch (_) {
      // Preferences failures must never trap the user on onboarding.
    }
    if (!mounted) return;
    widget.onFinished?.call();
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Theme(
      data: soundifyBrandTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BrandBackdrop(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: <Widget>[
                      const BrandMark(size: 36, glow: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Soundify',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: const Text('رد کردن'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (int index) => setState(() => _index = index),
                    itemBuilder: (BuildContext context, int index) {
                      return _OnboardingSlide(
                        data: _slides[index],
                        index: index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
                  child: Column(
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '${toPersianDigits(_index + 1)} از ${toPersianDigits(_slides.length)}',
                          key: ValueKey<int>(_index),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            letterSpacing: 1.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(_slides.length, (int i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            height: 7,
                            width: active ? 28 : 8,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: active ? AppColors.brandGradient : null,
                              color: active
                                  ? null
                                  : Colors.white.withValues(alpha: 0.16),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 26),
                      GradientButton(
                        label: isLast ? 'شروع کن' : 'بعدی',
                        icon: isLast
                            ? Icons.play_arrow_rounded
                            : Icons.chevron_left_rounded,
                        onPressed: _finishing ? null : _next,
                      ),
                    ],
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

class _SlideData {
  const _SlideData({
    required this.kicker,
    required this.title,
    required this.description,
  });

  final String kicker;
  final String title;
  final String description;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data, required this.index});

  final _SlideData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 344),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _Illustration(index: index),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            data.kicker,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.95,
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 334,
      height: 306,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 264,
            height: 264,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  AppColors.primaryDeep.withValues(alpha: 0.22),
                  AppColors.primaryDeep.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          switch (index) {
            0 => const _SearchIllustration(),
            1 => const _SecureIllustration(),
            _ => const _PlayerIllustration(),
          },
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 1 — streaming search
// -----------------------------------------------------------------------------

class _SearchIllustration extends StatelessWidget {
  const _SearchIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.rotate(
          angle: -0.03,
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 282,
              height: 258,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const _GradientIcon(icon: Icons.search_rounded, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 42,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(
                                Icons.graphic_eq_rounded,
                                size: 15,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'آهنگ، هنرمند، آلبوم…',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ResultRow(
                    title: 'نورِ ماه',
                    artist: 'آریا',
                    colors: <Color>[Color(0xFF7C3AED), Color(0xFFF472B6)],
                    playing: true,
                  ),
                  const SizedBox(height: 9),
                  const _ResultRow(
                    title: 'خیابان بارانی',
                    artist: 'سایه',
                    colors: <Color>[Color(0xFF0891B2), Color(0xFF67E8F9)],
                  ),
                  const SizedBox(height: 9),
                  const _ResultRow(
                    title: 'پرواز',
                    artist: 'نیلوفر',
                    colors: <Color>[Color(0xFFC026D3), Color(0xFF7C3AED)],
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: 2,
          right: 0,
          child: GentleFloat(
            child: GlassPill(
              icon: Icons.auto_awesome_rounded,
              label: 'جست‌وجوی زنده',
            ),
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          child: GentleFloat(
            phase: 0.3,
            child: GlassPill(icon: Icons.bolt_rounded, label: 'نتایج فوری'),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.artist,
    required this.colors,
    this.playing = false,
  });

  final String title;
  final String artist;
  final List<Color> colors;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  artist,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (playing)
            const SoundWaveBars(
              barCount: 3,
              height: 16,
              barWidth: 2.5,
              spacing: 2.5,
              color: AppColors.accent,
            )
          else
            const Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 2 — secure authentication
// -----------------------------------------------------------------------------

class _SecureIllustration extends StatelessWidget {
  const _SecureIllustration();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: <Widget>[
        _PulseRings(),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF7C3AED), Color(0xFFF472B6)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x667C3AED),
                blurRadius: 44,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SizedBox(
            width: 148,
            height: 148,
            child: Icon(
              Icons.fingerprint_rounded,
              size: 74,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          top: 22,
          right: 0,
          child: GentleFloat(
            child: GlassPill(
              icon: Icons.lock_outline_rounded,
              label: 'توکن امن',
            ),
          ),
        ),
        Positioned(
          top: 62,
          left: 0,
          child: GentleFloat(
            phase: 0.25,
            child: GlassPill(
              icon: Icons.fingerprint_rounded,
              label: 'ورود بیومتریک',
              color: AppColors.pink,
            ),
          ),
        ),
        Positioned(
          bottom: 26,
          child: GentleFloat(
            phase: 0.55,
            child: GlassPill(
              icon: Icons.shield_outlined,
              label: 'نشست محافظت‌شده',
              color: AppColors.mint,
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseRings extends StatefulWidget {
  const _PulseRings();

  @override
  State<_PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<_PulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: List<Widget>.generate(3, (int index) {
              final progress = (_controller.value + index / 3) % 1;
              final size = 118 + 106 * progress;
              final opacity = (1 - progress) * 0.38;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: opacity),
                    width: 1.4,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 3 — background playback
// -----------------------------------------------------------------------------

class _PlayerIllustration extends StatelessWidget {
  const _PlayerIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const Positioned(
          top: 4,
          left: 6,
          child: GentleFloat(child: _NotificationCard()),
        ),
        Positioned(
          bottom: 4,
          right: 0,
          child: Transform.rotate(
            angle: 0.02,
            child: GlassCard(
              radius: 26,
              padding: const EdgeInsets.all(15),
              child: SizedBox(
                width: 248,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF7C3AED),
                                Color(0xFFC026D3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'پرواز',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'نیلوفر',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 10.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryDeep,
                          ),
                          child: const Icon(
                            Icons.pause_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.42,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: <Widget>[
                        Text(
                          '۱:۲۴',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '۳:۰۶',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 120,
          left: 2,
          child: GentleFloat(
            phase: 0.4,
            child: GlassPill(
              icon: Icons.notifications_active_outlined,
              label: 'کنترل از اعلان',
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.warmGradient,
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Soundify',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'در حال پخش • پرواز',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SoundWaveBars(
            barCount: 4,
            height: 18,
            barWidth: 2.5,
            spacing: 2.5,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared bits
// -----------------------------------------------------------------------------

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryDeep, Color(0xFFC026D3)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: Colors.white),
    );
  }
}
