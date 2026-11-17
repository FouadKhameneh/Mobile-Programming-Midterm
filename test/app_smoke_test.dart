import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundify/app.dart';
import 'package:soundify/core/network/api_client.dart';
import 'package:soundify/core/storage/preferences_service.dart';
import 'package:soundify/core/storage/secure_store.dart';
import 'package:soundify/state/auth_provider.dart';
import 'package:soundify/state/settings_provider.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({
    required super.api,
    required super.secureStore,
    required super.prefs,
  });

  @override
  AuthStatus get status => AuthStatus.unauthenticated;

  @override
  bool get isInitializing => false;

  @override
  bool get isAuthenticated => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({PreferencesService prefs, AuthProvider auth})> harness(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = PreferencesService();
    await prefs.init();
    final secure = SecureStore();
    final auth = _FakeAuthProvider(
      api: ApiClient(secureStore: secure),
      secureStore: secure,
      prefs: prefs,
    );
    return (prefs: prefs, auth: auth);
  }

  testWidgets('unauth first launch renders onboarding without errors',
      (tester) async {
    final h = await harness(<String, Object>{});
    final settings = SettingsProvider(h.prefs);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<AuthProvider>.value(value: h.auth),
        ],
        child: const SoundifyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning unauth user sees the Persian login screen',
      (tester) async {
    final h = await harness(<String, Object>{'soundify_onboarding_seen': true});
    final settings = SettingsProvider(h.prefs);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<AuthProvider>.value(value: h.auth),
        ],
        child: const SoundifyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('خوش برگشتی'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding completion persists the first-launch flag',
      (tester) async {
    final h = await harness(<String, Object>{});
    final settings = SettingsProvider(h.prefs);
    await settings.completeOnboarding();
    expect(settings.onboardingSeen, isTrue);
  });
}
