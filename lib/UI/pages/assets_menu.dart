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
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
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
    );
  }
}
