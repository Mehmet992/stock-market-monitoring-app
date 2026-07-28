import 'package:flutter/material.dart';

class PreferencesSettingsPage extends StatefulWidget {
  final String? section;

  const PreferencesSettingsPage({super.key, this.section});

  @override
  State<PreferencesSettingsPage> createState() =>
      _PreferencesSettingsPageState();
}

class _PreferencesSettingsPageState extends State<PreferencesSettingsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  String _selectedTheme = 'dark';
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.section == 'currency' ? 1 : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          _buildThemePage(),
          _buildCurrencyPage(),
        ],
      ),
    );
  }

  Widget _buildThemePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Theme',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize the appearance of the app',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),

          // Light Theme Option
          _buildThemeOption(
            title: 'Light Mode',
            icon: Icons.light_mode,
            isSelected: _selectedTheme == 'light',
            onTap: () {
              setState(() {
                _selectedTheme = 'light';
              });
            },
          ),
          const SizedBox(height: 16),

          // Dark Theme Option
          _buildThemeOption(
            title: 'Dark Mode',
            icon: Icons.dark_mode,
            isSelected: _selectedTheme == 'dark',
            onTap: () {
              setState(() {
                _selectedTheme = 'dark';
              });
            },
          ),
          const SizedBox(height: 16),

          // System Theme Option
          _buildThemeOption(
            title: 'System Default',
            icon: Icons.brightness_auto,
            isSelected: _selectedTheme == 'system',
            onTap: () {
              setState(() {
                _selectedTheme = 'system';
              });
            },
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Apply Theme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currency & Units',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred currency and unit display',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),

          // Currency Selection
          Text(
            'Display Currency',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildCurrencyOptions(),
          const SizedBox(height: 32),

          // Unit Settings
          Text(
            'Unit Display',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildUnitOption(
            title: 'Metric',
            subtitle: 'kg, km, °C',
            isSelected: true,
          ),
          const SizedBox(height: 8),
          _buildUnitOption(
            title: 'Imperial',
            subtitle: 'lbs, miles, °F',
            isSelected: false,
          ),
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Save Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCurrencyOptions() {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR'];
    return currencies.map((currency) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedCurrency = currency;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedCurrency == currency
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.grey[900],
              border: Border.all(
                color: _selectedCurrency == currency
                    ? Colors.blue
                    : Colors.grey[700]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedCurrency == currency)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  )
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUnitOption({
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[700]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: Colors.blue,
              size: 20,
            )
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 24,
              )
          ],
        ),
      ),
    );
  }
}
