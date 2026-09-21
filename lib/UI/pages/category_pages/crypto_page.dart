import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'category_page.dart';

class CryptoPage extends StatelessWidget {
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const CryptoPage({
    super.key,
    required this.marketService,
    required this.watchlistService,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      categoryName: 'Crypto',
      assetType: AssetType.crypto,
      marketService: marketService,
      watchlistService: watchlistService,
    );
  }
}
