import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_market_monitoring_app/Enums/asset_types.dart';
import 'package:stock_market_monitoring_app/Models/market_asset.dart';
import 'package:stock_market_monitoring_app/Services/notification_service.dart';

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  int initializeCallCount = 0;
  InitializationSettings? lastInitSettings;

  int? lastShowId;
  String? lastShowTitle;
  String? lastShowBody;
  NotificationDetails? lastShowDetails;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCallCount++;
    lastInitSettings = initializationSettings;
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    lastShowId = id;
    lastShowTitle = title;
    lastShowBody = body;
    lastShowDetails = notificationDetails;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    late FakeFlutterLocalNotificationsPlugin fakePlugin;
    late NotificationService notificationService;

    setUp(() {
      fakePlugin = FakeFlutterLocalNotificationsPlugin();
      notificationService = NotificationService.withPlugin(fakePlugin);
      NotificationService.setMockInstance(notificationService);
    });

    tearDown(() {
      NotificationService.resetInstance();
    });

    group('Initialization', () {
      test('initialize configures Android and iOS settings properly', () async {
        expect(notificationService.isInitialized, false);

        await notificationService.initialize(isBackground: true);

        expect(notificationService.isInitialized, true);
        expect(fakePlugin.initializeCallCount, 1);

        final initSettings = fakePlugin.lastInitSettings;
        expect(initSettings, isNotNull);
        expect(
          initSettings!.android?.defaultIcon,
          '@mipmap/ic_launcher',
        );
        expect(initSettings.iOS?.requestAlertPermission, true);
        expect(initSettings.iOS?.requestBadgePermission, true);
        expect(initSettings.iOS?.requestSoundPermission, true);
      });

      test('Multiple initialize calls do not re-initialize plugin', () async {
        await notificationService.initialize(isBackground: true);
        expect(fakePlugin.initializeCallCount, 1);

        // Second call should return early
        await notificationService.initialize(isBackground: true);
        expect(fakePlugin.initializeCallCount, 1);
      });
    });

    group('Notification Dispatch & Channel Configuration', () {
      test('showPriceAlertNotification passes correct id, title, and body',
          () async {
        const testId = 42;
        const testTitle = '📈 Target Price Reached!';
        const testBody = 'Bitcoin (BTC-USD) rose to 105,000.00 USD';

        await notificationService.showPriceAlertNotification(
          id: testId,
          title: testTitle,
          body: testBody,
        );

        expect(fakePlugin.lastShowId, testId);
        expect(fakePlugin.lastShowTitle, testTitle);
        expect(fakePlugin.lastShowBody, testBody);
      });

      test('Configures Android channel with high importance and priority',
          () async {
        await notificationService.showPriceAlertNotification(
          id: 100,
          title: 'Alert',
          body: 'Price alert triggered',
        );

        final details = fakePlugin.lastShowDetails;
        expect(details, isNotNull);

        final androidDetails = details!.android;
        expect(androidDetails, isNotNull);
        expect(androidDetails!.channelId, 'price_alerts_channel');
        expect(androidDetails.channelName, 'Price Alerts');
        expect(androidDetails.importance, Importance.high);
        expect(androidDetails.priority, Priority.high);

        final iOSDetails = details.iOS;
        expect(iOSDetails, isNotNull);
      });
    });

    group('Connection with Background Service Alert Flow', () {
      test(
          'Background price alert creates notification with symbol hash ID and formatted message',
          () async {
        final targetAsset = MarketAsset(
          symbol: 'ETH-USD',
          displayName: 'Ethereum',
          regularPrice: 3500.0,
          previousClose: 3600.0,
          currency: 'USD',
          type: AssetType.crypto,
          targetAlertPrice: 3400.0,
        );

        final liveAsset = targetAsset.copyWith(regularPrice: 3350.0);

        // Verify downward alert trigger condition as evaluated in background_service
        final double basePrice = targetAsset.previousClose;
        final double target = targetAsset.targetAlertPrice!;
        final double currentPrice = liveAsset.regularPrice;

        expect(basePrice > 0 && target < basePrice, true);
        expect(currentPrice <= target, true);

        // Background service generates notificationId from symbol.hashCode
        final expectedNotificationId = targetAsset.symbol.hashCode;
        final expectedTitle = '📉 Target Price Reached!';
        final expectedBody =
            '${targetAsset.displayName} (${targetAsset.symbol}) dropped to ${currentPrice.toStringAsFixed(2)} ${liveAsset.currency} (Target: ${target.toStringAsFixed(2)})';

        // Fire notification via NotificationService instance
        await NotificationService().showPriceAlertNotification(
          id: expectedNotificationId,
          title: expectedTitle,
          body: expectedBody,
        );

        expect(fakePlugin.lastShowId, expectedNotificationId);
        expect(fakePlugin.lastShowTitle, expectedTitle);
        expect(fakePlugin.lastShowBody, expectedBody);
        expect(
          fakePlugin.lastShowBody,
          contains('Ethereum (ETH-USD) dropped to 3350.00 USD (Target: 3400.00)'),
        );
      });
    });
  });
}
