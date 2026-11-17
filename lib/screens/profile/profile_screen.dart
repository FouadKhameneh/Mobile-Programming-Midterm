import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/services/device_security_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../state/auth_provider.dart';
import '../../state/library_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/profile_widgets.dart';

/// The "پروفایل" tab: identity, security/biometrics, appearance and account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DeviceSecurityService _deviceSecurity = DeviceSecurityService();

  DeviceSecurityReport? _securityReport;
  bool _securityLoading = true;
  String? _securityError;
  bool _biometricBusy = false;
  bool _logoutBusy = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityReport();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryProvider>().loadLibrary();
    });
  }

  Future<void> _loadSecurityReport() async {
    if (mounted) {
      setState(() {
        _securityLoading = true;
        _securityError = null;
      });
    }
    try {
      final report = await _deviceSecurity.inspect();
      if (!mounted) return;
      setState(() {
        _securityReport = report;
        _securityLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _securityLoading = false;
        _securityError = 'بررسی وضعیت امنیتی دستگاه انجام نشد.';
      });
    }
  }

  Future<void> _refreshAll() async {
    final auth = context.read<AuthProvider>();
    final library = context.read<LibraryProvider>();
    await Future.wait<void>(<Future<void>>[
      auth.refreshUser(),
      library.refresh(),
      _loadSecurityReport(),
    ]);
  }

  Future<void> _onBiometricChanged(bool enabled) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _biometricBusy = true);
    final error = await auth.setBiometricEnabled(enabled);
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (enabled
                  ? 'ورود بیومتریک فعال شد.'
                  : 'ورود بیومتریک غیرفعال شد.'),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text('خروج از حساب؟'),
        content: const Text(
          'برای استفاده دوباره از Soundify باید با ایمیل و رمز عبور وارد شوید.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    setState(() => _logoutBusy = true);
    await auth.logout();
    if (!mounted) return;
    setState(() => _logoutBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final library = context.watch<LibraryProvider>();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    user: auth.user,
                    playlistCount: library.playlistCount,
                    favoriteCount: library.favoriteCount,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ProfileSectionCard(
                    title: 'امنیت و حریم خصوصی',
                    icon: Icons.shield_rounded,
                    tint: AppColors.accent,
                    children: <Widget>[
                      SwitchListTile(
                        value: auth.biometricEnabled,
                        onChanged: _biometricBusy ? null : _onBiometricChanged,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 2,
                        ),
                        secondary: const ProfileTileIcon(
                          icon: Icons.fingerprint_rounded,
                          color: AppColors.accent,
                        ),
                        title: const Text('ورود بیومتریک'),
                        subtitle: Text(
                          _biometricBusy
                              ? 'در حال اعمال تغییر…'
                              : auth.biometricEnabled
                              ? 'فعال — هنگام ورود با اثر انگشت یا چهره تأیید می‌شوید'
                              : 'با اثر انگشت یا چهره سریع‌تر وارد شوید',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (!auth.biometricAvailable)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: _InfoBanner(
                            icon: Icons.info_outline_rounded,
                            color: AppColors.warning,
                            text:
                                'برای فعال‌سازی ورود بیومتریک باید اثر انگشت یا '
                                'چهره روی این دستگاه ثبت شده باشد.',
                          ),
                        ),
                      const Divider(height: 1, indent: 18, endIndent: 18),
                      _buildSecurityHeader(theme),
                      _buildSecurityContent(theme),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: ProfileSectionCard(
                    title: 'ظاهر برنامه',
                    icon: Icons.palette_rounded,
                    tint: AppColors.pink,
                    children: <Widget>[
                      SwitchListTile(
                        value: settings.isDark,
                        onChanged: (value) => settings.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 2,
                        ),
                        secondary: ProfileTileIcon(
                          icon: settings.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: AppColors.pink,
                        ),
                        title: const Text('حالت تاریک'),
                        subtitle: Text(
                          settings.isDark
                              ? 'تیره — مناسب استفاده در نور کم'
                              : 'روشن — مناسب استفاده در روز',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 18, endIndent: 18),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        leading: const ProfileTileIcon(
                          icon: Icons.description_rounded,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('مستندات سرور'),
                        subtitle: Text(
                          AppConfig.docsUrl,
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
                SliverToBoxAdapter(
                  child: ProfileSectionCard(
                    title: 'حساب کاربری',
                    icon: Icons.manage_accounts_rounded,
                    tint: AppColors.warning,
                    children: <Widget>[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        leading: const ProfileTileIcon(
                          icon: Icons.logout_rounded,
                          color: AppColors.danger,
                        ),
                        title: const Text(
                          'خروج از حساب',
                          style: TextStyle(color: AppColors.danger),
                        ),
                        subtitle: Text(
                          'از این دستگاه خارج می‌شوید',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: _logoutBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: AppColors.textMuted,
                              ),
                        onTap: _logoutBusy ? null : _confirmLogout,
                      ),
                      const Divider(height: 1, indent: 18, endIndent: 18),
                      const ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 18),
                        leading: ProfileTileIcon(
                          icon: Icons.info_rounded,
                          color: AppColors.textSecondary,
                        ),
                        title: Text('نسخه برنامه'),
                        trailing: Text(
                          '${AppConfig.appName} ${AppConfig.appVersion}',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: _ProfileFooter()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 8, 0),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.smartphone_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'وضعیت امنیتی دستگاه',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _securityLoading ? null : _loadSecurityReport,
            tooltip: 'بررسی دوباره',
            visualDensity: VisualDensity.compact,
            icon: _securityLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityContent(ThemeData theme) {
    if (_securityLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'در حال بررسی دستگاه…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_securityError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InfoBanner(
              icon: Icons.error_outline_rounded,
              color: AppColors.danger,
              text: _securityError!,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _loadSecurityReport,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تلاش دوباره'),
              ),
            ),
          ],
        ),
      );
    }

    final report = _securityReport;
    if (report == null) return const SizedBox.shrink();

    final compromised = report.isCompromised;
    final accent = compromised ? AppColors.danger : AppColors.mint;
    final deviceName = <String?>[
      report.manufacturer,
      report.model,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SecurityStatusRow(
            label: 'شبیه‌ساز (Emulator)',
            compromised: report.isEmulator,
          ),
          const SizedBox(height: 10),
          SecurityStatusRow(
            label: 'دسترسی روت (Root)',
            compromised: report.isRooted,
          ),
          const SizedBox(height: 14),
          if (deviceName.isNotEmpty || report.androidVersion != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (deviceName.isNotEmpty)
                    ProfileInfoLine(label: 'دستگاه', value: deviceName),
                  if (report.androidVersion != null)
                    ProfileInfoLine(
                      label: 'سیستم‌عامل',
                      value: report.androidVersion!,
                    ),
                  if (report.details.isNotEmpty) const SizedBox(height: 6),
                  for (final detail in report.details)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.circle, size: 5, color: accent),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              detail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _InfoBanner(
            icon: compromised
                ? Icons.warning_amber_rounded
                : Icons.verified_rounded,
            color: accent,
            text: compromised
                ? 'این دستگاه ممکن است امن نباشد؛ ورود و داده‌های حساس '
                      'را با احتیاط انجام دهید.'
                : 'دستگاه سالم به نظر می‌رسد؛ نشانه‌ای از شبیه‌ساز یا روت '
                      'پیدا نشد.',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.lock_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'توکن‌های ورود در Android Keystore (حافظه امن دستگاه) '
                  'ذخیره می‌شوند و رمز عبور شما ذخیره نمی‌شود.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.playlistCount,
    required this.favoriteCount,
  });

  final User? user;
  final int playlistCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name ?? 'کاربر Soundify';
    final username = user?.username ?? 'soundify';
    final email = user?.email ?? '';
    final initials = user?.initials ?? 'S';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              ProfileAvatar(
                initials: initials,
                avatarUrl: user?.avatarUrl,
                size: 74,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (user?.isVerified == true)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                    if (email.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: Colors.white.withValues(alpha: 0.64),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: ProfileStatTile(
                  label: 'پلی‌لیست',
                  value: playlistCount,
                  icon: Icons.queue_music_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProfileStatTile(
                  label: 'علاقه‌مندی',
                  value: favoriteCount,
                  icon: Icons.favorite_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 30),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.music_note_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Soundify',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ساخته‌شده با عشق برای موسیقی فارسی',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
