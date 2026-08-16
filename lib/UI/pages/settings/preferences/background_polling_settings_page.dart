import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/background_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';

class BackgroundPollingSettingsPage extends StatefulWidget {
  const BackgroundPollingSettingsPage({super.key});

  @override
  State<BackgroundPollingSettingsPage> createState() =>
      _BackgroundPollingSettingsPageState();
}

class _BackgroundPollingSettingsPageState
    extends State<BackgroundPollingSettingsPage> {
  double? _selectedBackgroundPollingTime = 3600.0;
  bool _isLoading = false;
  bool _isSaving = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadBackgroundPollingTime();
  }

  Future<void> _loadBackgroundPollingTime() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = await _databaseService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _selectedBackgroundPollingTime = userProfile.backgroundPollingTime;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[BackgroundPollingSettingsPage] Error loading background polling time: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyBackgroundPollingTime() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _databaseService.saveUserProfile(
        backgroundPollingTime: _selectedBackgroundPollingTime,
      );

      await scheduleBackgroundWorker(_selectedBackgroundPollingTime);

      if (kDebugMode) {
        debugPrint(
            '[BackgroundPollingSettingsPage] Saved background polling interval: $_selectedBackgroundPollingTime');
      }
      if (mounted) {
        final label = _selectedBackgroundPollingTime == null
            ? 'Background alert checks disabled'
            : 'Background alerts set to check every ${(_selectedBackgroundPollingTime! / 60).round()} minutes';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(label),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[BackgroundPollingSettingsPage] Error saving background polling interval: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save background alert preference: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': '15 Minutes', 'sub': 'Check target prices every 15 minutes', 'value': 900.0},
      {'label': '30 Minutes', 'sub': 'Check target prices every 30 minutes', 'value': 1800.0},
      {'label': '1 Hour', 'sub': 'Check target prices every 60 minutes', 'value': 3600.0},
      {'label': 'Disabled', 'sub': 'Turn off background alert notifications', 'value': null},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Notifications'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background Price Alerts',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select how often the background service fetches market prices and checks target alert prices when the app is closed.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ...options.map((opt) {
                    final double? val = opt['value'] as double?;
                    final isSelected = _selectedBackgroundPollingTime == val;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBackgroundPollingTime = val;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15)
                                : Theme.of(context).cardColor,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['label'] as String,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opt['sub'] as String,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSaving ? null : _applyBackgroundPollingTime,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Background Preference',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
