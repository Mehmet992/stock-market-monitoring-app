import 'package:flutter/material.dart';
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
        final categoryAssets = allAssets
            .where((asset) => asset.type == widget.assetType)
            .toList();

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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.categoryName}...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green[400]!),
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
                              widget.watchlistService.toggleWatchlist(asset.symbol);
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssetDetailPage(
                                    asset: asset,
                                    watchlistService: widget.watchlistService,
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
  }
}
