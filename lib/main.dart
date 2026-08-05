import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/theme.dart' as app_theme;
import 'package:stock_market_monitoring_app/Models/user_data_model.dart';
import 'package:stock_market_monitoring_app/Services/background_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'package:stock_market_monitoring_app/Services/notification_service.dart';
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
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: Colors.grey[100],
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: Colors.grey[900],
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  elevation: 0,
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
