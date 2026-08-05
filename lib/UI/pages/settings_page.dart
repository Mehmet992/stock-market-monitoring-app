import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader(context, 'Account'),
            _buildSettingsCard(
              context,
              icon: Icons.person,
              title: 'Profile Info',
              subtitle: 'View and manage your profile',
              onTap: () => Navigator.pushNamed(context, '/account-settings'),
            ),
            _buildSettingsCard(
              context,
              icon: Icons.security,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () => Navigator.pushNamed(context, '/account-settings',
                  arguments: 'password'),
            ),
            _buildSettingsCard(
              context,
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out from your account',
              onTap: () => Navigator.pushNamed(context, '/account-settings',
                  arguments: 'logout'),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader(context, 'Preferences'),
            _buildSettingsCard(
              context,
              icon: Icons.palette,
              title: 'Theme',
              subtitle: 'Light / Dark mode',
              onTap: () => Navigator.pushNamed(context, '/preferences-settings'),
            ),
            _buildSettingsCard(
              context,
              icon: Icons.currency_exchange,
              title: 'Currency',
              subtitle: 'Change default display currency',
              onTap: () => Navigator.pushNamed(context, '/preferences-settings',
                  arguments: 'currency'),
            ),
            _buildSettingsCard(
              context,
              icon: Icons.timer,
              title: 'Polling Interval',
              subtitle: 'Set data refresh frequency (10s, 15s, 30s, 60s)',
              onTap: () => Navigator.pushNamed(context, '/preferences-settings',
                  arguments: 'polling'),
            ),
            const SizedBox(height: 24),

            // Legal & Support Section
            _buildSectionHeader(context, 'Legal & Support'),
            _buildSettingsCard(
              context,
              icon: Icons.description,
              title: 'Terms & Privacy Policy',
              subtitle: 'Read our terms and policies',
              onTap: () => Navigator.pushNamed(context, '/legal-support'),
            ),
            _buildSettingsCard(
              context,
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () => Navigator.pushNamed(context, '/legal-support',
                  arguments: 'help'),
            ),
            _buildSettingsCard(
              context,
              icon: Icons.info,
              title: 'App Version',
              subtitle: 'v1.0.0',
              onTap: () => Navigator.pushNamed(context, '/legal-support',
                  arguments: 'version'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
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
