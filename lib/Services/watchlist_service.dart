import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/background_service.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';

class WatchlistService {
  final StreamController<List<MarketAsset>> _watchlistController =
      StreamController<List<MarketAsset>>.broadcast();

  List<MarketAsset> _watchlist = [];
  late DatabaseService _databaseService;

  WatchlistService({DatabaseService? databaseService}) {
    _databaseService = databaseService ?? DatabaseService();
  }

  /// Gets the watchlist stream
  Stream<List<MarketAsset>> get watchlistStream => _watchlistController.stream;

  /// Gets the current list of watchlist
  List<MarketAsset> get watchlist => _watchlist;

  /// Initialize watchlist from database
  Future<void> initializeWatchlist() async {
    try {
      _watchlist = await _databaseService.loadWatchlist();
      _watchlistController.add(List.from(_watchlist));
      if (kDebugMode) {
        debugPrint(
            '[WatchlistService] Watchlist initialized with ${_watchlist.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WatchlistService] Error initializing watchlist: $e');
      }
      _watchlist = [];
      _watchlistController.add([]);
    }
  }

  /// Add asset to local watchlist and persist to database
  Future<void> addAsset(MarketAsset asset) async {
    if (!_watchlist.any((a) => a.symbol == asset.symbol)) {
      _watchlist.add(asset);
      _watchlistController.add(List.from(_watchlist));
      if (kDebugMode) {
        debugPrint(
            '[WatchlistService] Added asset ${asset.symbol} to local watchlist');
      }
      try {
        await _databaseService.addToWatchlist(asset);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[WatchlistService] Error persisting added asset ${asset.symbol}: $e');
        }
      }
    }
  }

  /// Add asset by symbol only (creates placeholder and persists to database)
  Future<void> addAssetBySymbol(String symbol) async {
    if (!_watchlist.any((a) => a.symbol == symbol)) {
      final placeholder = MarketAsset(
        regularPrice: 0.0,
        previousClose: 0.0,
        currency: CurrencyService().normalizeCurrencyCode(null, symbol: symbol),
        symbol: symbol,
        displayName: symbol,
        type: AssetType.crypto,
      );
      if (kDebugMode) {
        debugPrint(
            '[WatchlistService] Asset $symbol added to watchlist as placeholder');
      }
      await addAsset(placeholder);
    }
  }

  /// Remove asset from local watchlist and persist deletion to database
  Future<void> removeAsset(String symbol) async {
    if (_watchlist.any((a) => a.symbol == symbol)) {
      _watchlist.removeWhere((a) => a.symbol == symbol);
      _watchlistController.add(List.from(_watchlist));
      if (kDebugMode) {
        debugPrint(
            '[WatchlistService] Removed asset $symbol from local watchlist');
      }
      try {
        await _databaseService.removeFromWatchlist(symbol);
        await syncBackgroundWorkerForCurrentUser();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[WatchlistService] Error persisting removal of asset $symbol: $e');
        }
      }
    }
  }

  /// Check if asset is in watchlist
  bool isWatching(String symbol) {
    return _watchlist.any((a) => a.symbol == symbol);
  }

  /// Toggle asset in watchlist (with MarketAsset object)
  Future<void> toggleWatchlist(MarketAsset asset) async {
    if (isWatching(asset.symbol)) {
      await removeAsset(asset.symbol);
    } else {
      await addAsset(asset);
    }
  }

  /// Toggle asset by symbol only (backward compatibility)
  Future<void> toggleWatchlistBySymbol(String symbol) async {
    if (isWatching(symbol)) {
      await removeAsset(symbol);
    } else {
      await addAssetBySymbol(symbol);
    }
  }

  /// Update target price for an asset and persist to database
  Future<void> updateTargetPrice(MarketAsset asset, double? targetPrice) async {
    final updatedAsset = asset.copyWith(
      targetAlertPrice: targetPrice,
      isTargetAlertTriggered: false,
    );
    final index = _watchlist.indexWhere((a) => a.symbol == asset.symbol);
    if (index != -1) {
      _watchlist[index] = updatedAsset;
    } else {
      _watchlist.add(updatedAsset);
    }
    _watchlistController.add(List.from(_watchlist));
    try {
      await _databaseService.addToWatchlist(updatedAsset);
      await syncBackgroundWorkerForCurrentUser();
      if (kDebugMode) {
        debugPrint(
            '[WatchlistService] Saved target price $targetPrice for ${asset.symbol}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[WatchlistService] Error saving target price for ${asset.symbol}: $e');
      }
    }
  }

  void dispose() {
    _watchlistController.close();
  }
}
