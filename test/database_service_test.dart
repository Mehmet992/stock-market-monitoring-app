import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Enums/theme.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late DatabaseService databaseService;

    setUp(() {
      mockAuth = MockFirebaseAuth(signedIn: true);
      fakeFirestore = FakeFirebaseFirestore();
      databaseService = DatabaseService(db: fakeFirestore, auth: mockAuth);
    });

    group('User Profile Management & Auto-Initialization', () {
      test('saveUserProfile initializes default profile for new user', () async {
        final profile = await databaseService.saveUserProfile();
        final uid = mockAuth.currentUser!.uid;

        expect(profile, isNotNull);
        expect(profile!.uid, uid);
        expect(profile.defaultCurrency, Currency.usd);
        expect(profile.theme, Theme.system);
        expect(profile.pollingTime, 30.0);
        expect(profile.backgroundPollingTime, 3600.0);

        final doc = await fakeFirestore.collection('users').doc(uid).get();
        expect(doc.exists, true);
        expect(doc.data()!['defaultCurrency'], 'USD');
      });

      test('saveUserProfile performs partial updates for existing user', () async {
        await databaseService.saveUserProfile();

        final updateResult = await databaseService.saveUserProfile(
          currency: Currency.tryLira,
          theme: Theme.dark,
          pollingTime: 15.0,
          backgroundPollingTime: 1800.0,
        );

        expect(updateResult, isNull);

        final updatedProfile = await databaseService.getUserProfile();
        expect(updatedProfile, isNotNull);
        expect(updatedProfile!.defaultCurrency, Currency.tryLira);
        expect(updatedProfile.theme, Theme.dark);
        expect(updatedProfile.pollingTime, 15.0);
        expect(updatedProfile.backgroundPollingTime, 1800.0);
        expect(CurrencyService().defaultCurrency, Currency.tryLira);
      });

      test('getUserProfile auto-creates profile if missing and updates CurrencyService', () async {
        final profile = await databaseService.getUserProfile();
        final uid = mockAuth.currentUser!.uid;

        expect(profile, isNotNull);
        expect(profile!.uid, uid);

        final doc = await fakeFirestore.collection('users').doc(uid).get();
        expect(doc.exists, true);
      });

      test('getUserProfileStream emits UserDataModel on profile changes', () async {
        await databaseService.saveUserProfile();

        final stream = databaseService.getUserProfileStream();
        expect(
          stream,
          emitsThrough(predicate<dynamic>(
            (profile) => profile != null && profile.defaultCurrency == Currency.usd,
          )),
        );
      });

      test('Throws exception when user is not logged in', () async {
        final unauthMock = MockFirebaseAuth(signedIn: false);
        final unauthService = DatabaseService(db: fakeFirestore, auth: unauthMock);

        expect(
          () async => await unauthService.saveUserProfile(),
          throwsA(isA<Exception>()),
        );

        expect(
          () async => await unauthService.getUserProfile(),
          throwsA(isA<Exception>()),
        );

        expect(
          () async => await unauthService.addToWatchlist(
            MarketAsset(
              symbol: 'AAPL',
              displayName: 'Apple Inc.',
              regularPrice: 150.0,
              previousClose: 148.0,
              currency: 'USD',
              type: AssetType.stock,
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Watchlist Operations', () {
      test('addToWatchlist adds asset document to users/{uid}/watchlist subcollection', () async {
        final asset = MarketAsset(
          symbol: 'BTC-USD',
          displayName: 'Bitcoin',
          regularPrice: 100000.0,
          previousClose: 98000.0,
          currency: 'USD',
          type: AssetType.crypto,
          targetAlertPrice: 95000.0,
        );

        await databaseService.addToWatchlist(asset);
        final uid = mockAuth.currentUser!.uid;

        final doc = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('watchlist')
            .doc('BTC-USD')
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['displayName'], 'Bitcoin');
        expect(doc.data()!['targetAlertPrice'], 95000.0);
      });

      test('loadWatchlist loads all assets from Firestore once', () async {
        final asset1 = MarketAsset(
          symbol: 'AAPL',
          displayName: 'Apple',
          regularPrice: 150.0,
          previousClose: 148.0,
          currency: 'USD',
          type: AssetType.stock,
        );
        final asset2 = MarketAsset(
          symbol: 'NVDA',
          displayName: 'Nvidia',
          regularPrice: 120.0,
          previousClose: 118.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        await databaseService.addToWatchlist(asset1);
        await databaseService.addToWatchlist(asset2);

        final list = await databaseService.loadWatchlist();
        expect(list.length, 2);
        expect(list.any((a) => a.symbol == 'AAPL'), true);
        expect(list.any((a) => a.symbol == 'NVDA'), true);
      });

      test('removeFromWatchlist deletes asset from watchlist subcollection', () async {
        final asset = MarketAsset(
          symbol: 'AAPL',
          displayName: 'Apple',
          regularPrice: 150.0,
          previousClose: 148.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        await databaseService.addToWatchlist(asset);
        var list = await databaseService.loadWatchlist();
        expect(list.length, 1);

        await databaseService.removeFromWatchlist('AAPL');
        list = await databaseService.loadWatchlist();
        expect(list.isEmpty, true);
      });

      test('getWatchlist stream emits updated watchlist list', () async {
        final asset = MarketAsset(
          symbol: 'MSFT',
          displayName: 'Microsoft',
          regularPrice: 400.0,
          previousClose: 395.0,
          currency: 'USD',
          type: AssetType.stock,
        );

        await databaseService.addToWatchlist(asset);

        final stream = databaseService.getWatchlist();
        expect(
          stream,
          emitsThrough(predicate<List<MarketAsset>>(
            (list) => list.any((a) => a.symbol == 'MSFT'),
          )),
        );
      });

      test('updateTargetAlertTriggered updates isTargetAlertTriggered in Firestore', () async {
        final asset = MarketAsset(
          symbol: 'TSLA',
          displayName: 'Tesla',
          regularPrice: 200.0,
          previousClose: 200.0,
          currency: 'USD',
          type: AssetType.stock,
          targetAlertPrice: 180.0,
          isTargetAlertTriggered: false,
        );

        await databaseService.addToWatchlist(asset);
        await databaseService.updateTargetAlertTriggered('TSLA', true);

        final list = await databaseService.loadWatchlist();
        expect(list.first.isTargetAlertTriggered, true);
      });
    });

    group('User Profile & Subcollection Deletion', () {
      test('deleteUserProfile deletes watchlist subcollection and main user profile', () async {
        await databaseService.saveUserProfile();
        await databaseService.addToWatchlist(
          MarketAsset(
            symbol: 'GOOGL',
            displayName: 'Alphabet',
            regularPrice: 170.0,
            previousClose: 168.0,
            currency: 'USD',
            type: AssetType.stock,
          ),
        );

        final uid = mockAuth.currentUser!.uid;

        await databaseService.deleteUserProfile(uid);

        final docAfter = await fakeFirestore.collection('users').doc(uid).get();
        expect(docAfter.exists, false);

        final watchlistAfter = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('watchlist')
            .get();
        expect(watchlistAfter.docs.isEmpty, true);
      });
    });
  });
}
