import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_market_monitoring_app/ConfigClasses/market_asset_config.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';

import 'ConfigClasses/market_config.dart';
import 'Models/market_asset.dart';

/// Base URL for the central Node.js backend aggregator deployed on Render
const String kBackendBaseUrl = 'https://stock-market-backend-q5vu.onrender.com/api/v1';

/// Shared secret header key to authenticate mobile app requests to the central backend
const String kAppSecretKey = 'stock_market_app_secret_2026_secure_key';

/// Fetches all market assets from the central Node.js backend proxy.
///
/// Reduces mobile network overhead, bypasses mobile IP blocks, and returns
/// normalized real-time asset quotes cached on the central server.
Future<List<MarketAsset>> fetchAllAssetsConcurrently({int chunkSize = 20}) async {
  try {
    final Uri url = Uri.parse('$kBackendBaseUrl/assets');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'x-app-secret-key': kAppSecretKey,
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final List<dynamic> dataList = jsonData['data'] ?? [];

      final List<MarketAsset> assets = [];
      for (final item in dataList) {
        if (item is Map<String, dynamic>) {
          final symbol = item['symbol'] ?? '';
          final config = MarketConfig.assets.firstWhere(
            (c) => c.symbol.toLowerCase() == symbol.toString().toLowerCase(),
            orElse: () => MarketAssetConfig(
              symbol: symbol,
              displayName: item['displayName'] ?? symbol,
              type: _parseAssetType(item['type']),
            ),
          );

          assets.add(MarketAsset.fromJson(item, config: config));
        }
      }

      if (assets.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[API] Successfully fetched ${assets.length} assets from Node.js backend.');
        }
        return assets;
      }
    } else {
      if (kDebugMode) {
        debugPrint('[API] Node backend HTTP error: ${response.statusCode}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[API] Error fetching from Node backend: $e');
    }
  }

  return <MarketAsset>[];
}

/// Helper parser for asset types from string
AssetType _parseAssetType(dynamic typeStr) {
  switch (typeStr?.toString().toLowerCase()) {
    case 'stock':
      return AssetType.stock;
    case 'crypto':
      return AssetType.crypto;
    case 'metal':
      return AssetType.metal;
    case 'forex':
      return AssetType.forex;
    default:
      return AssetType.stock;
  }
}