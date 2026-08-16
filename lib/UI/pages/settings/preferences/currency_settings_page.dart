import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';

class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  bool _isSavingCurrency = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  Future<void> _loadUserCurrency() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = await _databaseService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          _selectedCurrency = userProfile.defaultCurrency.code;
          CurrencyService().defaultCurrency = userProfile.defaultCurrency;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CurrencySettingsPage] Error loading user currency: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyCurrency() async {
    setState(() {
      _isSavingCurrency = true;
    });

    final selectedEnum = Currency.fromCode(_selectedCurrency);

    try {
      await _databaseService.saveUserProfile(currency: selectedEnum);
      CurrencyService().defaultCurrency = selectedEnum;

      if (kDebugMode) {
        debugPrint(
            '[CurrencySettingsPage] Saved currency: ${selectedEnum.code}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedEnum.displayName} set as default display currency!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CurrencySettingsPage] Error saving currency: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save currency preference: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCurrency = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
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
                    'Display Currency',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred default display currency',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ..._buildCurrencyOptions(),
                  const SizedBox(height: 48),

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
                      onPressed: _isSavingCurrency ? null : _applyCurrency,
                      child: _isSavingCurrency
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Currency Preference',
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

  List<Widget> _buildCurrencyOptions() {
    return Currency.values.map((currencyOption) {
      final isSelected = _selectedCurrency == currencyOption.code;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedCurrency = currencyOption.code;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
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
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyOption.displayName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  )
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
