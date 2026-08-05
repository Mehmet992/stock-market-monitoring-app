import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_market_monitoring_app/ConfigClasses/market_asset_config.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';

import 'ConfigClasses/market_config.dart';
import 'Models/market_asset.dart';

class YahooAuthManager {
  static String? _cookie;
  static String? _crumb;

  static Future<String?> getCrumb() async {
    if (_crumb != null && _cookie != null) return _crumb;
    try {
      final initResp = await http.get(
        Uri.parse('https://fc.yahoo.com'),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
      );
      _cookie = initResp.headers['set-cookie']?.split(';').first;

      final crumbResp = await http.get(
        Uri.parse('https://query2.finance.yahoo.com/v1/test/getcrumb'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Cookie':? YahooAuthManager.cookie,
        },
      );

      if (crumbResp.statusCode == 200 && crumbResp.body.trim().isNotEmpty) {
        _crumb = crumbResp.body.trim();
        return _crumb;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[YahooAuthManager] Error obtaining crumb/cookie: $e');
      }
    }
    return null;
  }

  static void reset() {
    _cookie = null;
    _crumb = null;
  }

  static String? get cookie => _cookie;
}

/// Fetches all market assets in chunked batch HTTP requests.
///
/// Reduces network overhead by requesting multiple symbols per HTTP GET using
/// Yahoo Finance quote API with crumb authentication, falling back to individual
/// concurrent chart endpoints if batching fails.
Future<List<MarketAsset>> fetchAllAssetsConcurrently({int chunkSize = 20}) async {
  final crumb = await YahooAuthManager.getCrumb();

  if (crumb != null) {
    try {
      final List<List<MarketAssetConfig>> chunks = MarketConfig.assets.chunk(chunkSize);

      final Iterable<Future<List<MarketAsset>>> chunkRequests = chunks.map((chunk) async {
        final String symbolsParam = chunk.map((config) => config.symbol).join(',');
        final ts = DateTime.now().millisecondsSinceEpoch;
        final Uri url = Uri.parse('https://query2.finance.yahoo.com/v7/finance/quote?symbols=$symbolsParam&crumb=$crumb&_nc=$ts');

        http.Response response = await http.get(
          url,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Cookie':? YahooAuthManager.cookie,
          },
        );

        // Retry once on 401 in case crumb expired
        if (response.statusCode == 401) {
          YahooAuthManager.reset();
          final freshCrumb = await YahooAuthManager.getCrumb();
          if (freshCrumb != null) {
            final retryUrl = Uri.parse('https://query2.finance.yahoo.com/v7/finance/quote?symbols=$symbolsParam&crumb=$freshCrumb&_nc=$ts');
            response = await http.get(
              retryUrl,
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                'Accept': 'application/json',
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
                'Cookie':? YahooAuthManager.cookie,
              },
            );
          }
        }

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);
          final List<dynamic> quoteResults = jsonData['quoteResponse']?['result'] ?? [];

          final List<MarketAsset> assets = [];
          for (final quoteJson in quoteResults) {
            final symbol = quoteJson['symbol'];
            final config = chunk.firstWhere(
              (c) => c.symbol == symbol,
              orElse: () => MarketAssetConfig(symbol: symbol, displayName: symbol, type: AssetType.stock),
            );

            assets.add(MarketAsset.fromJson(quoteJson, config: config));
          }
          return assets;
        } else {
          if (kDebugMode) {
            debugPrint('[API] Chunk failed: HTTP ${response.statusCode}');
          }
          return <MarketAsset>[];
        }
      });

      final List<List<MarketAsset>> nestedResults = await Future.wait(chunkRequests);
      final List<MarketAsset> batchedResults = nestedResults.expand((element) => element).toList();

      if (batchedResults.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[API] Successfully fetched ${batchedResults.length} assets in ${chunks.length} batch requests.');
        }
        return batchedResults;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Error in chunked fetching, falling back: $e');
      }
    }
  }

  // Fallback: Individual concurrent chart API requests
  if (kDebugMode) {
    debugPrint('[API] Fallback: Fetching assets via individual chart requests');
  }
  return _fetchFallbackConcurrently();
}

//Fetching all assets one by one per request
Future<List<MarketAsset>> _fetchFallbackConcurrently() async {
  final Iterable<Future<MarketAsset?>> requests = MarketConfig.assets.map((assetConfig) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final separator = assetConfig.url.contains('?') ? '&' : '?';
      final Uri url = Uri.parse('${assetConfig.url}${separator}_nc=$ts');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return MarketAsset.fromJson(jsonData, config: assetConfig);
      }
      return null;
    } catch (error) {
      return null;
    }
  });

  final List<MarketAsset?> rawResults = await Future.wait(requests);
  return rawResults.whereType<MarketAsset>().toList();
}

extension ListChunker<T> on List<T> {
  List<List<T>> chunk(int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < length; i += chunkSize) {
      int end = (i + chunkSize < length) ? i + chunkSize : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}