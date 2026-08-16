import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';

class PollingSettingsPage extends StatefulWidget {
  const PollingSettingsPage({super.key});

  @override
  State<PollingSettingsPage> createState() => _PollingSettingsPageState();
}

class _PollingSettingsPageState extends State<PollingSettingsPage> {
  double _selectedPollingTime = 15.0;
  bool _isLoading = false;
  bool _isSavingPolling = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserPollingTime();
  }

  Future<void> _loadUserPollingTime() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = await _databaseService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _selectedPollingTime = userProfile.pollingTime;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PollingSettingsPage] Error loading polling time: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyPollingTime() async {
    setState(() {
      _isSavingPolling = true;
    });

    try {
      await _databaseService.saveUserProfile(pollingTime: _selectedPollingTime);
      GenericMarketService().startPolling(
        interval: Duration(seconds: _selectedPollingTime.toInt()),
      );

      if (kDebugMode) {
        debugPrint(
            '[PollingSettingsPage] Saved polling interval: ${_selectedPollingTime.toInt()}s');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Data polling interval set to ${_selectedPollingTime.toInt()} seconds!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PollingSettingsPage] Error saving polling interval: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save polling interval preference: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollingOptions = [10.0, 15.0, 30.0, 60.0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polling Settings'),
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
                    'Polling Interval',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how frequently market asset prices refresh in real-time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ...pollingOptions.map((option) {
                    final isSelected = _selectedPollingTime == option;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPollingTime = option;
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
                                    '${option.toInt()} Seconds',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Refresh market assets every ${option.toInt()} seconds',
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
                      onPressed: _isSavingPolling ? null : _applyPollingTime,
                      child: _isSavingPolling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Polling Interval',
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
