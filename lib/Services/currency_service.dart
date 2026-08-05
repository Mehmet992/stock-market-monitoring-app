import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();

  factory CurrencyService() => _instance;

  CurrencyService._internal();

  /// Default user display currency
  Currency defaultCurrency = Currency.usd;

  /// Cached exchange rates relative to 1 USD
  final Map<String, double> _usdRates = {
    'USD': 1.0,
    'TRY': 47.45,
    'EUR': 0.867,
    'GBP': 0.742,
    'JPY': 156.9,
    'CAD': 1.38,
    'AUD': 1.52,
    'CHF': 0.88,
    'CNY': 7.25,
    'INR': 83.5,
  };

  /// Dynamically updates exchange rates from live fetched MarketAssets
  void updateRatesFromMarketAssets(List<MarketAsset> assets) {
    for (final asset in assets) {
      final symbol = asset.symbol.toUpperCase();
      if (asset.regularPrice <= 0) continue;

      if (symbol == 'USDTRY=X') {
        _usdRates['TRY'] = asset.regularPrice;
      } else if (symbol == 'USDJPY=X') {
        _usdRates['JPY'] = asset.regularPrice;
      } else if (symbol == 'EURUSD=X') {
        _usdRates['EUR'] = 1.0 / asset.regularPrice;
      } else if (symbol == 'GBPUSD=X') {
        _usdRates['GBP'] = 1.0 / asset.regularPrice;
      }
    }
  }

  /// Get current exchange rate for a given Currency relative to 1 USD
  double getUsdExchangeRate(Currency targetCurrency) {
    return _usdRates[targetCurrency.code.toUpperCase()] ?? 1.0;
  }

  /// Converts a single MarketAsset to target display currency.
  MarketAsset convertAsset(MarketAsset asset, [Currency? targetCurrency]) {
    final target = targetCurrency ?? defaultCurrency;

    // 1. Forex pairs ending with =X
    if (asset.symbol.endsWith('=X')) {
      if (asset.symbol.startsWith('USD')) {
        // USD / X pair (e.g. USDTRY=X, USDJPY=X)
        // Price is already 1 USD in quote currency X
        return asset;
      } else if (asset.symbol.length >= 6 &&
          asset.symbol.substring(3, 6) == 'USD') {
        // A / USD pair (e.g. EURUSD=X, GBPUSD=X)
        if (target == Currency.usd) return asset;

        final baseCode = asset.symbol.substring(0, 3);
        final double rate = getUsdExchangeRate(target);
        final double convertedPrice = asset.regularPrice * rate;
        final double convertedPrevClose = asset.previousClose * rate;

        return asset.copyWith(
          regularPrice: convertedPrice,
          previousClose: convertedPrevClose,
          currency: target.code,
          displayName: '$baseCode / ${target.code}',
        );
      }
    }

    // 2. Standard USD-denominated assets (Gold, Crypto, Stocks)
    if (target == Currency.usd &&
        (asset.currency == 'USD' || asset.currency == '\$')) {
      return asset;
    }

    final double rate = getUsdExchangeRate(target);
    final double convertedPrice = asset.regularPrice * rate;
    final double convertedPrevClose = asset.previousClose * rate;

    return asset.copyWith(
      regularPrice: convertedPrice,
      previousClose: convertedPrevClose,
      currency: target.code,
    );
  }

  /// Batch converts a list of MarketAssets to target display currency.
  List<MarketAsset> convertAssets(List<MarketAsset> assets,
      [Currency? targetCurrency]) {
    final target = targetCurrency ?? defaultCurrency;

    updateRatesFromMarketAssets(assets);

    if (target == Currency.usd) {
      return assets;
    }

    return assets.map((asset) => convertAsset(asset, target)).toList();
  }

  /// Formats price with currency symbol and code
  String formatPrice(double price, [Currency? currency]) {
    final curr = currency ?? defaultCurrency;
    return '${price.toStringAsFixed(2)} ${curr.symbol}';
  }
}