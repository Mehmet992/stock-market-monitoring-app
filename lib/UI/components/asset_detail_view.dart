import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'asset_chart_view.dart';

class AssetDetailView extends StatelessWidget {
  final MarketAsset asset;
  final bool isWatched;
  final VoidCallback onWatchlistToggle;
  final VoidCallback? onSetTargetPrice;

  const AssetDetailView({
    super.key,
    required this.asset,
    required this.isWatched,
    required this.onWatchlistToggle,
    this.onSetTargetPrice,
  });

  double get priceChange => asset.regularPrice - asset.previousClose;
  double get changePercent =>
      asset.previousClose > 0 ? (priceChange / asset.previousClose) * 100 : 0.0;
  bool get isPositive => priceChange >= 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyObj = Currency.fromCode(asset.currency);
    final trendColor = isPositive ? const Color(0xFF00C805) : const Color(0xFFFF5000);
    final cardBg = isDark ? const Color(0xFF11161F) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symbol & Asset Type Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                asset.symbol,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  asset.type.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Display Name
          Text(
            asset.displayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),

          // Hero Price
          Text(
            asset.formattedPrice,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),

          // Daily Change Pill + "Today"
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      color: trendColor,
                      size: 20,
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${asset.formattedChange(priceChange)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive Chart
          AssetChartView(
            symbol: asset.symbol,
            currency: asset.currency,
          ),
          const SizedBox(height: 16),

          // Key Statistics Section
          Text(
            'Key Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                _buildStatRow(
                  theme,
                  label: 'Previous Close',
                  value: asset.previousClose.toStringAsFixed(asset.decimalPrecision),
                ),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                _buildStatRow(
                  theme,
                  label: 'Currency',
                  value: '${currencyObj.name} (${currencyObj.symbol})',
                ),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                _buildStatRow(
                  theme,
                  label: 'Unit of Measure',
                  value: asset.unitOfMeasure,
                ),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                _buildStatRow(
                  theme,
                  label: 'Asset Category',
                  value: asset.type.toString().split('.').last.toUpperCase(),
                ),
                if (isWatched) ...[
                  Divider(
                    height: 24,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  _buildStatRow(
                    theme,
                    label: 'Target Alert Price',
                    value: (asset.targetAlertPrice != null && asset.targetAlertPrice! > 0)
                        ? '${asset.targetAlertPrice!.toStringAsFixed(asset.decimalPrecision)} ${currencyObj.symbol}'
                        : 'Not Set',
                    valueColor: (asset.targetAlertPrice != null && asset.targetAlertPrice! > 0)
                        ? const Color(0xFF00C805)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Primary Watchlist Pill Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onWatchlistToggle,
              icon: Icon(
                isWatched ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded,
                size: 20,
              ),
              label: Text(
                isWatched ? 'Remove from Watchlist' : 'Add to Watchlist',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWatched
                    ? (isDark ? const Color(0xFF1E2633) : const Color(0xFFF0F3F6))
                    : const Color(0xFF00C805),
                foregroundColor: isWatched
                    ? theme.colorScheme.onSurface
                    : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: isWatched
                      ? BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                        )
                      : BorderSide.none,
                ),
              ),
            ),
          ),

          // Target Price Alert Button
          if (isWatched && onSetTargetPrice != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onSetTargetPrice,
                icon: const Icon(
                  Icons.notifications_active_rounded,
                  size: 20,
                ),
                label: Text(
                  (asset.targetAlertPrice != null && asset.targetAlertPrice! > 0)
                      ? 'Edit Target Price (${asset.targetAlertPrice!.toStringAsFixed(asset.decimalPrecision)})'
                      : 'Set Price Alert',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    ThemeData theme, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
