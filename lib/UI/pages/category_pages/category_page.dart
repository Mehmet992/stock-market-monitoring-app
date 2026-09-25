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
    super.key,
    required this.categoryName,
    required this.assetType,
    required this.marketService,
    required this.watchlistService,
  });

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

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.categoryName}...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF141A23)
                            : const Color(0xFFF0F3F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF00C805),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (filteredAssets.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      title: 'No Results',
                      message: 'Try a different search term.',
                      icon: Icons.search_off,
                    ),
                  )
                else ...[
                  SliverList.builder(
                    itemCount: filteredAssets.length,
                    itemBuilder: (context, index) {
                      final asset = filteredAssets[index];
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
                    },
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
