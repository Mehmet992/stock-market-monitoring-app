import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';

class AssetCard extends StatelessWidget {
  final MarketAsset asset;
  final bool isWatched;
  final VoidCallback onWatchlistToggle;
  final VoidCallback onTap;

  const AssetCard({
    Key? key,
    required this.asset,
    required this.isWatched,
    required this.onWatchlistToggle,
    required this.onTap,
  }) : super(key: key);

  double get priceChange => asset.regularPrice - asset.previousClose;
  double get changePercent => (priceChange / asset.previousClose) * 100;
  bool get isPositive => priceChange >= 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.symbol,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${asset.regularPrice.toStringAsFixed(2)} ${asset.currency}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green[400] : Colors.red[400],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onWatchlistToggle,
                child: Icon(
                  isWatched ? Icons.favorite : Icons.favorite_border,
                  color: isWatched ? Colors.red[400] : Colors.grey[500],
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
