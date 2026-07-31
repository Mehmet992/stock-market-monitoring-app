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