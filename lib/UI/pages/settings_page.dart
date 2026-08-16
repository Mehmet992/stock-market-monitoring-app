import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';

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
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
              onTap: () => Navigator.pushNamed(context, '/preferences-settings',
                  arguments: 'theme'),
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
            _buildSettingsCard(
              context,
              icon: Icons.notifications_active,
              title: 'Background Notifications',
              subtitle: 'Configure background target price alert checks',
              onTap: () => Navigator.pushNamed(context, '/preferences-settings',
                  arguments: 'background_polling'),
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

            // Data Provider Status Indicator
            _buildProviderStatusFooter(context),
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

  Widget _buildProviderStatusFooter(BuildContext context) {
    return StreamBuilder<List<MarketAsset>>(
      stream: GenericMarketService().marketDataStream,
      builder: (context, snapshot) {
        final assets = snapshot.data ?? [];
        final sources = assets
            .map((a) => a.source)
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet();

        String providerText;
        Color statusColor = Colors.green;

        if (assets.isEmpty) {
          providerText = 'Connecting to market data service...';
          statusColor = Colors.orange;
        } else if (sources.contains('SERVER_ERROR') && sources.length == 1) {
          providerText = 'Server-side Error: Failed to fetch market quotes';
          statusColor = Colors.red;
        } else {
          final usCryptoSources = assets
              .where((a) => a.type == AssetType.crypto || (a.type == AssetType.stock && !a.symbol.endsWith('.IS')))
              .map((a) => a.source)
              .where((s) => s != null && s.isNotEmpty)
              .cast<String>()
              .toSet();

          final bistForexSources = assets
              .where((a) => a.symbol.endsWith('.IS') || a.type == AssetType.forex || a.type == AssetType.metal)
              .map((a) => a.source)
              .where((s) => s != null && s.isNotEmpty)
              .cast<String>()
              .toSet();

          String formatSourceLabel(Set<String> categorySources, String primaryName, String fallbackName) {
            if (categorySources.contains('STALE_CACHE')) {
              return 'Stale Cache';
            }
            if (categorySources.contains('SERVER_ERROR')) {
              return 'Server Error';
            }
            if (categorySources.any((s) => s.contains('FALLBACK'))) {
              return '$fallbackName (Fallback)';
            }
            if (categorySources.contains('ALPACA')) {
              return 'Alpaca Market';
            }
            if (categorySources.contains('YAHOO')) {
              return 'Yahoo Finance';
            }
            if (categorySources.contains('BIGPARA')) {
              return 'Bigpara';
            }
            return primaryName;
          }

          final usCryptoLabel = formatSourceLabel(usCryptoSources, 'Alpaca Market', 'Yahoo Finance');
          final bistForexLabel = formatSourceLabel(bistForexSources, 'Yahoo Finance', 'Bigpara');

          final isFallbackActive = usCryptoSources.any((s) => s.contains('FALLBACK') || s == 'STALE_CACHE') ||
              bistForexSources.any((s) => s.contains('FALLBACK') || s == 'STALE_CACHE');
          final isServerError = sources.contains('SERVER_ERROR');

          if (isServerError) {
            statusColor = Colors.red;
          } else if (isFallbackActive) {
            statusColor = Colors.orange;
          } else {
            statusColor = Colors.green;
          }

          providerText = 'US/Crypto: $usCryptoLabel • BIST/Forex: $bistForexLabel';
        }

        return Container(
          margin: const EdgeInsets.only(top: 16, bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  providerText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

