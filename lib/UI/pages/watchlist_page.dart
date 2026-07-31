import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import '../components/asset_card.dart';
import '../components/state_widgets.dart';
import 'asset_detail_page.dart';

class WatchlistPage extends StatelessWidget {
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const WatchlistPage({
    super.key,
    required this.marketService,
    required this.watchlistService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketAsset>>(
      stream: marketService.marketDataStream,
      builder: (context, marketSnapshot) {
        if (marketSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingSpinner(message: 'Loading market data...');
        }

        if (marketSnapshot.hasError) {
          return ErrorDisplay(
            message: marketSnapshot.error.toString(),
          );
        }

        if (!marketSnapshot.hasData || marketSnapshot.data!.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Data Available',
            message: 'Unable to fetch market data. Please check your connection.',
            icon: Icons.cloud_off,
          );
        }

        return StreamBuilder<List<MarketAsset>>(
          stream: watchlistService.watchlistStream,
          builder: (context, watchlistSnapshot) {
            final watchlist = watchlistService.watchlist;

            if (watchlist.isEmpty) {
              return const EmptyStateWidget(
                title: 'Your Watchlist is Empty',
                message: 'Add assets from other pages to see them here.',
                icon: Icons.favorite_border,
              );
            }

            final allAssets = marketSnapshot.data!;
            final watchlistIds = watchlist.map((a) => a.symbol);
            final watchedAssets = allAssets
                .where((asset) => watchlistIds.contains(asset.symbol))
                .toList();

            if (watchedAssets.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Matching Assets',
                message: 'Your watched assets are not in the current data.',
                icon: Icons.search_off,
              );
            }

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
                          'My Watchlist',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${watchedAssets.length} asset${watchedAssets.length > 1 ? 's' : ''} tracked',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...watchedAssets.map((asset) {
                    return Dismissible(
                      key: Key(asset.symbol),
                      onDismissed: (direction) {
                        watchlistService.removeAsset(asset.symbol);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${asset.displayName} removed'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.red[400],
                          ),
                        );
                      },
                      background: Container(
                        color: Colors.red[400],
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: AssetCard(
                        asset: asset,
                        isWatched: true,
                        onWatchlistToggle: () {
                          watchlistService.removeAsset(asset.symbol);
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
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
