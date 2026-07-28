import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/UI/pages/settings_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/watchlist_page.dart';
import 'pages/category_pages/forex_page.dart';
import 'pages/category_pages/metals_page.dart';
import 'pages/category_pages/crypto_page.dart';
import 'pages/category_pages/stocks_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late GenericMarketService _marketService;
  late WatchlistService _watchlistService;

  @override
  void initState() {
    super.initState();
    _marketService = GenericMarketService();
    _watchlistService = WatchlistService();
    _marketService.startPolling(interval: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _marketService.dispose();
    _watchlistService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            label: 'Dashboard',
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
        return _buildAssetsMenu();
      case 3:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAssetsMenu() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Forex'),
              Tab(text: 'Metals'),
              Tab(text: 'Crypto'),
              Tab(text: 'Stocks'),
            ],
            labelColor: Colors.green[400],
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.green[400],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ForexPage(
                  marketService: _marketService,
                  watchlistService: _watchlistService,
                ),
                MetalsPage(
                  marketService: _marketService,
                  watchlistService: _watchlistService,
                ),
                CryptoPage(
                  marketService: _marketService,
                  watchlistService: _watchlistService,
                ),
                StocksPage(
                  marketService: _marketService,
                  watchlistService: _watchlistService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
