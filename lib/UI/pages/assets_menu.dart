import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'category_pages/forex_page.dart';
import 'category_pages/metals_page.dart';
import 'category_pages/crypto_page.dart';
import 'category_pages/stocks_page.dart';

class AssetsMenu extends StatelessWidget {
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const AssetsMenu({
    super.key,
    required this.marketService,
    required this.watchlistService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Markets',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse market categories and live asset prices',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              tabs: const [
                Tab(text: 'Forex'),
                Tab(text: 'Metals'),
                Tab(text: 'Crypto'),
                Tab(text: 'Stocks'),
              ],
              labelColor: const Color(0xFF00C805),
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: const Color(0xFF00C805),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ForexPage(
                    marketService: marketService,
                    watchlistService: watchlistService,
                  ),
                  MetalsPage(
                    marketService: marketService,
                    watchlistService: watchlistService,
                  ),
                  CryptoPage(
                    marketService: marketService,
                    watchlistService: watchlistService,
                  ),
                  StocksPage(
                    marketService: marketService,
                    watchlistService: watchlistService,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
