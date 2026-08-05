import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import '../../components/asset_card.dart';
import '../../components/state_widgets.dart';
import '../asset_detail_page.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;
  final AssetType assetType;
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const CategoryPage({
    Key? key,
    required this.categoryName,
    required this.assetType,
    required this.marketService,
    required this.watchlistService,
  }) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketAsset>>(
      stream: widget.watchlistService.watchlistStream,
      initialData: widget.watchlistService.watchlist,
      builder: (context, watchlistSnapshot) {
        return StreamBuilder<List<MarketAsset>>(
          stream: widget.marketService.marketDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingSpinner(message: 'Loading assets...');
            }

            if (snapshot.hasError) {
              return ErrorDisplay(
                message: snapshot.error.toString(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Data Available',
                message: 'Unable to fetch asset data.',
                icon: Icons.cloud_off,
              );
            }

            final allAssets = snapshot.data!;
            final convertedAssets = CurrencyService().convertAssets(allAssets);
            final categoryAssets = convertedAssets
                .where((asset) => asset.type == widget.assetType)
                .toList();

            //Logic of searching for an asset
            final filteredAssets = _searchQuery.isEmpty
                ? categoryAssets
                : categoryAssets
                    .where((asset) =>
                        asset.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        asset.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

            if (categoryAssets.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Assets Found',
                message: 'This category has no available assets.',
                icon: Icons.search_off,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.categoryName}...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredAssets.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No Results',
                          message: 'Try a different search term.',
                          icon: Icons.search_off,
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: filteredAssets.map((asset) {
                              final isWatched = widget.watchlistService.isWatching(asset.symbol);
                              return AssetCard(
                                asset: asset,
                                isWatched: isWatched,
                                onWatchlistToggle: () {
                                  widget.watchlistService.toggleWatchlist(asset);
                                },
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AssetDetailPage(
                                        asset: asset,
                                        watchlistService: widget.watchlistService,
                                        marketService: widget.marketService,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
