import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';

void main() async {
  print("Starting the service!");

  final service = GenericMarketService();

  service.marketDataStream.listen((assets) {
    print('\n--- NEW DATA FETCHED AT ${DateTime.now()} ---');
    for (var asset in assets) {
      print('${asset.displayName} (${asset.symbol}): ${asset.regularPrice} ${asset.currency}');
    }
  });

  service.startPolling(interval: const Duration(seconds: 10));

  await Future.delayed(const Duration(seconds: 35));
  service.dispose();
  print('\nTest finished.');
}