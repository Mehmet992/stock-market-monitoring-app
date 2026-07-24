import 'package:stock_market_monitoring_app/Enums/asset_types.dart';

class MarketAssetConfig {
  final String symbol;
  final String displayName;
  final AssetType type;

  MarketAssetConfig(
  {
    required this.symbol,
    required this.displayName,
    required this.type,
  });

  String get url => 'https://query2.finance.yahoo.com/v8/finance/chart/$symbol';
}