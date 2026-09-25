import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/generic_market_service.dart';
import 'package:stock_market_monitoring_app/Services/notification_service.dart';
import 'package:stock_market_monitoring_app/Services/watchlist_service.dart';
import '../components/asset_detail_view.dart';

class AssetDetailPage extends StatelessWidget {
  final MarketAsset asset;
  final WatchlistService watchlistService;
  final GenericMarketService? marketService;

  const AssetDetailPage({
    super.key,
    required this.asset,
    required this.watchlistService,
    this.marketService,
  });

  void _openSetTargetPriceDialog(BuildContext context, MarketAsset displayAsset) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController(
      text: (displayAsset.targetAlertPrice != null && displayAsset.targetAlertPrice! > 0)
          ? displayAsset.targetAlertPrice.toString()
          : '',
    );
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              title: Text(
                'Set Target Price Alert',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get notified automatically when ${displayAsset.displayName} reaches this price.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Target Price (${displayAsset.currency})',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      hintText: 'e.g. ${displayAsset.regularPrice.toStringAsFixed(2)}',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      errorText: dialogError,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF141A23)
                          : const Color(0xFFF0F3F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C805),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      // Clearing the target price when empty
                      await watchlistService.updateTargetPrice(displayAsset, null);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Target price cleared for ${displayAsset.displayName}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      setDialogState(() {
                        dialogError = 'Please enter a valid price (> 0)';
                      });
                      return;
                    }

                    await watchlistService.updateTargetPrice(displayAsset, parsed);
                    await NotificationService().initialize();

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Target price of $parsed ${displayAsset.currency} saved!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save Alert',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<MarketAsset>>(
      stream: marketService?.marketDataStream ?? const Stream.empty(),
      builder: (context, marketSnapshot) {
        final liveAssets = marketSnapshot.data ?? [];
        final latestLiveAsset = liveAssets.firstWhere(
          (a) => a.symbol == asset.symbol,
          orElse: () => asset,
        );

        return StreamBuilder<List<MarketAsset>>(
          stream: watchlistService.watchlistStream,
          builder: (context, watchlistSnapshot) {
            final isWatched = watchlistService.isWatching(asset.symbol);

            final watchedAsset = watchlistService.watchlist.firstWhere(
              (a) => a.symbol == asset.symbol,
              orElse: () => latestLiveAsset,
            );

            final combinedAsset = latestLiveAsset.copyWith(
              targetAlertPrice: watchedAsset.targetAlertPrice,
            );

            final displayAsset = CurrencyService().convertAsset(combinedAsset);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  displayAsset.displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isWatched ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: isWatched
                          ? const Color(0xFF00C805)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      watchlistService.toggleWatchlist(displayAsset);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isWatched
                                ? '${displayAsset.displayName} removed from watchlist'
                                : '${displayAsset.displayName} added to watchlist',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: AssetDetailView(
                asset: displayAsset,
                isWatched: isWatched,
                onWatchlistToggle: () {
                  watchlistService.toggleWatchlist(displayAsset);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isWatched
                            ? '${displayAsset.displayName} removed from watchlist'
                            : '${displayAsset.displayName} added to watchlist',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onSetTargetPrice: isWatched ? () => _openSetTargetPriceDialog(context, displayAsset) : null,
              ),
            );
          },
        );
      },
    );
  }
}
