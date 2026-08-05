import 'package:flutter/material.dart';
import 'terms_privacy_page.dart';
import 'help_support_page.dart';
import 'app_version_page.dart';

class LegalSupportPage extends StatelessWidget {
  final String? section;

  const LegalSupportPage({super.key, this.section});

  @override
  Widget build(BuildContext context) {
    // If a specific section was requested in arguments, navigate directly to that sub-page
    if (section == 'help') {
      return const HelpSupportPage();
    } else if (section == 'version') {
      return const AppVersionPage();
    } else if (section == 'terms') {
      return const TermsPrivacyPage();
    }

    // Default Legal & Support Hub
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & Support'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Policies, Help & App Details',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildMenuCard(
            context,
            icon: Icons.description,
            title: 'Terms & Privacy Policy',
            subtitle: 'Read our terms, conditions, and privacy rights',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsPrivacyPage(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'FAQs, contact information, and live chat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportPage(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.info,
            title: 'App Version',
            subtitle: 'v1.0.0 (Release Notes & Updates)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppVersionPage(),
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
