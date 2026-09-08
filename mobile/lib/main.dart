import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'utils/secure_storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart'
    if (dart.library.io) 'utils/url_strategy_stub.dart';
import 'config/theme.dart';
import 'features/settings/legal_document_screen.dart';
import 'app.dart';
import 'features/onboarding/user_type_selection_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/stripe_payment_service.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';
import 'services/att_service.dart';
import 'services/rating_service.dart';
import 'services/update_service.dart';
import 'services/deep_link_service.dart';

const bool _isTest = bool.fromEnvironment('FLUTTER_TEST');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  User? currentUser;
  bool hasCompletedOnboarding = true;

  if (!_isTest) {
    try {
      // Initialize Firebase using native configuration files on mobile
      // (android/app/google-services.json and ios/Runner/GoogleService-Info.plist).
      // Web still uses the demo options below.
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
            appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
            messagingSenderId: String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID'),
            projectId: String.fromEnvironment('FIREBASE_WEB_PROJECT_ID'),
            authDomain: String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN'),
            storageBucket: String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET'),
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      debugPrint('Firebase inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar Firebase: $e');
    }

    // Initialize Stripe (web only; mobile uses IAP)
    try {
      if (kIsWeb) {
        await StripePaymentService.initialize();
        debugPrint('Stripe inicializado correctamente');
      }
    } catch (e) {
      debugPrint('Error al inicializar Stripe: $e');
    }

    // Initialize In-App Purchase
    try {
      await IapService().initialize();
      debugPrint('IAP inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar IAP: $e');
    }

    // Initialize notifications
    try {
      await NotificationService().initialize();
      await NotificationService().scheduleReEngagementNotification(delay: const Duration(days: 3));
      debugPrint('Notificaciones inicializadas correctamente');
    } catch (e) {
      debugPrint('Error al inicializar notificaciones: $e');
    }

    // Wait for the auth state to be available
    currentUser = await FirebaseAuth.instance.authStateChanges().first;

    // Check if the user has completed the onboarding
    hasCompletedOnboarding = await SecureStorageService.getBool('onboarding_completed');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  String initialRoute;
  if (currentUser != null) {
    initialRoute = '/main';
  } else if (!hasCompletedOnboarding) {
    initialRoute = '/onboarding';
  } else {
    initialRoute = '/login';
  }

  runApp(RoomMateMatchApp(initialRoute: initialRoute));
}

class RoomMateMatchApp extends StatefulWidget {
  final String initialRoute;

  const RoomMateMatchApp({super.key, this.initialRoute = '/login'});

  @override
  State<RoomMateMatchApp> createState() => _RoomMateMatchAppState();
}

class _RoomMateMatchAppState extends State<RoomMateMatchApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AttService.requestIfNeeded();
    RatingService.trackAppOpen();
    DeepLinkService().init();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_navigatorKey.currentContext != null) {
        await UpdateService.checkForUpdate(_navigatorKey.currentContext!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RoomMate Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('es');
        for (final l in supportedLocales) {
          if (l.languageCode == locale.languageCode) return l;
        }
        return const Locale('es');
      },
      initialRoute: widget.initialRoute,
      onGenerateRoute: _generateRoute,
    );
  }
}

Route<dynamic>? _generateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case '/login':
      page = const WelcomeScreen();
      break;
    case '/onboarding':
      page = const OnboardingScreen();
      break;
    case '/main':
      page = const MainScreen();
      break;
    case '/terms':
      page = const LegalDocumentScreen(
        title: 'Términos de Servicio',
        assetPath: 'assets/legal/terms_of_service.md',
      );
      break;
    case '/privacy':
      page = const LegalDocumentScreen(
        title: 'Política de Privacidad',
        assetPath: 'assets/legal/privacy_policy.md',
      );
      break;
    case '/cookies':
      page = const LegalDocumentScreen(
        title: 'Política de Cookies',
        assetPath: 'assets/legal/cookie_policy.md',
      );
      break;
    case '/':
    default:
      page = const WelcomeScreen();
  }
  return MaterialPageRoute(builder: (context) => page, settings: settings);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

  }

  Future<void> _checkAuthStatus() async {
    if (_isTest) return;

    try {
      // Minimal delay for splash screen visibility
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      // Check if user is authenticated
      final user = _authService.currentUser;
      
      if (user != null) {
        // User is logged in, go to main screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // User is not logged in, check if they selected user type
        final userType = await SecureStorageService.getString('user_type');
        
        if (userType == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UserTypeSelectionScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al verificar estado de autenticación: $e');
      // On error, navigate to login screen as fallback
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTest) {
      return const Scaffold(
        body: Center(child: Text('RoomMate Match')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF022C87),
              Color(0xFF1FA5F0),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_symbol.png',
                height: 320,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '© 2026 RoomMate Match',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
