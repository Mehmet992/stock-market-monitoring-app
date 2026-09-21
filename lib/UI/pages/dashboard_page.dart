import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
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
    super.key,
    required this.marketService,
    required this.watchlistService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketAsset>>(
      stream: watchlistService.watchlistStream,
      initialData: watchlistService.watchlist,
      builder: (context, watchlistSnapshot) {
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

          final rawAssets = snapshot.data!;
          final assets = CurrencyService().convertAssets(rawAssets);

          final watchedAssets = assets
              .where((asset) => watchlistService.isWatching(asset.symbol))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Overview',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${DateTime.now().toLocal()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (watchedAssets.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Your Watchlist (${watchedAssets.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: watchedAssets.length,
                  itemBuilder: (context, index) {
                    final asset = watchedAssets[index];
                    return AssetCard(
                      asset: asset,
                      isWatched: true,
                      onWatchlistToggle: () {
                        watchlistService.toggleWatchlist(asset);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssetDetailPage(
                              asset: asset,
                              watchlistService: watchlistService,
                              marketService: marketService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'All Assets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  final isWatched = watchlistService.isWatching(asset.symbol);
                  return AssetCard(
                    asset: asset,
                    isWatched: isWatched,
                    onWatchlistToggle: () {
                      watchlistService.toggleWatchlist(asset);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssetDetailPage(
                            asset: asset,
                            watchlistService: watchlistService,
                            marketService: marketService,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],
          );
        },
      );
    },
  );
}
}
