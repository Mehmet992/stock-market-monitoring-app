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
    final currencyObj = Currency.fromCode(asset.currency);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            asset.displayName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            asset.symbol,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  asset.formattedPrice,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${currencyObj.code} (${currencyObj.symbol}) • Unit: ${asset.unitOfMeasure}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    asset.formattedChange(priceChange),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green[400] : Colors.red[400],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
              Column(
                children: [
                  Text(
                    'Change %',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green[400] : Colors.red[400],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AssetChartView(
            symbol: asset.symbol,
            currency: asset.currency,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Previous Close', asset.previousClose.toStringAsFixed(asset.decimalPrecision)),
                const SizedBox(height: 12),
                _buildDetailRow('Unit of Measure', asset.unitOfMeasure),
                const SizedBox(height: 12),
                _buildDetailRow('Currency', '${currencyObj.name} (${currencyObj.symbol})'),
                const SizedBox(height: 12),
                _buildDetailRow('Type', asset.type.toString().split('.').last.toUpperCase()),
                if (isWatched) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Target Price',
                    (asset.targetAlertPrice != null && asset.targetAlertPrice! > 0)
                        ? '${asset.targetAlertPrice!.toStringAsFixed(asset.decimalPrecision)} ${currencyObj.symbol}'
                        : 'Not initialized',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onWatchlistToggle,
              icon: Icon(
                isWatched ? Icons.favorite : Icons.favorite_border,
              ),
              label: Text(
                isWatched ? 'Remove from Watchlist' : 'Add to Watchlist',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWatched ? Colors.red[400] : Colors.green[400],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (isWatched && onSetTargetPrice != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSetTargetPrice,
                icon: const Icon(Icons.notifications_active),
                label: Text(
                  (asset.targetAlertPrice != null && asset.targetAlertPrice! > 0)
                      ? 'Edit Target Price'
                      : 'Set Target Price',
                  style: const TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
