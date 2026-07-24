import 'package:stock_market_monitoring_app/ConfigClasses/market_asset_config.dart';

import '../Enums/asset_types.dart';

class MarketAsset {
  final double regularPrice, previousClose;
  final String currency, symbol, displayName;
  final AssetType type;

  MarketAsset({
    required this.regularPrice,
    required this.previousClose,
    required this.currency,
    required this.symbol,
    required this.displayName,
    required this.type,
  });

  factory MarketAsset.fromJson(
      Map<String, dynamic> json, {
        required MarketAssetConfig config,
      }) {

    final meta = json['chart']['result'][0]['meta'];
    return MarketAsset(
      regularPrice: (meta['regularMarketPrice'] as num).toDouble(),
      previousClose: (meta['chartPreviousClose'] as num).toDouble(),
      currency: meta['currency'] ?? 'UNKNOWN',
      symbol: meta['symbol'] ?? config.symbol,
      displayName: config.displayName,
      type: config.type,
    );
  }
}
