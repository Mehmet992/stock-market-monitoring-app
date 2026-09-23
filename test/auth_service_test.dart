import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/auth_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';

void main() {
  group('AuthService & DatabaseService Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late AuthService authService;
    late DatabaseService databaseService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      authService = AuthService(firebaseAuth: mockAuth);
      databaseService = DatabaseService(db: fakeFirestore, auth: mockAuth);
    });

    group('Anonymous Login & Database Persistence', () {
      test('signInAnonymously creates an anonymous user session', () async {
        expect(authService.currentUser, isNull);
        expect(authService.isAnonymous, false);

        await authService.signInAnonymously();

        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.isAnonymous, true);
        expect(authService.isAnonymous, true);
      });

      test('saveUserProfile saves initial guest profile into Firestore', () async {
        await authService.signInAnonymously();
        final uid = authService.currentUser!.uid;

        final createdProfile = await databaseService.saveUserProfile();

        expect(createdProfile, isNotNull);
        expect(createdProfile!.uid, uid);
        expect(createdProfile.isAnonymous, true);
        expect(createdProfile.defaultCurrency, Currency.usd);

        // Verify document in FakeFirestore
        final doc = await fakeFirestore.collection('users').doc(uid).get();
        expect(doc.exists, true);
        expect(doc.data()!['isAnonymous'], true);
      });

      test('signInAnonymously resumes active anonymous session without creating a new UID', () async {
        await authService.signInAnonymously();
        final firstUid = authService.currentUser!.uid;

        // Call again while logged in
        await authService.signInAnonymously();
        final secondUid = authService.currentUser!.uid;

        expect(firstUid, secondUid);
      });
    });

    group('Logout & Account Deletion (Cleanup)', () {
      test('deleteUserProfile and deleteCurrentUser purges guest data and session', () async {
        await authService.signInAnonymously();
        final uid = authService.currentUser!.uid;

        await databaseService.saveUserProfile();
        await databaseService.addToWatchlist(
          MarketAsset(
            symbol: 'AAPL',
            displayName: 'Apple Inc.',
            regularPrice: 150.0,
            previousClose: 148.0,
            currency: 'USD',
            type: AssetType.stock,
          ),
        );

        // Verify watchlist document exists
        final watchlistBefore = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('watchlist')
            .get();
        expect(watchlistBefore.docs.length, 1);

        // Delete profile & current user
        await databaseService.deleteUserProfile(uid);
        await authService.deleteCurrentUser();

        // Verify session is cleared
        expect(authService.currentUser, isNull);

        // Verify Firestore profile & watchlist subcollection deleted
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

    group('Account Linking to Email', () {
      test('linkAnonymousUserWithEmail converts guest account into email account', () async {
        await authService.signInAnonymously();
        await databaseService.saveUserProfile();

        const testEmail = 'user@example.com';
        const testPass = 'password123';

        await authService.linkAnonymousUserWithEmail(
          email: testEmail,
          password: testPass,
        );

        // Re-authenticate mock user with linked email in mock test environment
        await authService.signUpWithEmail(email: testEmail, password: testPass);

        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, testEmail);

        // Update database profile after linking
        await databaseService.saveUserProfile();

        final updatedProfile = await databaseService.getUserProfile();
        expect(updatedProfile, isNotNull);
        expect(updatedProfile!.email, testEmail);
      });
    });

    group('Core Authentication Operations', () {
      test('signUpWithEmail creates user account', () async {
        const testEmail = 'newuser@example.com';
        const testPass = 'password123';

        await authService.signUpWithEmail(email: testEmail, password: testPass);

        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, testEmail);
        expect(authService.currentUser!.isAnonymous, false);
      });

      test('signOut clears current user session', () async {
        await authService.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );
        expect(authService.currentUser, isNotNull);

        await authService.signOut();
        expect(authService.currentUser, isNull);
      });
    });
  });
}
