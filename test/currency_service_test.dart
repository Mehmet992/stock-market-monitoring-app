import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';

void main() {
  group('CurrencyService tests', () {
    final currencyService = CurrencyService();

    test('USD conversion returns unchanged asset when default is USD', () {
      final asset = MarketAsset(
        regularPrice: 100.0,
        previousClose: 90.0,
        currency: 'USD',
        symbol: 'BTC-USD',
        displayName: 'Bitcoin',
        type: AssetType.crypto,
      );

      final converted = currencyService.convertAsset(asset, Currency.usd);
      expect(converted.regularPrice, 100.0);
      expect(converted.currency, 'USD');
    });

    test('Converts USD asset to TRY with rate correctly', () {
      final asset = MarketAsset(
        regularPrice: 100.0,
        previousClose: 90.0,
        currency: 'USD',
        symbol: 'BTC-USD',
        displayName: 'Bitcoin',
        type: AssetType.crypto,
      );

      currencyService.updateRatesFromMarketAssets([
        MarketAsset(
          regularPrice: 40.0,
          previousClose: 40.0,
          currency: 'TRY',
          symbol: 'USDTRY=X',
          displayName: 'USD / TRY',
          type: AssetType.forex,
        )
      ]);

      final converted = currencyService.convertAsset(asset, Currency.tryLira);
      expect(converted.regularPrice, 4000.0);
      expect(converted.previousClose, 3600.0);
      expect(converted.currency, 'TRY');
      expect(converted.displayName, 'Bitcoin');
    });

    test('Converts EUR/USD forex pair to EUR/TRY when display is TRY', () {
      final eurUsdAsset = MarketAsset(
        regularPrice: 1.15,
        previousClose: 1.10,
        currency: 'USD',
        symbol: 'EURUSD=X',
        displayName: 'EUR / USD',
        type: AssetType.forex,
      );

      currencyService.updateRatesFromMarketAssets([
        MarketAsset(
          regularPrice: 40.0,
          previousClose: 40.0,
          currency: 'TRY',
          symbol: 'USDTRY=X',
          displayName: 'USD / TRY',
          type: AssetType.forex,
        )
      ]);

      final converted = currencyService.convertAsset(eurUsdAsset, Currency.tryLira);
      expect(converted.regularPrice, 46.0); // 1.15 * 40.0
      expect(converted.currency, 'TRY');
      expect(converted.displayName, 'EUR / TRY');
    });

    test('Keeps USD/TRY forex pair unchanged when display is TRY', () {
      final usdTryAsset = MarketAsset(
        regularPrice: 40.0,
        previousClose: 39.5,
        currency: 'TRY',
        symbol: 'USDTRY=X',
        displayName: 'USD / TRY',
        type: AssetType.forex,
      );

      final converted = currencyService.convertAsset(usdTryAsset, Currency.tryLira);
      expect(converted.regularPrice, 40.0);
      expect(converted.currency, 'TRY');
      expect(converted.displayName, 'USD / TRY');
    });

    test('Formats price with currency symbol', () {
      final formatted = currencyService.formatPrice(123.45, Currency.tryLira);
      expect(formatted, '123.45 ₺');
    });
  });
}
