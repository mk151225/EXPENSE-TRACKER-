import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/session_manager.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    MultiProvider(
      providers: [Provider<DatabaseService>.value(value: dbService)],
      child: const ExpenseTrackerApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp>
    with WidgetsBindingObserver {
  // EventChannel name must match what MainActivity.kt declares.
  static const _screenLockChannel = EventChannel(
    'com.example.expense_tracker/screen_lock',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToScreenLockEvents();
  }

  /// Subscribe to native Android screen lock/unlock events.
  void _listenToScreenLockEvents() {
    _screenLockChannel.receiveBroadcastStream().listen((event) {
      if (event == 'screen_locked') {
        // Device screen turned OFF — mark session as needing re-auth.
        SessionManager.instance.onScreenLocked();
      } else if (event == 'screen_unlocked') {
        // User dismissed the device lock screen — check if we should lock.
        final shouldLock = SessionManager.instance.onScreenUnlocked();
        if (shouldLock) {
          _navigateToLockScreen();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Fallback for platforms where the native EventChannel is unavailable
    // (web, desktop). On those platforms, use the flag set by onScreenLocked().
    if (state == AppLifecycleState.resumed) {
      final shouldLock = SessionManager.instance.onResumedFallback();
      if (shouldLock) {
        _navigateToLockScreen();
      }
    }
    // We do NOT lock on inactive / paused / detached — those fire during
    // normal app switching and must not trigger a logout.
  }

  void _navigateToLockScreen() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LockScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const LockScreen(),
    );
  }
}

