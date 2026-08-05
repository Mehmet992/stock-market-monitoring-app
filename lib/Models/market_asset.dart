import 'package:stock_market_monitoring_app/ConfigClasses/market_asset_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Enums/asset_types.dart';

class MarketAsset {
  final double regularPrice, previousClose;
  final String currency, symbol, displayName;
  final AssetType type;

  final DateTime? addedAt;
  final double? targetAlertPrice;

  MarketAsset({
    required this.regularPrice,
    required this.previousClose,
    required this.currency,
    required this.symbol,
    required this.displayName,
    required this.type,
    this.addedAt,
    this.targetAlertPrice,
  });

  MarketAsset copyWith({
    double? regularPrice,
    double? previousClose,
    String? currency,
    String? symbol,
    String? displayName,
    AssetType? type,
    DateTime? addedAt,
    double? targetAlertPrice,
  }) {
    return MarketAsset(
      regularPrice: regularPrice ?? this.regularPrice,
      previousClose: previousClose ?? this.previousClose,
      currency: currency ?? this.currency,
      symbol: symbol ?? this.symbol,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      targetAlertPrice: targetAlertPrice ?? this.targetAlertPrice,
    );
  }



  factory MarketAsset.fromJson(
      Map<String, dynamic> json, {
        required MarketAssetConfig config,
      }) {
    // 1. Single Chart API response format (v8/finance/chart)
    if (json.containsKey('chart') && json['chart'] != null) {
      final meta = json['chart']['result'][0]['meta'];
      return MarketAsset(
        regularPrice: (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0,
        previousClose: (meta['chartPreviousClose'] as num?)?.toDouble() ?? 0.0,
        currency: meta['currency'] ?? 'UNKNOWN',
        symbol: meta['symbol'] ?? config.symbol,
        displayName: config.displayName,
        type: config.type,
      );
    }

    // 2. Batch Quote API response format (v7/finance/quote)
    final double price = (json['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
    final double prevClose = (json['regularMarketPreviousClose'] as num?)?.toDouble()
        ?? (json['chartPreviousClose'] as num?)?.toDouble()
        ?? 0.0;

    return MarketAsset(
      regularPrice: price,
      previousClose: prevClose,
      currency: json['currency'] ?? 'UNKNOWN',
      symbol: json['symbol'] ?? config.symbol,
      displayName: config.displayName,
      type: config.type,
    );
  }

  //Factory to reconstruct MarketAssets when reading from the FireStore subcollection
  factory MarketAsset.fromFirestore(Map<String, dynamic> docData, String docId) {
    return MarketAsset(
      regularPrice: 0.0, //Mock information until the real data fetched
      previousClose: 0.0,
      currency: docData['currency'] ?? 'USD',
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