import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/UI/components/asset_card.dart';

void main() {
  testWidgets('AssetCard renders asset details correctly',
      (WidgetTester tester) async {
    final testAsset = MarketAsset(
      regularPrice: 2500.0,
      previousClose: 2450.0,
      currency: 'USD',
      symbol: 'GC=F',
      displayName: 'Gold (Ounce)',
      type: AssetType.metal,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetCard(
            asset: testAsset,
            isWatched: false,
            onWatchlistToggle: () {},
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Gold (Ounce)'), findsOneWidget);
    expect(find.text('GC=F'), findsOneWidget);
    expect(find.text('2500.00 \$'), findsOneWidget);
  });
}
