import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import '../components/asset_card.dart';
import '../components/state_widgets.dart';
import 'asset_detail_page.dart';

class DashboardPage extends StatelessWidget {
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const DashboardPage({
    Key? key,
    required this.marketService,
    required this.watchlistService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: watchlistService.watchlistStream,
      initialData: watchlistService.watchlist,
      builder: (context, snapshot) {
        return StreamBuilder<List<MarketAsset>>(
        stream: marketService.marketDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSpinner(message: 'Loading market data...');
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              message: snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Data Available',
              message: 'Unable to fetch market data. Please check your connection.',
              icon: Icons.cloud_off,
            );
          }

          final assets = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Overview',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${DateTime.now().toLocal()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (watchlistService.watchlist.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Your Watchlist (${watchlistService.watchlist.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[400],
                      ),
                    ),
                  ),
                  ..._buildWatchlistAssets(assets, context),
                  const SizedBox(height: 24),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'All Assets',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ..._buildAllAssets(assets, context),
              ],
            ),
          );
        },
      );},
    );
  }

  List<Widget> _buildWatchlistAssets(List<MarketAsset> assets, BuildContext context) {
    final watchedAssets = assets
        .where((asset) => watchlistService.isWatching(asset.symbol))
        .toList();

    return watchedAssets.map((asset) {
      return AssetCard(
        asset: asset,
        isWatched: true,
        onWatchlistToggle: () {
          watchlistService.toggleWatchlist(asset.symbol);
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailPage(
                asset: asset,
                watchlistService: watchlistService,
              ),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildAllAssets(List<MarketAsset> assets, BuildContext context) {
    return assets.map((asset) {
      final isWatched = watchlistService.isWatching(asset.symbol);
      return AssetCard(
        asset: asset,
        isWatched: isWatched,
        onWatchlistToggle: () {
          watchlistService.toggleWatchlist(asset.symbol);
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailPage(
                asset: asset,
                watchlistService: watchlistService,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}
