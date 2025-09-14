// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

// App state & pages
import 'state.dart';
import 'pages/games_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/timeline_page.dart';
import 'pages/sponsor_page.dart';
import 'pages/profile_page.dart';
import 'pages/signin_page.dart';

// Your HTTP API (custom backend)
import 'api_room.dart';
import 'config.dart'; // ✅ هنا نستورد config.dart عشان نستعمل guestUserId

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = AppState();
  await app.load();

  runApp(InzeliApp(app: app));
}

class InzeliApp extends StatelessWidget {
  final AppState app;
  const InzeliApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFC5533C));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'انزلي',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFFF7F0E3),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFFF7F0E3),
            foregroundColor: Colors.black,
            titleTextStyle: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFEADFCC)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: Color(0xFFC5533C), width: 1.4),
            ),
            labelStyle: TextStyle(color: Colors.black87),
            hintStyle: TextStyle(color: Colors.black54),
          ),
        ),
        home: HomeShell(app: app),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final AppState app;
  const HomeShell({super.key, required this.app});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      Uri? initialUri;
      try {
        initialUri = await _appLinks!.getInitialLink(); // app_links >= 6.x
      } catch (_) {
        final dyn = _appLinks as dynamic;
        try {
          final res = await dyn.getInitialLink(); // older versions
          if (res is Uri) initialUri = res;
        } catch (_) {}
      }
      if (initialUri != null) await _handleUri(initialUri);

      _linkSub = _appLinks!.uriLinkStream.listen(
            (uri) => _handleUri(uri),
        onError: (err) => debugPrint('Deep link stream error: $err'),
      );
    } catch (e) {
      debugPrint('AppLinks init error: $e');
    }
  }

  Future<void> _handleUri(Uri uri) async {
    if (!mounted) return;

    if (uri.scheme == 'https' && uri.host == 'inzeli.app') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join') {
        if (uri.pathSegments.length >= 2) {
          final code = uri.pathSegments[1];
          await _joinRoom(code);
          return;
        }
      }
    }

    if (uri.scheme == 'inzeli' && uri.host == 'join') {
      final code = uri.queryParameters['code'] ?? '';
      if (code.isNotEmpty) {
        await _joinRoom(code);
        return;
      }
    }
  }

  Future<void> _joinRoom(String code) async {
    try {
      // ✅ الآن نستخدم guestUserId من config.dart
      await joinByCode(code: code, userId: guestUserId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انضمّيت للروم $code ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الانضمام: $e')),
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;

    final pages = <Widget>[
      GamesPage(app: app),
      LeaderboardPage(app: app),
      SponsorPage(app: app),
      TimelinePage(app: app),
      ProfilePage(app: app),
    ];
    final titles = <String>[
      'انزلي','المراتب','سبونسر','السالفة؟','حسابي'
    ];

    if (_tab < 0 || _tab >= pages.length) {
      _tab = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'تسجيل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SignInPage(state: app)),
              );
            },
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'انزلي'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'المراتب'),
          NavigationDestination(icon: Icon(Icons.star_border), label: 'سبونسر'),
          NavigationDestination(icon: Icon(Icons.history), label: 'سالفة؟'),
          NavigationDestination(icon: Icon(Icons.account_circle_outlined), label: 'حسابي'),
        ],
      ),
    );
  }
}
