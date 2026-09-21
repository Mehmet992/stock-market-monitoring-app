import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stock_market_monitoring_app/Services/auth_service.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isEmailVerified = false;
  bool _isResendingEmail = false;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final isVerified = await _authService.checkEmailVerified();
      if (isVerified) {
        setState(() {
          _isEmailVerified = true;
        });
        _timer?.cancel();
        // Navigate to home after a short delay to show success
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResendingEmail = true;
    });

    try {
      await _authService.sendEmailVerificationWithRedirect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isResendingEmail = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            // Success Icon or Pending Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isEmailVerified
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                border: Border.all(
                  color: _isEmailVerified ? Colors.green : Colors.blue,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  _isEmailVerified ? Icons.check_circle : Icons.mail_outline,
                  size: 56,
                  color: _isEmailVerified ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              _isEmailVerified ? 'Email Verified!' : 'Verify Your Email',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              _isEmailVerified
                  ? 'Your email has been verified. Welcome to Stock Market Monitor!'
                  : 'We\'ve sent a verification email to ${FirebaseAuth.instance.currentUser?.email}.\n\nPlease click the link in the email to verify your account.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (!_isEmailVerified) ...[
              // Resend Email Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isResendingEmail
                      ? null
                      : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResendingEmail
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Resend Verification Email',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[600]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
