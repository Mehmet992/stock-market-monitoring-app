import 'package:flutter/material.dart';
import 'profile_info_page.dart';
import 'change_password_page.dart';
import 'logout_page.dart';

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
    } else if (section == 'logout') {
      return const LogoutPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
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
          _buildMenuCard(
            context,
            icon: Icons.logout,
            title: 'Logout & Account Options',
            subtitle: 'Sign out or delete your account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogoutPage(),
                ),
              );
            },
          ),
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
}
