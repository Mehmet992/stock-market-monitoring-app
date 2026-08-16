import 'package:stock_market_monitoring_app/ConfigClasses/market_asset_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import '../Enums/asset_types.dart';

class MarketAsset {
  final double regularPrice, previousClose;
  final String currency, symbol, displayName;
  final AssetType type;
  final String? source;

  final DateTime? addedAt;
  final double? targetAlertPrice;

  MarketAsset({
    required this.regularPrice,
    required this.previousClose,
    required this.currency,
    required this.symbol,
    required this.displayName,
    required this.type,
    this.source,
    this.addedAt,
    this.targetAlertPrice,
  });

  /// Returns the human-readable unit of measurement for this asset
  String get unitOfMeasure {
    final sym = symbol.toUpperCase();
    if (sym == 'GC=F' || sym == 'SI=F' || sym == 'PL=F' || sym == 'PA=F') {
      return 'Troy Oz';
    } else if (sym == 'CL=F') {
      return 'Barrel (bbl)';
    } else if (sym == 'HG=F') {
      return 'Lb (Pound)';
    } else if (sym == 'NG=F') {
      return 'MMBtu';
    } else if (type == AssetType.forex) {
      return 'Exchange Rate';
    } else if (type == AssetType.crypto) {
      return 'Token / Coin';
    } else if (type == AssetType.metal) {
      return 'Commodity';
    } else {
      return 'Per Share';
    }
  }

  /// Calculates adaptive decimal precision based on asset category and price magnitude
  int get decimalPrecision {
    if (type == AssetType.forex || (type == AssetType.metal && regularPrice < 100.0)) {
      return 4;
    }
    if (regularPrice > 0 && regularPrice < 1.0) {
      return 4;
    }
    return 2;
  }

  /// Formats regular price with adaptive decimal precision
  String get formattedPrice {
    return regularPrice.toStringAsFixed(decimalPrecision);
  }

  /// Formats numeric price change with adaptive decimal precision
  String formattedChange(double change) {
    final prefix = change >= 0 ? '+' : '';
    return '$prefix${change.toStringAsFixed(decimalPrecision)}';
  }

  static const Object _sentinel = Object();

  MarketAsset copyWith({
    double? regularPrice,
    double? previousClose,
    String? currency,
    String? symbol,
    String? displayName,
    AssetType? type,
    String? source,
    DateTime? addedAt,
    Object? targetAlertPrice = _sentinel,
  }) {
    return MarketAsset(
      regularPrice: regularPrice ?? this.regularPrice,
      previousClose: previousClose ?? this.previousClose,
      currency: currency ?? this.currency,
      symbol: symbol ?? this.symbol,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
      targetAlertPrice: targetAlertPrice == _sentinel
          ? this.targetAlertPrice
          : targetAlertPrice as double?,
    );
  }



  factory MarketAsset.fromJson(
      Map<String, dynamic> json, {
        required MarketAssetConfig config,
      }) {
    // 1. Single Chart API response format (v8/finance/chart)
    if (json.containsKey('chart') && json['chart'] != null) {
      final meta = json['chart']['result'][0]['meta'];
      final symbol = meta['symbol'] ?? config.symbol;
      final rawCurrency = meta['currency'] as String?;
      return MarketAsset(
        regularPrice: (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0,
        previousClose: (meta['chartPreviousClose'] as num?)?.toDouble() ?? 0.0,
        currency: CurrencyService().normalizeCurrencyCode(rawCurrency, symbol: symbol),
        symbol: symbol,
        displayName: config.displayName,
        type: config.type,
        source: 'YAHOO',
      );
    }

    // 2. Batch Quote API & Node Backend response format
    final double price = (json['price'] as num?)?.toDouble()
        ?? (json['regularMarketPrice'] as num?)?.toDouble()
        ?? 0.0;
    final double prevClose = (json['previousClose'] as num?)?.toDouble()
        ?? (json['regularMarketPreviousClose'] as num?)?.toDouble()
        ?? (json['chartPreviousClose'] as num?)?.toDouble()
        ?? 0.0;
    final symbol = json['symbol'] ?? config.symbol;
    final rawCurrency = json['currency'] as String?;

    return MarketAsset(
      regularPrice: price,
      previousClose: prevClose,
      currency: CurrencyService().normalizeCurrencyCode(rawCurrency, symbol: symbol),
      symbol: symbol,
      displayName: config.displayName,
      type: config.type,
      source: json['source'] as String?,
    );
  }

  //Factory to reconstruct MarketAssets when reading from the FireStore subcollection
  factory MarketAsset.fromFirestore(Map<String, dynamic> docData, String docId) {
    return MarketAsset(
      regularPrice: 0.0, //Mock information until the real data fetched
      previousClose: 0.0,
      currency: CurrencyService().normalizeCurrencyCode(docData['currency'] as String?, symbol: docId),
      symbol: docId,
      displayName: docData['displayName'] ?? '',
      type: AssetType.values.firstWhere(
          (e) => e.name == docData['type'],
          orElse: () => AssetType.crypto,
      ),
      addedAt: docData['addedAt'] != null
      ? (docData['addedAt'] as Timestamp).toDate()
      : null,
      targetAlertPrice: (docData['targetAlertPrice'] as num?)?.toDouble(),
    );
  }

  //Map method to save a MarketAsset when saving to Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'displayName' : displayName,
      'currency' : currency,
      'type' : type.name,
      'addedAt' : FieldValue.serverTimestamp(),
      'targetAlertPrice' : targetAlertPrice,
    };
  }
}