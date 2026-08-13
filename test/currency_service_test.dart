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

    test('Converts TRY asset (THYAO.IS) to USD correctly', () {
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

      final tryAsset = MarketAsset(
        regularPrice: 300.0,
        previousClose: 290.0,
        currency: 'TRY',
        symbol: 'THYAO.IS',
        displayName: 'Türk Hava Yolları',
        type: AssetType.stock,
      );

      final convertedUsd = currencyService.convertAsset(tryAsset, Currency.usd);
      expect(convertedUsd.regularPrice, 7.5); // 300 / 40.0 = 7.5
      expect(convertedUsd.previousClose, 7.25); // 290 / 40.0 = 7.25
      expect(convertedUsd.currency, 'USD');
    });

    test('Converts TRY asset (THYAO.IS) to EUR correctly', () {
      currencyService.updateRatesFromMarketAssets([
        MarketAsset(
          regularPrice: 40.0,
          previousClose: 40.0,
          currency: 'TRY',
          symbol: 'USDTRY=X',
          displayName: 'USD / TRY',
          type: AssetType.forex,
        ),
        MarketAsset(
          regularPrice: 1.25, // 1 EUR = 1.25 USD -> EUR rate = 0.8
          previousClose: 1.25,
          currency: 'USD',
          symbol: 'EURUSD=X',
          displayName: 'EUR / USD',
          type: AssetType.forex,
        ),
      ]);

      final tryAsset = MarketAsset(
        regularPrice: 300.0,
        previousClose: 290.0,
        currency: 'TRY',
        symbol: 'THYAO.IS',
        displayName: 'Türk Hava Yolları',
        type: AssetType.stock,
      );

      final convertedEur = currencyService.convertAsset(tryAsset, Currency.eur);
      // 300 TRY in USD = 7.5 USD. 7.5 USD in EUR = 7.5 * 0.8 = 6.0 EUR
      expect(convertedEur.regularPrice, 6.0);
      expect(convertedEur.currency, 'EUR');
    });

    test('Normalizes currency codes and symbol suffixes', () {
      expect(currencyService.normalizeCurrencyCode('TL'), 'TRY');
      expect(currencyService.normalizeCurrencyCode('₺'), 'TRY');
      expect(currencyService.normalizeCurrencyCode('€'), 'EUR');
      expect(currencyService.normalizeCurrencyCode(null, symbol: 'THYAO.IS'), 'TRY');
      expect(currencyService.normalizeCurrencyCode(null, symbol: 'AIR.PA'), 'EUR');
      expect(currencyService.normalizeCurrencyCode(null, symbol: 'BARC.L'), 'GBP');
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

    test('MarketAsset.copyWith clears targetAlertPrice when explicitly set to null', () {
      final asset = MarketAsset(
        regularPrice: 100.0,
        previousClose: 95.0,
        currency: 'USD',
        symbol: 'AAPL',
        displayName: 'Apple',
        type: AssetType.stock,
        targetAlertPrice: 150.0,
      );

      expect(asset.targetAlertPrice, 150.0);

      // copyWith without targetAlertPrice retains existing value
      final copiedSame = asset.copyWith(regularPrice: 105.0);
      expect(copiedSame.regularPrice, 105.0);
      expect(copiedSame.targetAlertPrice, 150.0);

      // copyWith with explicit null clears targetAlertPrice
      final copiedCleared = asset.copyWith(targetAlertPrice: null);
      expect(copiedCleared.targetAlertPrice, null);
    });
  });
}


