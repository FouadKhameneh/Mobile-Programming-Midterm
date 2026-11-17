import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_flow_screen.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/auth_provider.dart';
import 'state/settings_provider.dart';
import 'widgets/main_shell.dart';

class SoundifyApp extends StatelessWidget {
  const SoundifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Soundify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const <Locale>[
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    final Widget screen;
    final String stage;
    if (auth.isInitializing) {
      stage = 'splash';
      screen = const SplashScreen();
    } else if (!settings.onboardingSeen) {
      stage = 'onboarding';
      screen = const OnboardingScreen();
    } else if (auth.isAuthenticated) {
      if (auth.biometricLocked) {
        stage = 'biometric';
        screen = const BiometricLockScreen();
      } else {
        stage = 'main';
        screen = const MainShell();
      }
    } else {
      stage = 'auth';
      screen = const AuthFlowScreen();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(fade),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<String>(stage), child: screen),
    );
  }
}
