import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/theme.dart' as app_theme;
import 'package:stock_market_monitoring_app/Models/user_data_model.dart';
import 'package:stock_market_monitoring_app/Services/background_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'package:stock_market_monitoring_app/UI/app_shell.dart';
import 'package:stock_market_monitoring_app/UI/pages/auth/login_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/auth/signup_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/auth/email_verification_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings/account/account_settings_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings/preferences/preferences_settings_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings/legal/legal_support_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double? _lastScheduledTime;
  String? _lastUserId;

  void _syncBackgroundWorker(User? user, UserDataModel? userProfile) {
    final newTime = (user != null && userProfile != null) ? userProfile.backgroundPollingTime : null;
    final newUserId = user?.uid;

    if (_lastUserId != newUserId || _lastScheduledTime != newTime) {
      _lastUserId = newUserId;
      _lastScheduledTime = newTime;
      scheduleBackgroundWorker(newTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return StreamBuilder<UserDataModel?>(
          stream: user != null ? databaseService.getUserProfileStream() : Stream.value(null),
          builder: (context, profileSnapshot) {
            final userProfile = profileSnapshot.data;

            // Sync background worker only when background polling preference or auth user changes
            _syncBackgroundWorker(user, userProfile);

            final activeTheme = userProfile?.theme ?? app_theme.Theme.dark;

            return MaterialApp(
              title: 'Stock Market Monitor',
              debugShowCheckedModeBanner: false,
              themeMode: activeTheme.mode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF00C805),
                  secondary: Color(0xFFFF5000),
                  surface: Color(0xFFF7F9FB),
                  onSurface: Color(0xFF11161D),
                  onSurfaceVariant: Color(0xFF6E7C8E),
                  outline: Color(0xFFE4E7EB),
                ),
                scaffoldBackgroundColor: const Color(0xFFFFFFFF),
                cardColor: const Color(0xFFF7F9FB),
                dividerColor: const Color(0xFFEDF0F3),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFFFFFFF),
                  foregroundColor: Color(0xFF11161D),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: false,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF00C805),
                  secondary: Color(0xFFFF5000),
                  surface: Color(0xFF141A23),
                  onSurface: Color(0xFFFFFFFF),
                  onSurfaceVariant: Color(0xFF8A96A6),
                  outline: Color(0xFF222B38),
                ),
                scaffoldBackgroundColor: const Color(0xFF0A0E14),
                cardColor: const Color(0xFF141A23),
                dividerColor: const Color(0xFF1B2330),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF0A0E14),
                  foregroundColor: Color(0xFFFFFFFF),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: false,
                ),
              ),
              home: AuthenticationWrapper(authSnapshot: authSnapshot),
              routes: {
                '/login': (context) => const LoginPage(),
                '/signup': (context) => const SignupPage(),
                '/verify-email': (context) => const EmailVerificationPage(),
                '/email-verification': (context) => const EmailVerificationPage(),
                '/home': (context) => const AppShell(),
                '/account-settings': (context) {
                  final section = ModalRoute.of(context)?.settings.arguments as String?;
                  return AccountSettingsPage(section: section);
                },
                '/preferences-settings': (context) {
                  final section = ModalRoute.of(context)?.settings.arguments as String?;
                  return PreferencesSettingsPage(section: section);
                },
                '/legal-support': (context) {
                  final section = ModalRoute.of(context)?.settings.arguments as String?;
                  return LegalSupportPage(section: section);
                },
              },
            );
          },
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final AsyncSnapshot<User?> authSnapshot;

  const AuthenticationWrapper({super.key, required this.authSnapshot});

  @override
  Widget build(BuildContext context) {
    if (authSnapshot.connectionState == ConnectionState.waiting) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
          ),
        ),
      );
    }

    if (authSnapshot.hasData) {
      final user = authSnapshot.data!;
      // If email is not verified and the user is not an anonymous user, show verification page
      if (!user.emailVerified && !user.isAnonymous) {
        return const EmailVerificationPage();
      }
      // If email is verified, show home
      return const AppShell();
    }

    // No user logged in, show login page
    return const LoginPage();
  }
}
