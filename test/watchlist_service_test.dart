import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';

void main() {
  group('WatchlistService Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late DatabaseService databaseService;
    late WatchlistService watchlistService;

    setUp(() {
      mockAuth = MockFirebaseAuth(signedIn: true);
      fakeFirestore = FakeFirebaseFirestore();
      databaseService = DatabaseService(db: fakeFirestore, auth: mockAuth);
      watchlistService = WatchlistService(databaseService: databaseService);
    });

    tearDown(() {
      watchlistService.dispose();
    });

    group('Initialization & Stream Emissions', () {
      test('initializeWatchlist loads existing items from Firestore', () async {
        final asset = MarketAsset(
          symbol: 'BTC-USD',
          displayName: 'Bitcoin',
          regularPrice: 100000.0,
          previousClose: 99000.0,
          currency: 'USD',
          type: AssetType.crypto,
        );

        await databaseService.addToWatchlist(asset);

        expect(watchlistService.watchlist, isEmpty);

        await watchlistService.initializeWatchlist();

        expect(watchlistService.watchlist.length, 1);
        expect(watchlistService.watchlist.first.symbol, 'BTC-USD');
      });

      test('watchlistStream emits new lists as assets are updated', () async {
        final asset = MarketAsset(
          symbol: 'ETH-USD',
          displayName: 'Ethereum',
          regularPrice: 3500.0,
          previousClose: 3400.0,
          currency: 'USD',
          type: AssetType.crypto,
        );

        expect(
          watchlistService.watchlistStream,
          emitsThrough(predicate<List<MarketAsset>>(
            (list) => list.any((a) => a.symbol == 'ETH-USD'),
          )),
        );

        await watchlistService.addAsset(asset);
      });
    });

    group('Adding & Removing Assets', () {
      test('addAsset adds asset to local list and persists to database', () async {
        final asset = MarketAsset(
          symbol: 'AAPL',
          displayName: 'Apple Inc.',
          regularPrice: 150.0,
          previousClose: 148.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        await watchlistService.addAsset(asset);

        expect(watchlistService.watchlist.length, 1);
        expect(watchlistService.isWatching('AAPL'), true);

        // Verify Firestore subcollection
        final dbList = await databaseService.loadWatchlist();
        expect(dbList.length, 1);
        expect(dbList.first.symbol, 'AAPL');
      });

      test('addAsset ignores duplicate assets for the same symbol', () async {
        final asset = MarketAsset(
          symbol: 'AAPL',
          displayName: 'Apple Inc.',
          regularPrice: 150.0,
          previousClose: 148.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        await watchlistService.addAsset(asset);
        await watchlistService.addAsset(asset);

        expect(watchlistService.watchlist.length, 1);
      });

      test('addAssetBySymbol creates placeholder asset and persists', () async {
        await watchlistService.addAssetBySymbol('SOL-USD');

        expect(watchlistService.watchlist.length, 1);
        final added = watchlistService.watchlist.first;
        expect(added.symbol, 'SOL-USD');
        expect(added.displayName, 'SOL-USD');
        expect(watchlistService.isWatching('SOL-USD'), true);

        final dbList = await databaseService.loadWatchlist();
        expect(dbList.first.symbol, 'SOL-USD');
      });

      test('removeAsset removes asset from local list and deletes from database', () async {
        final asset = MarketAsset(
          symbol: 'TSLA',
          displayName: 'Tesla Motors',
          regularPrice: 200.0,
          previousClose: 195.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        await watchlistService.addAsset(asset);
        expect(watchlistService.isWatching('TSLA'), true);

        await watchlistService.removeAsset('TSLA');
        expect(watchlistService.watchlist, isEmpty);
        expect(watchlistService.isWatching('TSLA'), false);

        final dbList = await databaseService.loadWatchlist();
        expect(dbList, isEmpty);
      });
    });

    group('Toggling Watchlist State', () {
      test('toggleWatchlist adds when absent and removes when present', () async {
        final asset = MarketAsset(
          symbol: 'NVDA',
          displayName: 'Nvidia',
          regularPrice: 120.0,
          previousClose: 118.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        // Toggle 1: Add
        await watchlistService.toggleWatchlist(asset);
        expect(watchlistService.isWatching('NVDA'), true);

        // Toggle 2: Remove
        await watchlistService.toggleWatchlist(asset);
        expect(watchlistService.isWatching('NVDA'), false);
      });

      test('toggleWatchlistBySymbol toggles asset membership', () async {
        // Toggle 1: Add by symbol
        await watchlistService.toggleWatchlistBySymbol('MSFT');
        expect(watchlistService.isWatching('MSFT'), true);

        // Toggle 2: Remove by symbol
        await watchlistService.toggleWatchlistBySymbol('MSFT');
        expect(watchlistService.isWatching('MSFT'), false);
      });
    });

    group('Target Price Updates & Trigger Reset', () {
      test('updateTargetPrice updates targetAlertPrice and resets isTargetAlertTriggered', () async {
        final asset = MarketAsset(
          symbol: 'AMZN',
          displayName: 'Amazon',
          regularPrice: 180.0,
          previousClose: 175.0,
          currency: 'USD',
          type: AssetType.stock,
          targetAlertPrice: 170.0,
          isTargetAlertTriggered: true, // Previously triggered
        );

        await watchlistService.addAsset(asset);
        expect(watchlistService.watchlist.first.isTargetAlertTriggered, true);

        // Update target price
        await watchlistService.updateTargetPrice(asset, 165.0);

        final updatedLocal = watchlistService.watchlist.first;
        expect(updatedLocal.targetAlertPrice, 165.0);
        expect(updatedLocal.isTargetAlertTriggered, false);

        // Verify Firestore persistence
        final dbList = await databaseService.loadWatchlist();
        expect(dbList.first.targetAlertPrice, 165.0);
        expect(dbList.first.isTargetAlertTriggered, false);
      });
    });
  });
}
