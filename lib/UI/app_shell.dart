import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings_page.dart';
import 'pages/assets_menu.dart';
import 'pages/dashboard_page.dart';
import 'pages/watchlist_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late GenericMarketService _marketService;
  late WatchlistService _watchlistService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); //Listens to OS actions, app lifecycle state and system changes.
    _marketService = GenericMarketService();
    _watchlistService = WatchlistService();

    // Initialize watchlist from database
    _initializeAppData();
  }

  /// Initialize app data from database
  Future<void> _initializeAppData() async {
    await _watchlistService.initializeWatchlist();
    final profile = await DatabaseService().getUserProfile();
    final pollingSecs = profile?.pollingTime.toInt() ?? 15;
    _marketService.startPolling(interval: Duration(seconds: pollingSecs));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      if (kDebugMode) {
        debugPrint(
            '[AppShell] App data initialized and service polling started with ${pollingSecs}s interval');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint('[AppShell] App lifecycle state changed to: $state');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _marketService.dispose();
    _watchlistService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stock Market Monitor'),
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Market Monitor'),
        elevation: 0,
      ),
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (kDebugMode) {
            debugPrint('[Navigation] Tab changed: $_selectedIndex -> $index');
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Dashboard'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
          marketService: _marketService,
          watchlistService: _watchlistService,
        );
      case 1:
        return WatchlistPage(
          marketService: _marketService,
          watchlistService: _watchlistService,
        );
      case 2:
        return AssetsMenu(
          marketService: _marketService,
          watchlistService: _watchlistService,
        );
      case 3:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
