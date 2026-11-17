import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../state/player_provider.dart';
import 'app_widgets.dart';
import 'mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  PlayerProvider? _player;
  String? _lastError;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _player = context.read<PlayerProvider>();
    _player!.addListener(_onPlayerChanged);
  }

  @override
  void dispose() {
    _player?.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    final message = _player?.error;
    if (message == null) {
      _lastError = null;
      return;
    }
    if (message == _lastError || !mounted) return;
    _lastError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppSnack(context, message, error: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const MiniPlayer(),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) {
                if (value == _index) return;
                setState(() => _index = value);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'خانه',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'جست‌وجو',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'کتابخانه',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'پروفایل',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
