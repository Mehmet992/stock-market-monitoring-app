import 'dart:async';

class WatchlistService {
  final StreamController<Set<String>> _watchlistController =
      StreamController<Set<String>>.broadcast();
  
  Set<String> _watchlist = {};

  //Gets the watchlistStream
  Stream<Set<String>> get watchlistStream => _watchlistController.stream;

  //Gets the current list of watchlist
  Set<String> get watchlist => _watchlist;

  void addAsset(String symbol) {
    if (!_watchlist.contains(symbol)) {
      _watchlist.add(symbol);
      _watchlistController.add(Set.from(_watchlist)); //Getting a fresh copy of _watchlist
    }
  }

  void removeAsset(String symbol) {
    if (_watchlist.contains(symbol)) {
      _watchlist.remove(symbol);
      _watchlistController.add(Set.from(_watchlist)); //Getting a fresh copy of _watchlist
    }
  }

  bool isWatching(String symbol) {
    return _watchlist.contains(symbol);
  }

  void toggleWatchlist(String symbol) {
    if (isWatching(symbol)) {
      removeAsset(symbol);
    } else {
      addAsset(symbol);
    }
  }

  void dispose() {
    _watchlistController.close();
  }
}
