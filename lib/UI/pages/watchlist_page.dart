import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
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
    final theme = Theme.of(context);

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
            icon: Icons.cloud_off_rounded,
          );
        }

        return StreamBuilder<List<MarketAsset>>(
          stream: watchlistService.watchlistStream,
          builder: (context, watchlistSnapshot) {
            final watchlist = watchlistService.watchlist;

            if (watchlist.isEmpty) {
              return const EmptyStateWidget(
                title: 'Your Watchlist is Empty',
                message: 'Tap the bookmark icon on any asset to track it here in real-time.',
                icon: Icons.bookmark_border_rounded,
              );
            }

            final allAssets = marketSnapshot.data!;
            final convertedAssets = CurrencyService().convertAssets(allAssets);
            final watchlistIds = watchlist.map((a) => a.symbol).toSet();
            final watchedAssets = convertedAssets
                .where((asset) => watchlistIds.contains(asset.symbol))
                .toList();

            if (watchedAssets.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Matching Assets',
                message: 'Your watched assets are not present in current live feeds.',
                icon: Icons.search_off_rounded,
              );
            }

            return SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Watchlist Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C805).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark_rounded,
                                  size: 13,
                                  color: Color(0xFF00C805),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${watchedAssets.length} tracked',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00C805),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Watchlist',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Swipe left to remove an asset from your watchlist',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Watched Asset List
                  SliverList.builder(
                    itemCount: watchedAssets.length,
                    itemBuilder: (context, index) {
                      final asset = watchedAssets[index];
                      return Dismissible(
                        key: Key(asset.symbol),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          watchlistService.removeAsset(asset.symbol);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${asset.displayName} removed from watchlist'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5000),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 24,
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
                                  marketService: marketService,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
