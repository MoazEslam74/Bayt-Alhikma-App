// lib/main.dart
import 'package:bayt_alhikma/screens/edit_profile.dart';
import 'package:bayt_alhikma/screens/opening_page.dart';
import 'package:bayt_alhikma/screens/recommended_screen.dart';
import 'package:bayt_alhikma/view_model/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 1. Import your local storage service
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/widgets.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/store_screen.dart';
import 'screens/search_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/now_playing_screen.dart';

// Utils / styles
import 'utils/styles.dart';
// إستدعاء ملف الـ Session Manager اللي إنت عملته
import 'utils/session_timeout_manager.dart';

import 'view_model/dark_mode.dart';
import 'view_model/language_provider.dart';

// ... (Routes class remains the same) ...
class Routes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String store = '/store';
  static const String search = '/search';
  static const String saved = '/saved';
  static const String nowPlaying = '/now_playing';
  static const String bookInfo = '/book_info';
  static const String recommended = '/recommended';
}

// تعريف الـ GlobalKey للـ Navigator عشان نقدر نتحكم في الشاشات من بره
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 2. Initialize Hive here
  await LocalStorageService.init();
  await dotenv.load(fileName: ".env");
  
  // ❌ قم بحذف هذا السطر تماماً
  // runApp(const MyApp());

  // ✅ الإبقاء على هذا الاستدعاء فقط
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DarkModeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DarkModeProvider>(
      builder: (context, darkMode, _) {
        return MaterialApp(
          // 1. ربط الـ navigatorKey بالـ MaterialApp
          navigatorKey: globalNavigatorKey,

          title: 'Bayt Alhikma',
          theme: AppStyles.lightTheme,
          darkTheme: AppStyles.darkTheme,
          themeMode: darkMode.isDark ? ThemeMode.dark : ThemeMode.light,

          // 2. تغليف التطبيق بالـ SessionTimeoutManager
          builder: (context, child) {
            return SessionTimeoutManager(
              navigatorKey: globalNavigatorKey,
              timeoutDuration: const Duration(
                minutes: 2,
              ), // تقدر تغير المدة من هنا
              child: child!,
            );
          },

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: Provider.of<LanguageProvider>(context).locale,
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'EG')],
          debugShowCheckedModeBanner: false,
          // The OpeningPage will now check Hive to decide where to go
          home: const Scaffold(body: OpeningPage()),
          routes: <String, WidgetBuilder>{
            Routes.home: (context) => const HomeScreen(),
            Routes.login: (context) => LoginScreen(),
            Routes.signup: (context) => SignUpScreen(),
            Routes.recommended: (context) => RecommendedScreen(),
            Routes.store: (context) => StoreScreen(),
            Routes.search: (context) => const SearchScreen(),
            Routes.saved: (context) => SavedScreen(),
          },
          onGenerateRoute: (RouteSettings settings) {
            // ... (existing onGenerateRoute logic) ...
            final args = settings.arguments;
            switch (settings.name) {
              case Routes.nowPlaying:
                final Map<String, dynamic> book = (args is Map<String, dynamic>)
                    ? args
                    : <String, dynamic>{};
                return MaterialPageRoute(
                  builder: (context) => NowPlayingScreen(book: book),
                  settings: settings,
                );

              default:
                return MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                  settings: settings,
                );
            }
          },
        );
      },
    );
  }
}
