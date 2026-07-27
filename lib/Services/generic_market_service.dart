import 'dart:async';

import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/main_api.dart';

//Pulling all the specified information from the API service
class GenericMarketService {
  //Creating the Stream controller and broadcasting the stream
  final StreamController<List<MarketAsset>> _marketDataController = StreamController<List<MarketAsset>>.broadcast();
  Timer? _timer;

  List<MarketAsset>? _lastData;
  Stream<List<MarketAsset>> get marketDataStream => _getStreamWithCache();

  Stream<List<MarketAsset>> _getStreamWithCache() async* {
    if (_lastData != null) {
      yield _lastData!;
    }
    yield* _marketDataController.stream;
  }

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    //Avoiding multiple timers
    stopPolling();

    _fetchAndBroadcast();

    _timer = Timer.periodic(interval, (_) {
      _fetchAndBroadcast();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopPolling();
    _marketDataController.close();
  }

  Future<void> _fetchAndBroadcast() async {
    //Calling the function that returns all the assets and makes api calls
    final List<MarketAsset> assets = await fetchAllAssetsConcurrently();

    if (assets.isNotEmpty && !_marketDataController.isClosed) {
      _lastData = assets;
      _marketDataController.add(assets);
    }
  }
}