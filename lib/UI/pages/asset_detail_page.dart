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
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Set Target Price Alert',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter target price for ${displayAsset.displayName}. You will be notified when the price reaches this target.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Target Price (${displayAsset.currency})',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: 'e.g. 150.00',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      errorText: dialogError,
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      //The reason of passing a null value is clearing the target price when the text is empty
                      await watchlistService.updateTargetPrice(displayAsset, null);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Target price cleared for ${displayAsset.displayName}'),
                            backgroundColor: Colors.grey[700],
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
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
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
                title: Text(displayAsset.displayName),
                backgroundColor: Colors.blueGrey[900],
                elevation: 0,
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
                      backgroundColor: isWatched ? Colors.red[400] : Colors.green[400],
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


