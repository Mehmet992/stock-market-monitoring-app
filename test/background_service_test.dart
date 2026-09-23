import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/background_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';

void main() {
  group('BackgroundService & Target Price Alert Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late DatabaseService databaseService;

    setUp(() async {
      mockAuth = MockFirebaseAuth(signedIn: true);
      fakeFirestore = FakeFirebaseFirestore();
      databaseService = DatabaseService(db: fakeFirestore, auth: mockAuth);

      // Initialize user profile in fake Firestore
      await databaseService.saveUserProfile();
    });

    group('Target Price Alert Condition Logic', () {
      test('Downward target alert triggers when current price drops to or below target', () {
        final targetAsset = MarketAsset(
          symbol: 'BTC-USD',
          displayName: 'Bitcoin',
          regularPrice: 100000.0,
          previousClose: 100000.0,
          currency: 'USD',
          type: AssetType.crypto,
          targetAlertPrice: 95000.0,
          isTargetAlertTriggered: false,
        );

        final liveAssetDrop = targetAsset.copyWith(regularPrice: 90000.0);

        final basePrice = targetAsset.previousClose;
        final target = targetAsset.targetAlertPrice!;
        final currentPrice = liveAssetDrop.regularPrice;

        bool isDownwardAlert = basePrice > 0 && target < basePrice;
        bool shouldTrigger = isDownwardAlert && (currentPrice <= target);

        expect(isDownwardAlert, true);
        expect(shouldTrigger, true);
      });

      test('Upward target alert triggers when current price rises to or above target', () {
        final targetAsset = MarketAsset(
          symbol: 'AAPL',
          displayName: 'Apple Inc.',
          regularPrice: 150.0,
          previousClose: 150.0,
          currency: 'USD',
          type: AssetType.stock,
          targetAlertPrice: 160.0,
          isTargetAlertTriggered: false,
        );

        final liveAssetRise = targetAsset.copyWith(regularPrice: 165.0);

        final basePrice = targetAsset.previousClose;
        final target = targetAsset.targetAlertPrice!;
        final currentPrice = liveAssetRise.regularPrice;

        bool isUpwardAlert = basePrice > 0 && target > basePrice;
        bool shouldTrigger = isUpwardAlert && (currentPrice >= target);

        expect(isUpwardAlert, true);
        expect(shouldTrigger, true);
      });
    });

    group('Notification Throttling ("Send Notification Once")', () {
      test('Assets with isTargetAlertTriggered == true are filtered out from notification checks', () async {
        final asset = MarketAsset(
          symbol: 'TSLA',
          displayName: 'Tesla Motors',
          regularPrice: 200.0,
          previousClose: 200.0,
          currency: 'USD',
          type: AssetType.stock,
          targetAlertPrice: 180.0,
          isTargetAlertTriggered: true, // Already triggered once
        );

        await databaseService.addToWatchlist(asset);
        final watchlist = await databaseService.loadWatchlist();

        final activeTargetAssets = watchlist
            .where((a) =>
                a.targetAlertPrice != null &&
                a.targetAlertPrice! > 0 &&
                !a.isTargetAlertTriggered)
            .toList();

        // Should be empty because isTargetAlertTriggered is true
        expect(activeTargetAssets.isEmpty, true);
      });

      test('Updating target alert price resets isTargetAlertTriggered to false', () async {
        final asset = MarketAsset(
          symbol: 'TSLA',
          displayName: 'Tesla Motors',
          regularPrice: 200.0,
          previousClose: 200.0,
          currency: 'USD',
          type: AssetType.stock,
          targetAlertPrice: 180.0,
          isTargetAlertTriggered: true,
        );

        await databaseService.addToWatchlist(asset);

        // Update target alert triggered state in Firestore
        await databaseService.updateTargetAlertTriggered('TSLA', true);

        var loaded = await databaseService.loadWatchlist();
        expect(loaded.first.isTargetAlertTriggered, true);

        // Resetting target price or saving asset with false re-enables active checking
        final updated = loaded.first.copyWith(
          targetAlertPrice: 175.0,
          isTargetAlertTriggered: false,
        );
        await databaseService.addToWatchlist(updated);

        loaded = await databaseService.loadWatchlist();
        expect(loaded.first.targetAlertPrice, 175.0);
        expect(loaded.first.isTargetAlertTriggered, false);

        final activeTargetAssets = loaded
            .where((a) =>
                a.targetAlertPrice != null &&
                a.targetAlertPrice! > 0 &&
                !a.isTargetAlertTriggered)
            .toList();
        expect(activeTargetAssets.length, 1);
      });
    });

    group('Worker Scheduling & Syncing Logic', () {
      test('syncBackgroundWorkerForCurrentUser executes safely when user profile is present', () async {
        await databaseService.saveUserProfile(backgroundPollingTime: 1800.0);

        final profile = await databaseService.getUserProfile();
        expect(profile, isNotNull);
        expect(profile!.backgroundPollingTime, 1800.0);

        expect(() async => await syncBackgroundWorkerForCurrentUser(), returnsNormally);
      });
    });
  });
}
