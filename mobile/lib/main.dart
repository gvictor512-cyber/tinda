import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/secure_storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'config/theme.dart';
import 'app.dart';
import 'features/onboarding/user_type_selection_screen.dart';
import 'features/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/stripe_payment_service.dart';

const bool _isTest = bool.fromEnvironment('FLUTTER_TEST');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    // Initialize Stripe
    try {
      await StripePaymentService.initialize();
      debugPrint('Stripe inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar Stripe: $e');
    }
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const RoomMateMatchApp());
}

class RoomMateMatchApp extends StatelessWidget {
  const RoomMateMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomMate Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
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
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al verificar estado de autenticación: $e');
      // On error, navigate to login screen as fallback
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 70,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: const Text(
                        'RoomMate Match',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Text(
                        'Encuentra tu compañero de piso ideal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  );
                },
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
            ],
          ),
        ),
      ),
    );
  }
}
