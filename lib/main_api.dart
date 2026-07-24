import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ConfigClasses/market_config.dart';
import 'Models/market_asset.dart';

Future<List<MarketAsset>> fetchAllAssetsConcurrently() async {
  final Iterable<Future<MarketAsset?>> requests = MarketConfig.assets.map((assetConfig) async {
    try {
      final response = await http.get(Uri.parse(assetConfig.url),
        headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return MarketAsset.fromJson(jsonData, config: assetConfig);
      } else {
        print('Failed to load ${assetConfig.displayName}: HTTP ${response.statusCode} ');
        return null;
      }
    } catch (error) {
      print('An error has occurred: $error');
      return null;
    }
  });

  final List<MarketAsset?> rawResults = await Future.wait(requests);
  return rawResults.whereType<MarketAsset>().toList();
}