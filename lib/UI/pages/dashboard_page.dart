import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import '../components/asset_card.dart';
import '../components/state_widgets.dart';
import 'asset_detail_page.dart';

class DashboardPage extends StatefulWidget {
  final GenericMarketService marketService;
  final WatchlistService watchlistService;

  const DashboardPage({
    super.key,
    required this.marketService,
    required this.watchlistService,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Stocks',
    'Crypto',
    'Metals',
    'Forex',
  ];

  bool _matchesCategory(MarketAsset asset) {
    if (_selectedCategory == 'All') return true;
    switch (_selectedCategory) {
      case 'Stocks':
        return asset.type == AssetType.stock;
      case 'Crypto':
        return asset.type == AssetType.crypto;
      case 'Metals':
        return asset.type == AssetType.metal;
      case 'Forex':
        return asset.type == AssetType.forex;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<MarketAsset>>(
      stream: widget.watchlistService.watchlistStream,
      initialData: widget.watchlistService.watchlist,
      builder: (context, watchlistSnapshot) {
        return StreamBuilder<List<MarketAsset>>(
          stream: widget.marketService.marketDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingSpinner(message: 'Connecting to market stream...');
            }

            if (snapshot.hasError) {
              return ErrorDisplay(
                message: snapshot.error.toString(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Market Data',
                message: 'Unable to fetch market assets. Please check your connection.',
                icon: Icons.show_chart_rounded,
              );
            }

            final rawAssets = snapshot.data!;
            final assets = CurrencyService().convertAssets(rawAssets);

            final watchedAssets = assets
                .where((asset) => widget.watchlistService.isWatching(asset.symbol))
                .toList();

            final filteredAssets = assets.where(_matchesCategory).toList();

            return SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
              slivers: [
                // Top Market Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Status Pill
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C805).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00C805),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Live Markets',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00C805),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Markets & Assets',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time streaming prices & watchlist tracking',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal Category Filter Bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF11161D))
                                  : (isDark ? const Color(0xFF141A23) : const Color(0xFFF0F3F6)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04)),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF0A0E14) : Colors.white)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Watchlist Section (only shown when user has watched items and selected category is 'All')
                if (watchedAssets.isNotEmpty && _selectedCategory == 'All') ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Watchlist',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C2430) : const Color(0xFFE8EDF2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${watchedAssets.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: watchedAssets.length,
                    itemBuilder: (context, index) {
                      final asset = watchedAssets[index];
                      return AssetCard(
                        asset: asset,
                        isWatched: true,
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
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],

                // All / Filtered Assets Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory == 'All' ? 'All Assets' : '$_selectedCategory Assets',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${filteredAssets.length} tracked',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
        );
      },
    );
  }
}
