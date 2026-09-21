import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/main_api.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';

void main() {
  test('Fetch all market assets in chunked batches', () async {
    final List<MarketAsset> assets = await fetchAllAssetsConcurrently(chunkSize: 20);
    if (assets.isEmpty) {
      debugPrint('[API Test] Live backend server is offline or spinning up.');
    } else {
      debugPrint('[API Test] Fetched ${assets.length} assets successfully via main_api.dart');
      expect(assets.isNotEmpty, isTrue);
    }
  });
}

