import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'market_asset_config.dart';

class MarketConfig {
  static List<MarketAssetConfig> assets = [
    // ==========================================
    // 1. POPULAR US & GLOBAL STOCKS
    // ==========================================
    // Tech & AI Giants
    MarketAssetConfig(symbol: 'NVDA', displayName: 'NVIDIA', type: AssetType.stock),
    MarketAssetConfig(symbol: 'AAPL', displayName: 'Apple', type: AssetType.stock),
    MarketAssetConfig(symbol: 'MSFT', displayName: 'Microsoft', type: AssetType.stock),
    MarketAssetConfig(symbol: 'GOOGL', displayName: 'Alphabet (Google)', type: AssetType.stock),
    MarketAssetConfig(symbol: 'AMZN', displayName: 'Amazon', type: AssetType.stock),
    MarketAssetConfig(symbol: 'META', displayName: 'Meta (Facebook)', type: AssetType.stock),
    MarketAssetConfig(symbol: 'TSLA', displayName: 'Tesla', type: AssetType.stock),
    MarketAssetConfig(symbol: 'AMD', displayName: 'AMD', type: AssetType.stock),
    MarketAssetConfig(symbol: 'PLTR', displayName: 'Palantir', type: AssetType.stock),
    MarketAssetConfig(symbol: 'TSM', displayName: 'TSMC', type: AssetType.stock),

    // Finance & Industry
    MarketAssetConfig(symbol: 'JPM', displayName: 'JPMorgan Chase', type: AssetType.stock),
    MarketAssetConfig(symbol: 'V', displayName: 'Visa', type: AssetType.stock),
    MarketAssetConfig(symbol: 'WMT', displayName: 'Walmart', type: AssetType.stock),
    MarketAssetConfig(symbol: 'DIS', displayName: 'Walt Disney', type: AssetType.stock),
    MarketAssetConfig(symbol: 'NFLX', displayName: 'Netflix', type: AssetType.stock),

    // Market Index ETFs (Essential for macro monitoring)
    MarketAssetConfig(symbol: 'SPY', displayName: 'S&P 500 ETF', type: AssetType.stock),
    MarketAssetConfig(symbol: 'QQQ', displayName: 'Nasdaq 100 ETF', type: AssetType.stock),
    MarketAssetConfig(symbol: 'DIA', displayName: 'Dow Jones ETF', type: AssetType.stock),

    // ==========================================
    // 2. CRYPTOCURRENCIES (Format: SYMBOL-USD)
    // ==========================================
    MarketAssetConfig(symbol: 'BTC-USD', displayName: 'Bitcoin', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'ETH-USD', displayName: 'Ethereum', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'SOL-USD', displayName: 'Solana', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'BNB-USD', displayName: 'Binance Coin', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'XRP-USD', displayName: 'Ripple', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'ADA-USD', displayName: 'Cardano', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'DOGE-USD', displayName: 'Dogecoin', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'AVAX-USD', displayName: 'Avalanche', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'DOT-USD', displayName: 'Polkadot', type: AssetType.crypto),
    MarketAssetConfig(symbol: 'LINK-USD', displayName: 'Chainlink', type: AssetType.crypto),

    // ==========================================
    // 3. COMMODITIES & METALS (Futures end with =F)
    // ==========================================
    MarketAssetConfig(symbol: 'GC=F', displayName: 'Gold Futures', type: AssetType.metal),
    MarketAssetConfig(symbol: 'SI=F', displayName: 'Silver Futures', type: AssetType.metal),
    MarketAssetConfig(symbol: 'HG=F', displayName: 'Copper Futures', type: AssetType.metal),
    MarketAssetConfig(symbol: 'PL=F', displayName: 'Platinum Futures', type: AssetType.metal),
    MarketAssetConfig(symbol: 'PA=F', displayName: 'Palladium Futures', type: AssetType.metal),

    // Energy & Agriculture (Optional Commodities)
    MarketAssetConfig(symbol: 'CL=F', displayName: 'Crude Oil (WTI)', type: AssetType.metal),
    MarketAssetConfig(symbol: 'NG=F', displayName: 'Natural Gas', type: AssetType.metal),

    // ==========================================
    // 4. FOREX CURRENCY PAIRS (Format: PAIR=X)
    // ==========================================
    MarketAssetConfig(symbol: 'EURUSD=X', displayName: 'EUR / USD', type: AssetType.forex),
    MarketAssetConfig(symbol: 'GBPUSD=X', displayName: 'GBP / USD', type: AssetType.forex),
    MarketAssetConfig(symbol: 'AUDUSD=X', displayName: 'AUD / USD', type: AssetType.forex),
    MarketAssetConfig(symbol: 'NZDUSD=X', displayName: 'NZD / USD', type: AssetType.forex),

    MarketAssetConfig(symbol: 'USDJPY=X', displayName: 'USD / JPY', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDCHF=X', displayName: 'USD / CHF', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDCAD=X', displayName: 'USD / CAD', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDTRY=X', displayName: 'USD / TRY', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDCNY=X', displayName: 'USD / CNY', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDINR=X', displayName: 'USD / INR', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDKRW=X', displayName: 'USD / KRW', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDMXN=X', displayName: 'USD / MXN', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDBRL=X', displayName: 'USD / BRL', type: AssetType.forex),
    MarketAssetConfig(symbol: 'USDSEK=X', displayName: 'USD / SEK', type: AssetType.forex),
  ];
}