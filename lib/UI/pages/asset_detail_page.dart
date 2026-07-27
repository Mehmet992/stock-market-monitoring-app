import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import '../components/asset_detail_view.dart';

class AssetDetailPage extends StatelessWidget {
  final MarketAsset asset;
  final WatchlistService watchlistService;

  const AssetDetailPage({
    Key? key,
    required this.asset,
    required this.watchlistService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: watchlistService.watchlistStream,
      builder: (context, snapshot) {
        final isWatched = watchlistService.isWatching(asset.symbol);

        return Scaffold(
          appBar: AppBar(
            title: Text(asset.displayName),
            backgroundColor: Colors.blueGrey[900],
            elevation: 0,
          ),
          body: AssetDetailView(
            asset: asset,
            isWatched: isWatched,
            onWatchlistToggle: () {
              watchlistService.toggleWatchlist(asset.symbol);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isWatched
                        ? '${asset.displayName} removed from watchlist'
                        : '${asset.displayName} added to watchlist',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: isWatched ? Colors.red[400] : Colors.green[400],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
