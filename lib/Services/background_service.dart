import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/currency_service.dart';
import 'package:stock_market_monitoring_app/Services/database_service.dart';
import 'package:stock_market_monitoring_app/Services/notification_service.dart';
import 'package:stock_market_monitoring_app/firebase_options.dart';
import 'package:stock_market_monitoring_app/main_api.dart';

const String backgroundTaskUniqueName = 'stock_price_checker_task';
const String backgroundTaskTag = 'fetchStockPricesAndCheckTargets';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (kDebugMode) {
        debugPrint('[BackgroundWorker] Task $taskName executed');
      }

      // 1. Initialize Firebase in background isolate
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Load user watchlist from Firestore
      final dbService = DatabaseService();
      final watchlist = await dbService.loadWatchlist();
      final userProfile = await dbService.getUserProfile();
      final displayCurrency = userProfile?.defaultCurrency ?? Currency.usd;

      // Skip API network calls and notification system if no assets have a target price set
      final targetAssets = watchlist
          .where((a) => a.targetAlertPrice != null && a.targetAlertPrice! > 0)
          .toList();

      if (targetAssets.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[BackgroundWorker] No assets have a target price set up. Skipping notification checks.');
        }
        return Future.value(true);
      }

      // 3. Initialize NotificationService in background mode
      await NotificationService().initialize(isBackground: true);

      // 3. Fetch latest live market prices and convert to user display currency
      final List<MarketAsset> rawLiveAssets = await fetchAllAssetsConcurrently();
      final List<MarketAsset> liveAssets =
          CurrencyService().convertAssets(rawLiveAssets, displayCurrency);

      // 4. Compare regular price against targetAlertPrice for both UP and DOWN conditions
      for (final targetAsset in targetAssets) {
        final double target = targetAsset.targetAlertPrice!;
        final liveAsset = liveAssets.firstWhere(
          (a) => a.symbol == targetAsset.symbol,
          orElse: () => targetAsset,
        );

        final double currentPrice = liveAsset.regularPrice;
        if (currentPrice <= 0) continue;

        final double basePrice = targetAsset.previousClose > 0
            ? targetAsset.previousClose
            : liveAsset.previousClose;

        bool targetTriggered = false;
        String title = '';
        String body = '';

        if (basePrice > 0 && target < basePrice) {
          // Downward target alert (price dropped to/below target)
          if (currentPrice <= target) {
            targetTriggered = true;
            title = '📉 Target Price Reached!';
            body =
                '${targetAsset.displayName} (${targetAsset.symbol}) dropped to ${currentPrice.toStringAsFixed(2)} ${liveAsset.currency} (Target: ${target.toStringAsFixed(2)})';
          }
        } else {
          // Upward target alert (price rose to/above target)
          if (currentPrice >= target) {
            targetTriggered = true;
            title = '📈 Target Price Reached!';
            body =
                '${targetAsset.displayName} (${targetAsset.symbol}) rose to ${currentPrice.toStringAsFixed(2)} ${liveAsset.currency} (Target: ${target.toStringAsFixed(2)})';
          }
        }

        if (targetTriggered) {
          final notificationId = targetAsset.symbol.hashCode;
          await NotificationService().showPriceAlertNotification(
            id: notificationId,
            title: title,
            body: body,
          );
          if (kDebugMode) {
            debugPrint('[BackgroundWorker] Fired alert for ${targetAsset.symbol}');
          }
        }
      }

      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackgroundWorker] Error during background task execution: $e');
      }
      return Future.value(false);
    }
  });
}

/// Schedules or cancels periodic background price checking tasks via WorkManager
Future<void> scheduleBackgroundWorker(double? backgroundPollingTimeInSeconds) async {
  if (backgroundPollingTimeInSeconds == null || backgroundPollingTimeInSeconds <= 0) {
    await Workmanager().cancelByUniqueName(backgroundTaskUniqueName);
    if (kDebugMode) {
      debugPrint('[BackgroundWorker] Cancelled background task.');
    }
    return;
  }

  // Pre-check: Only schedule if at least one asset in user's watchlist has a target price
  try {
    final watchlist = await DatabaseService().loadWatchlist();
    final hasTargetPrices = watchlist.any((a) => a.targetAlertPrice != null && a.targetAlertPrice! > 0);
    if (!hasTargetPrices) {
      await Workmanager().cancelByUniqueName(backgroundTaskUniqueName);
      if (kDebugMode) {
        debugPrint(
            '[BackgroundWorker] No watchlist assets have a target price configured. Background task unscheduled.');
      }
      return;
    }
  } catch (e) {
    // If user is unauthenticated or error loading, skip scheduling
  }

  // WorkManager minimum periodic frequency on Android is 15 minutes (900 seconds)
  final double minutesDouble = backgroundPollingTimeInSeconds / 60.0;
  int frequencyMinutes = minutesDouble.round();
  if (frequencyMinutes < 15) {
    frequencyMinutes = 15;
  }

  await Workmanager().initialize(
    callbackDispatcher,
  );

  //Registering a periodic task for notification (checks for every interval which is specified by the user)
  await Workmanager().registerPeriodicTask(
    backgroundTaskUniqueName,
    backgroundTaskTag,
    frequency: Duration(minutes: frequencyMinutes),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  if (kDebugMode) {
    debugPrint(
        '[BackgroundWorker] Scheduled periodic background task every $frequencyMinutes minutes.');
  }
}

/// Helper to sync background worker schedule for current user when watchlist or target prices change
Future<void> syncBackgroundWorkerForCurrentUser() async {
  try {
    final userProfile = await DatabaseService().getUserProfile();
    final backgroundPollingTime = userProfile?.backgroundPollingTime ?? 3600.0;
    await scheduleBackgroundWorker(backgroundPollingTime);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[BackgroundWorker] Error syncing background worker for user: $e');
    }
  }
}

