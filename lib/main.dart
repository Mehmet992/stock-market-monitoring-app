import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/UI/app_shell.dart';
import 'package:stock_market_monitoring_app/UI/pages/auth/login_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/auth/signup_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/auth/email_verification_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings/account_settings_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings/preferences_settings_page.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings/legal_support_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Market Monitor',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: const AuthenticationWrapper(),
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
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          // If email is not verified, show verification page
          if (!user.emailVerified && !user.isAnonymous) {
            return const EmailVerificationPage();
          }
          // If email is verified, show home
          return const AppShell();
        }

        // No user logged in, show login page
        return const LoginPage();
      },
    );
  }
}
