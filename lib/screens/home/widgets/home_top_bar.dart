import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';

/// Home greeting bar: avatar + greeting/name, a search shortcut and a
/// decorative notification bell.
///
/// The avatar intentionally renders the user's initials on a brand gradient
/// instead of a remote image, so the header never flashes or breaks.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.greeting,
    required this.name,
    required this.initial,
    this.onSearch,
    this.onNotifications,
  });

  final String greeting;
  final String name;
  final String initial;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        _AvatarBadge(initial: initial),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                greeting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: Icons.search_rounded,
          tooltip: 'جستجو',
          onPressed: onSearch,
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'اعلان‌ها',
          onPressed: onNotifications,
          showDot: true,
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.6),
          width: 1.6,
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.brandGradient,
        ),
        child: Center(
          child: Text(
            initial,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Material(
          color: AppColors.surfaceHigh.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: AppColors.textPrimary, size: 21),
            ),
          ),
        ),
        if (showDot)
          PositionedDirectional(
            top: 9,
            end: 11,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.4),
              ),
            ),
          ),
      ],
    );
  }
}
