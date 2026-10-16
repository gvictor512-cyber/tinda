import 'dart:async';
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
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/email_verification_screen.dart';
import 'features/legal/reconsent_screen.dart';
import 'services/stripe_payment_service.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';
import 'services/rating_service.dart';
import 'services/update_service.dart';
import 'services/deep_link_service.dart';
import 'services/public_profile_service.dart';
import 'services/presence_service.dart';
import 'services/api_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config/legal_constants.dart';

const bool _isTest = bool.fromEnvironment('FLUTTER_TEST');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En Release los errores de build se ven como pantalla en blanco;
  // este widget muestra la excepción en pantalla para poder diagnosticarla.
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFF101418),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: ${details.exceptionAsString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      );

  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  User? currentUser;
  bool hasCompletedOnboarding = true;

  if (!_isTest) {
    try {
      await _initializeServices(
        onUserReady: (user) => currentUser = user,
        onOnboardingReady: (completed) => hasCompletedOnboarding = completed,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error o timeout global en inicialización: $e');
    }
  }

  // Set preferred orientations (sin bloquear el arranque si tarda)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('Error al fijar orientaciones: $e');
  }

  // Legal/version gates evaluated for logged-in users
  bool needsEmailVerification = false;
  bool needsReconsent = false;
  final authedUser = currentUser;
  if (authedUser != null) {
    // Email gate: only for email/password accounts (social providers are
    // verified by definition). Anonymous/demo sessions are exempt.
    // En builds de prueba (debug/profile) se omite el gate para poder
    // registrar cuentas con emails ficticios (p. ej. demo para App Review);
    // la version comercial (release) sigue exigiendo la verificacion.
    final isEmailProvider = authedUser.providerData
        .any((p) => p.providerId == 'password');
    needsEmailVerification =
        kReleaseMode && isEmailProvider && !authedUser.emailVerified;

    // Re-consent gate: stored terms version older than the current one
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authedUser.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final consent = doc.data()?['consent'] as Map<String, dynamic>?;
      final storedVersion = consent?['termsVersion'] as String?;
      needsReconsent = storedVersion != null &&
          storedVersion != LegalConstants.currentTermsVersion;
    } catch (e) {
      debugPrint('Consent version check failed: $e');
    }
  }

  String initialRoute;
  if (authedUser == null) {
    initialRoute = !hasCompletedOnboarding ? '/onboarding' : '/login';
  } else if (needsEmailVerification) {
    initialRoute = '/email-verification';
  } else if (needsReconsent) {
    initialRoute = '/reconsent';
  } else {
    initialRoute = '/main';
  }

  WidgetsBinding.instance.addObserver(PresenceService.instance);
  runApp(RoomMateMatchApp(initialRoute: initialRoute));
}

Future<void> _initializeServices({
  required void Function(User?) onUserReady,
  required void Function(bool) onOnboardingReady,
}) async {
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
      ).timeout(const Duration(seconds: 10));
    } else {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    }
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error al inicializar Firebase: $e');
  }

  // App Check: proveedores reales en release, debug provider en desarrollo.
  // Backend enforcement is opt-in via APP_CHECK_ENABLED=true.
  try {
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
      if (kDebugMode) {
        debugPrint(
            'App Check (debug) activado — registra el token que aparece en logs');
      }
    }
  } catch (e) {
    debugPrint('App Check no disponible: $e');
  }

  // Crashlytics: captura errores de Flutter y errores async no manejados
  try {
    if (!kIsWeb && !_isTest) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  } catch (e) {
    debugPrint('Crashlytics no disponible: $e');
  }

  // Independent services initialize in parallel so cold start stays fast.
  await Future.wait([
    // Stripe (web only; mobile uses IAP)
    () async {
      try {
        if (kIsWeb) {
          await StripePaymentService.initialize();
          debugPrint('Stripe inicializado correctamente');
        }
      } catch (e) {
        debugPrint('Error al inicializar Stripe: $e');
      }
    }(),
    // In-App Purchase
    () async {
      try {
        await IapService().initialize().timeout(const Duration(seconds: 10));
        debugPrint('IAP inicializado correctamente');
      } catch (e) {
        debugPrint('Error al inicializar IAP: $e');
      }
    }(),
    // Notifications
    () async {
      try {
        await NotificationService()
            .initialize()
            .timeout(const Duration(seconds: 10));
        // Scheduling is non-critical: don't make startup wait for it
        unawaited(NotificationService()
            .scheduleReEngagementNotification(delay: const Duration(days: 3))
            .timeout(const Duration(seconds: 5))
            .catchError((Object e) =>
                debugPrint('Error programando notificación: $e')));
        debugPrint('Notificaciones inicializadas correctamente');
      } catch (e) {
        debugPrint('Error al inicializar notificaciones: $e');
      }
    }(),
    // Auth state
    () async {
      try {
        final user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 5));
        onUserReady(user);
        if (user != null) {
          // Self-heal: ensure the public profiles/{uid} doc exists and is fresh
          unawaited(PublicProfileService.sync(user.uid));
          // Online presence (lifecycle + heartbeat)
          PresenceService.instance.start();
          // Claim pending referral rewards (server-side grant)
          unawaited(() async {
            try {
              final token = await user.getIdToken();
              final api = ApiService()..setAuthToken(token ?? '');
              await api.post('/users/me/referral-rewards');
            } catch (e) {
              debugPrint('Referral rewards claim failed: $e');
            }
          }());
        }
      } catch (e) {
        debugPrint('Error al obtener el estado de autenticación: $e');
      }
    }(),
    // Onboarding flag
    () async {
      try {
        final completed = await SecureStorageService.getBool(
                'onboarding_completed')
            .timeout(const Duration(seconds: 5), onTimeout: () => true);
        onOnboardingReady(completed);
      } catch (e) {
        debugPrint('Error al leer onboarding_completed: $e');
      }
    }(),
  ]);
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
    case '/register':
      page = const RegisterScreen();
      break;
    case '/onboarding':
      page = const OnboardingScreen();
      break;
    case '/main':
      page = const MainScreen();
      break;
    case '/email-verification':
      page = const EmailVerificationScreen();
      break;
    case '/reconsent':
      page = const ReconsentScreen();
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
