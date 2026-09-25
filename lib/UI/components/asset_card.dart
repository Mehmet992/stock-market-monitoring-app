import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';

class AssetCard extends StatelessWidget {
  final MarketAsset asset;
  final bool isWatched;
  final VoidCallback onWatchlistToggle;
  final VoidCallback onTap;

  const AssetCard({
    super.key,
    required this.asset,
    required this.isWatched,
    required this.onWatchlistToggle,
    required this.onTap,
  });

  double get priceChange => asset.regularPrice - asset.previousClose;
  double get changePercent =>
      asset.previousClose > 0 ? (priceChange / asset.previousClose) * 100 : 0.0;
  bool get isPositive => priceChange >= 0;

  String get formattedPrice {
    final currencyObj = Currency.fromCode(asset.currency);
    return '${asset.formattedPrice} ${currencyObj.symbol}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bullColor = const Color(0xFF00C805);
    final bearColor = const Color(0xFFFF5000);
    final trendColor = isPositive ? bullColor : bearColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131821) : const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Left Column: Ticker & Display Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        asset.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Column: Price & Change Pill Chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Watchlist Bookmark Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onWatchlistToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isWatched ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: isWatched
                          ? const Color(0xFF00C805)
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

