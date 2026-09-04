import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: OfficeBuddyApp()));
}

class OfficeBuddyApp extends ConsumerStatefulWidget {
  const OfficeBuddyApp({super.key});

  @override
  ConsumerState<OfficeBuddyApp> createState() => _OfficeBuddyAppState();
}

class _OfficeBuddyAppState extends ConsumerState<OfficeBuddyApp> with WidgetsBindingObserver {
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      _checkResumeLock();
    }
  }

  Future<void> _checkResumeLock() async {
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasPin();
    final token = await storage.getToken();
    final recently = await storage.isRecentlyUnlockedCurrent();
    if (hasPin && token != null && !recently && mounted) {
      final router = ref.read(routerProvider);
      final current = router.routerDelegate.currentConfiguration.uri.path;
      if (current != '/lock' && current != '/auth' && current != '/onboarding' && current != '/splash') {
        router.go('/lock');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'OfficeBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
