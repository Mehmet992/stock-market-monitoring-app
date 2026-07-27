import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'category_page.dart';

class StocksPage extends StatelessWidget {
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const StocksPage({
    Key? key,
    required this.marketService,
    required this.watchlistService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      categoryName: 'Stocks',
      assetType: AssetType.stock,
      marketService: marketService,
      watchlistService: watchlistService,
    );
  }
}
