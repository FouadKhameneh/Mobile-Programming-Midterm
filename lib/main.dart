import 'dart:async';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_colors.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/secure_store.dart';
import 'state/auth_provider.dart';
import 'state/catalog_provider.dart';
import 'state/library_provider.dart';
import 'state/player_provider.dart';
import 'state/search_provider.dart';
import 'state/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: AppConfig.notificationChannelId,
    androidNotificationChannelName: AppConfig.notificationChannelName,
    androidNotificationChannelDescription: 'پخش موسیقی Soundify در پس‌زمینه',
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: true,
    notificationColor: AppColors.primaryDeep,
    preloadArtwork: true,
    artDownscaleWidth: 512,
    artDownscaleHeight: 512,
  );

  final prefs = PreferencesService();
  await prefs.init();
  final settings = SettingsProvider(prefs);
  final secureStore = SecureStore();
  final api = ApiClient(secureStore: secureStore);
  final auth = AuthProvider(api: api, secureStore: secureStore, prefs: prefs);
  api.onSessionExpired = auth.handleSessionExpired;

  final catalog = CatalogProvider(api: api);
  final search = SearchProvider(api: api, prefs: prefs);
  final library = LibraryProvider(api: api, auth: auth);
  final player = PlayerProvider();

  unawaited(auth.initialize());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
        ChangeNotifierProvider<SearchProvider>.value(value: search),
        ChangeNotifierProvider<LibraryProvider>.value(value: library),
        ChangeNotifierProvider<PlayerProvider>.value(value: player),
      ],
      child: const SoundifyApp(),
    ),
  );
}
