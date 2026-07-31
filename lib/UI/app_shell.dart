import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    WidgetsBinding.instance.addObserver(this);
    _marketService = GenericMarketService();
    _watchlistService = WatchlistService();

    // Initialize watchlist from database
    _initializeAppData();
  }

  /// Initialize app data from database
  Future<void> _initializeAppData() async {
    await _watchlistService.initializeWatchlist();
    _marketService.startPolling(interval: const Duration(seconds: 10));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      if (kDebugMode) {
        debugPrint('[AppShell] App data initialized and service polling started');
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
          backgroundColor: Colors.blueGrey[900],
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Market Monitor'),
        backgroundColor: Colors.blueGrey[900],
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
        backgroundColor: Colors.blueGrey[900],
        selectedItemColor: Colors.green[400],
        unselectedItemColor: Colors.grey[400],
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
