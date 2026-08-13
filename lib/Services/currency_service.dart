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

  /// Normalizes raw currency strings or infers exchange currency from stock symbol suffix
  String normalizeCurrencyCode(String? rawCurrency, {String? symbol}) {
    if (rawCurrency != null && rawCurrency.trim().isNotEmpty) {
      final upper = rawCurrency.trim().toUpperCase();
      if (upper == 'USD' || upper == '\$') return 'USD';
      if (upper == 'TRY' || upper == 'TL' || upper == '₺') return 'TRY';
      if (upper == 'EUR' || upper == '€') return 'EUR';
      if (upper == 'GBP' || upper == '£') return 'GBP';
      if (upper == 'JPY' || upper == '¥') return 'JPY';
      if (upper == 'CAD' || upper == 'CA\$') return 'CAD';
      if (upper == 'AUD' || upper == 'A\$') return 'AUD';
      if (upper == 'CHF') return 'CHF';
      if (upper == 'CNY') return 'CNY';
      if (upper == 'INR' || upper == '₹') return 'INR';
      if (_usdRates.containsKey(upper)) return upper;
    }

    if (symbol != null) {
      final upperSym = symbol.trim().toUpperCase();
      if (upperSym.endsWith('.IS')) return 'TRY';
      if (upperSym.endsWith('.PA') ||
          upperSym.endsWith('.DE') ||
          upperSym.endsWith('.MI') ||
          upperSym.endsWith('.MC') ||
          upperSym.endsWith('.AS')) return 'EUR';
      if (upperSym.endsWith('.L')) return 'GBP';
      if (upperSym.endsWith('.T')) return 'JPY';
      if (upperSym.endsWith('.TO')) return 'CAD';
    }

    return 'USD';
  }

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
      } else if (symbol == 'USDCAD=X') {
        _usdRates['CAD'] = asset.regularPrice;
      } else if (symbol == 'AUDUSD=X') {
        _usdRates['AUD'] = 1.0 / asset.regularPrice;
      } else if (symbol == 'USDCHF=X') {
        _usdRates['CHF'] = asset.regularPrice;
      } else if (symbol == 'USDCNY=X') {
        _usdRates['CNY'] = asset.regularPrice;
      } else if (symbol == 'USDINR=X') {
        _usdRates['INR'] = asset.regularPrice;
      }
    }
  }

  /// Get current exchange rate for a given currency code relative to 1 USD
  double getUsdExchangeRateForCode(String currencyCode) {
    final code = normalizeCurrencyCode(currencyCode);
    return _usdRates[code] ?? 1.0;
  }

  /// Get current exchange rate for a given Currency relative to 1 USD
  double getUsdExchangeRate(Currency targetCurrency) {
    return getUsdExchangeRateForCode(targetCurrency.code);
  }

  /// Converts a single MarketAsset to target display currency.
  MarketAsset convertAsset(MarketAsset asset, [Currency? targetCurrency]) {
    final target = targetCurrency ?? defaultCurrency;
    final targetCode = target.code.toUpperCase();

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

    // 2. Standard assets (Stocks, Crypto, Metals, Commodities)
    final fromCode = normalizeCurrencyCode(asset.currency, symbol: asset.symbol);

    if (fromCode == targetCode) {
      return asset.copyWith(currency: target.code);
    }

    final double fromUsdRate = getUsdExchangeRateForCode(fromCode);
    final double toUsdRate = getUsdExchangeRate(target);

    final double factor = (fromUsdRate > 0) ? (toUsdRate / fromUsdRate) : 1.0;
    final double convertedPrice = asset.regularPrice * factor;
    final double convertedPrevClose = asset.previousClose * factor;

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

    return assets.map((asset) => convertAsset(asset, target)).toList();
  }

  /// Formats price with currency symbol and code
  String formatPrice(double price, [Currency? currency]) {
    final curr = currency ?? defaultCurrency;
    return '${price.toStringAsFixed(2)} ${curr.symbol}';
  }
}