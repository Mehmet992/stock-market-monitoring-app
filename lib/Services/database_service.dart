import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Models/user_data_model.dart';

import '../Enums/theme.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save user profile to database (called immediately on account creation)
  Future<void> saveUserProfile({
    Currency? currency,
    Theme? theme,
    double? pollingTime,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in!");
    }

    final userData = UserDataModel(
      uid: userId,
      email: _auth.currentUser?.email,
      isAnonymous: _auth.currentUser?.isAnonymous ?? true,
      defaultCurrency: currency ?? Currency.usd,
      theme: theme ?? Theme.system,
      pollingTime: pollingTime ?? 10.0,
    ).toFirestoreMap();

    await _db
        .collection('users')
        .doc(userId)
        .set(userData, SetOptions(merge: true));

    if (kDebugMode) {
      debugPrint('[DatabaseService] User profile saved for UID: $userId');
    }
  }

  /// Load user profile from database
  Future<UserDataModel?> getUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in!");
    }

    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        if (kDebugMode) {
          debugPrint('[DatabaseService] User profile loaded for UID: $userId');
        }
        return UserDataModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DatabaseService] Error loading user profile: $e');
      }
      return null;
    }
  }

  /// Stream for user profile changes
  Stream<UserDataModel?> getUserProfileStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }

    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserDataModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Add single asset to watchlist
  Future<void> addToWatchlist(MarketAsset asset) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in!");
    }

    await _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(asset.symbol)
        .set(asset.toFirestoreMap());

    if (kDebugMode) {
      debugPrint(
          '[DatabaseService] Added asset ${asset.symbol} to watchlist for UID: $userId');
    }
  }

  /// Remove single asset from watchlist
  Future<void> removeFromWatchlist(String assetSymbol) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in!");
    }

    await _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(assetSymbol)
        .delete();

    if (kDebugMode) {
      debugPrint(
          '[DatabaseService] Removed asset $assetSymbol from watchlist for UID: $userId');
    }
  }

  /// Get all watchlist assets as a stream
  Stream<List<MarketAsset>> getWatchlist() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketAsset.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Load watchlist once (for initialization)
  Future<List<MarketAsset>> loadWatchlist() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .get();

      final list = snapshot.docs
          .map((doc) => MarketAsset.fromFirestore(doc.data(), doc.id))
          .toList();

      if (kDebugMode) {
        debugPrint(
            '[DatabaseService] Loaded ${list.length} watchlist items for UID: $userId');
      }

      return list;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DatabaseService] Error loading watchlist: $e');
      }
      return [];
    }
  }
}
