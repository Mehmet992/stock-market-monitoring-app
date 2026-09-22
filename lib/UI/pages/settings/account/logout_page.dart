import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/auth_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'profile_info_page.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logout & Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Sign Out or Delete Account',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLogoutCard(context, authService),
          const SizedBox(height: 16),
          _buildDeleteAccountCard(context, authService),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, AuthService authService) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.orange, size: 28),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        subtitle: Text(
          authService.isAnonymous
              ? 'Guest Account Options'
              : 'Sign out from your account on this device',
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () => _handleLogout(context, authService),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthService authService) async {
    final databaseService = DatabaseService();
    final user = authService.currentUser;

    if (authService.isAnonymous && user != null) {
      final choice = await _showGuestLogoutDialog(context);
      if (!context.mounted) return;

      if (choice == 'link') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileInfoPage()),
        );
      } else if (choice == 'delete') {
        try {
          await databaseService.deleteUserProfile(user.uid);
          await authService.deleteCurrentUser();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
      return;
    }

    final confirmed = await _showConfirmDialog(
      context,
      'Logout',
      'Are you sure you want to logout?',
    );

    if (confirmed && context.mounted) {
      try {
        await authService.signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showGuestLogoutDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Guest Account'),
          ],
        ),
        content: const Text(
          'You are logged in as a Guest.\n\n'
          'Signing out will permanently delete your guest watchlist and preferences unless you link your account to an email address.\n\n'
          'What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'link'),
            child: const Text('Link Account'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete & Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountCard(BuildContext context, AuthService authService) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        subtitle: const Text(
          'Permanently delete your account and all data',
          style: TextStyle(fontSize: 12),
        ),
        onTap: () async {
          final confirmed = await _showConfirmDialog(
            context,
            'Delete Account',
            'This action cannot be undone. All your data will be permanently deleted.\n\nAre you sure?',
          );

          if (confirmed && context.mounted) {
            try {
              final user = authService.currentUser;
              if (user != null) {
                final databaseService = DatabaseService();
                await databaseService.deleteUserProfile(user.uid);
                await authService.deleteCurrentUser();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
