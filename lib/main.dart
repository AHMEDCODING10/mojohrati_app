import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'state/app_state.dart';
import 'state/theme_state.dart';
import 'state/cart_state.dart';
import 'state/favorites_state.dart';
import 'ui/screens/auth/splash_screen.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'utils/localization_service.dart';
import 'utils/api_service.dart';
import 'services/deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');
  await LocalizationService.load('ar'); // Default locale

  // Initialize Global API Service with Interceptors
  ApiService().initialize(
    getToken: () async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    },
    onUnauthorized: () {
      // AppState handles the redirect via AuthInterceptor's LoginScreen navigation
      debugPrint('Global 401 Intercepted: Redirecting to Login');
    },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..loadSettings()),
        ChangeNotifierProvider(create: (_) => ThemeState()),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProxyProvider<AppState, FavoritesState>(
          create: (_) => FavoritesState(),
          update: (_, appState, favoritesState) => 
            favoritesState!..setToken(appState.token),
        ),
      ],
      child: const MojawharatiApp(),
    ),
  );
}

class MojawharatiApp extends StatefulWidget {
  const MojawharatiApp({super.key});

  @override
  State<MojawharatiApp> createState() => _MojawharatiAppState();
}

class _MojawharatiAppState extends State<MojawharatiApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep linking with context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.initialize(context);
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mojawharati',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: appState.locale,
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
