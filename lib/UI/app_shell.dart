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
    WidgetsBinding.instance.addObserver(this);
    _marketService = GenericMarketService();
    _watchlistService = WatchlistService();

    // Initialize watchlist from database
    _initializeAppData();
  }

  /// Initialize app data from database
  Future<void> _initializeAppData() async {
    await _watchlistService.initializeWatchlist();
    final profile = await DatabaseService().getUserProfile();
    final pollingSecs = profile?.pollingTime.toInt() ?? 30;
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
    _marketService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C805)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Syncing market data...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(
            marketService: _marketService,
            watchlistService: _watchlistService,
          ),
          WatchlistPage(
            marketService: _marketService,
            watchlistService: _watchlistService,
          ),
          AssetsMenu(
            marketService: _marketService,
            watchlistService: _watchlistService,
          ),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0E14) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (kDebugMode) {
              debugPrint('[Navigation] Tab changed: $_selectedIndex -> $index');
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF00C805),
          unselectedItemColor: isDark
              ? const Color(0xFF717D91)
              : const Color(0xFF8E9BAE),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.candlestick_chart_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.candlestick_chart_rounded, size: 22),
              ),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.bookmark_border_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.bookmark_rounded, size: 22),
              ),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.travel_explore_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.travel_explore_rounded, size: 22),
              ),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.tune_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3.0),
                child: Icon(Icons.tune_rounded, size: 22),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
