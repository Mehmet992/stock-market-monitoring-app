import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'market_asset_config.dart';

class MarketConfig {
  static List<MarketAssetConfig> assets = [
    //Metals
    MarketAssetConfig(symbol: 'GC=F', displayName: 'Gold (Ounce)', type: AssetType.metal),
    MarketAssetConfig(symbol: 'SI=F', displayName: 'Silver', type: AssetType.metal),
    MarketAssetConfig(symbol: 'HG=F', displayName: 'Copper', type: AssetType.metal),
    MarketAssetConfig(symbol: 'PL=F', displayName: 'Platinum', type: AssetType.metal),

    // Forex
    MarketAssetConfig(symbol: 'EURUSD=X', displayName: 'EUR / USD', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDJPY=X', displayName: 'USD / JPY', type: AssetType.forex),
    MarketAssetConfig(symbol: 'GBPUSD=X', displayName: 'GBP / USD', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDTRY=X', displayName: 'USD / TRY', type: AssetType.forex),
    MarketAssetConfig(symbol: 'EURTRY=X', displayName: 'EUR / TRY', type: AssetType.forex),

    // Crypto
    MarketAssetConfig(symbol: 'BTC-USD', displayName: 'Bitcoin', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'ETH-USD', displayName: 'Ethereum', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'SOL-USD', displayName: 'Solana', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'XRP-USD', displayName: 'Ripple', type: AssetType.crypto),
    
  ];
}