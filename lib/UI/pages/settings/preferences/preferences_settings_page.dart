import 'package:flutter/material.dart';
import 'theme_settings_page.dart';
import 'currency_settings_page.dart';
import 'polling_settings_page.dart';
import 'background_polling_settings_page.dart';

class PreferencesSettingsPage extends StatelessWidget {
  final String? section;

  const PreferencesSettingsPage({super.key, this.section});

  @override
  Widget build(BuildContext context) {
    // If a specific section was requested in arguments, navigate directly to that sub-page
    if (section == 'theme') {
      return const ThemeSettingsPage();
    } else if (section == 'currency') {
      return const CurrencySettingsPage();
    } else if (section == 'polling') {
      return const PollingSettingsPage();
    } else if (section == 'background_polling') {
      return const BackgroundPollingSettingsPage();
    }

    // Default Preferences Menu Hub
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'App Customization & Behavior',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildMenuCard(
            context,
            icon: Icons.palette,
            title: 'Theme Settings',
            subtitle: 'Light / Dark mode choices',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsPage(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.currency_exchange,
            title: 'Display Currency',
            subtitle: 'Choose default display currency',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencySettingsPage(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.timer,
            title: 'Polling Interval',
            subtitle: 'Set data refresh frequency (10s, 15s, 30s, 60s)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PollingSettingsPage(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.notifications_active,
            title: 'Background Notifications',
            subtitle: 'Configure background target price alert checks',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackgroundPollingSettingsPage(),
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
