import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/auth_service.dart';
import 'profile_info_page.dart';
import 'change_password_page.dart';

class AccountSettingsPage extends StatelessWidget {
  final String? section;

  const AccountSettingsPage({super.key, this.section});

  @override
  Widget build(BuildContext context) {
    // If a specific section was requested in arguments, navigate directly to that sub-page
    if (section == 'password') {
      return const ChangePasswordPage();
    } else if (section == 'profile') {
      return const ProfileInfoPage();
    }

    // Default Account Settings Hub
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Manage Account & Security',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildMenuCard(
            context,
            icon: Icons.person,
            title: 'Profile Info',
            subtitle: 'View and manage your account profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileInfoPage(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.security,
            title: 'Change Password',
            subtitle: 'Update account password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildLogoutCard(context, authService),
          const SizedBox(height: 16),
          _buildDeleteAccountCard(context, authService),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
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
        subtitle: const Text(
          'Sign out from your account on this device',
          style: TextStyle(fontSize: 12),
        ),
        onTap: () async {
          final confirmed = await _showConfirmDialog(
            context,
            'Logout',
            'Are you sure you want to logout?',
          );

          if (confirmed && context.mounted) {
            try {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
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
                await user.delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/login');
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
