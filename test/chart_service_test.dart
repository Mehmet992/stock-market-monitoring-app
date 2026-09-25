import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_market_monitoring_app/Models/chart_point.dart';
import 'package:stock_market_monitoring_app/Services/chart_service.dart';
import 'package:stock_market_monitoring_app/UI/components/asset_chart_view.dart';

void main() {
  group('ChartPoint Model Tests', () {
    test('parses json with integer milliseconds timestamp', () {
      final json = {
        'timestamp': 1727100000000,
        'price': 285.50,
      };
      final point = ChartPoint.fromJson(json);

      expect(point.timestamp.millisecondsSinceEpoch, equals(1727100000000));
      expect(point.price, equals(285.50));
    });

    test('parses json with ISO string timestamp and num price', () {
      final json = {
        'timestamp': '2026-09-23T12:00:00.000Z',
        'price': 150,
      };
      final point = ChartPoint.fromJson(json);

      expect(point.price, equals(150.0));
      expect(point.timestamp, equals(DateTime.parse('2026-09-23T12:00:00.000Z')));
    });

    test('toJson produces expected map', () {
      final point = ChartPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(1727100000000),
        price: 340.25,
      );
      final json = point.toJson();

      expect(json['timestamp'], equals(1727100000000));
      expect(json['price'], equals(340.25));
    });

    test('equality and hashCode contract', () {
      final p1 = ChartPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(1727100000000),
        price: 100.0,
      );
      final p2 = ChartPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(1727100000000),
        price: 100.0,
      );
      final p3 = ChartPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(1727100000000),
        price: 105.0,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('Chart Point Downsampling Tests', () {
    test('returns points unchanged if count is less than or equal to maxPoints', () {
      final raw = List.generate(
        15,
        (i) => ChartPoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000000 + i * 1000),
          price: 100.0 + i,
        ),
      );

      final result = AssetChartView.downsamplePoints(raw, maxPoints: 30);
      expect(result.length, equals(15));
      expect(result.first.price, equals(100.0));
      expect(result.last.price, equals(114.0));
    });

    test('downsamples 200 points to 30 points and preserves first & last points', () {
      final raw = List.generate(
        200,
        (i) => ChartPoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000000 + i * 1000),
          price: 100.0 + i * 0.5,
        ),
      );

      final result = AssetChartView.downsamplePoints(raw, maxPoints: 30);
      expect(result.length, equals(30));
      // First point must be identical to raw.first
      expect(result.first.timestamp, equals(raw.first.timestamp));
      expect(result.first.price, equals(raw.first.price));
      // Last point must be identical to raw.last
      expect(result.last.timestamp, equals(raw.last.timestamp));
      expect(result.last.price, equals(raw.last.price));
    });

    test('handles empty points list gracefully', () {
      final result = AssetChartView.downsamplePoints([]);
      expect(result, isEmpty);
    });
  });

  group('ChartService Tests', () {
    const testBaseUrl = 'https://api.test.com/api/v1';

    test('fetches chart points from backend and stores in client cache', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        expect(request.url.path, contains('/assets/AAPL/history'));
        expect(request.url.queryParameters['range'], equals('1d'));
        expect(request.headers['x-app-secret-key'], isNotNull);

        final mockBody = jsonEncode({
          'success': true,
          'symbol': 'AAPL',
          'range': '1d',
          'data': [
            {'timestamp': 1727100000000, 'price': 220.0},
            {'timestamp': 1727100300000, 'price': 222.5},
            {'timestamp': 1727100600000, 'price': 221.8},
          ],
        });

        return http.Response(mockBody, 200, headers: {'content-type': 'application/json'});
      });

      final service = ChartService(client: mockClient, baseUrl: testBaseUrl);
      service.clearCache();

      // First fetch -> hits HTTP backend
      final points1 = await service.getHistory('AAPL', range: '1d');
      expect(points1.length, equals(3));
      expect(points1.first.price, equals(220.0));
      expect(points1.last.price, equals(221.8));
      expect(requestCount, equals(1));
      expect(service.isCached('AAPL', range: '1d'), isTrue);

      // Second fetch -> served from client in-memory cache, zero HTTP calls!
      final points2 = await service.getHistory('AAPL', range: '1d');
      expect(points2.length, equals(3));
      expect(requestCount, equals(1)); // Still 1!
    });

    test('forceRefresh bypasses client cache and makes HTTP request', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        final mockBody = jsonEncode({
          'success': true,
          'symbol': 'THYAO.IS',
          'range': '1d',
          'data': [
            {'timestamp': 1727100000000, 'price': 295.0},
          ],
        });
        return http.Response(mockBody, 200);
      });

      final service = ChartService(client: mockClient, baseUrl: testBaseUrl);
      service.clearCache();

      await service.getHistory('THYAO.IS');
      expect(requestCount, equals(1));

      // With forceRefresh: true, it must issue a new request
      await service.getHistory('THYAO.IS', forceRefresh: true);
      expect(requestCount, equals(2));
    });

    test('clearCache invalidates cached entries', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'symbol': 'BTC-USD',
            'range': '1w',
            'data': [
              {'timestamp': 1727100000000, 'price': 65000.0},
            ],
          }),
          200,
        );
      });

      final service = ChartService(client: mockClient, baseUrl: testBaseUrl);
      service.clearCache();

      await service.getHistory('BTC-USD', range: '1w');
      expect(requestCount, equals(1));
      expect(service.isCached('BTC-USD', range: '1w'), isTrue);

      service.clearCache();
      expect(service.isCached('BTC-USD', range: '1w'), isFalse);

      await service.getHistory('BTC-USD', range: '1w');
      expect(requestCount, equals(2));
    });

    test('handles HTTP 500 error gracefully without crashing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ChartService(client: mockClient, baseUrl: testBaseUrl);
      service.clearCache();

      final points = await service.getHistory('UNKNOWN_ASSET');
      expect(points, isEmpty);
      expect(service.isCached('UNKNOWN_ASSET'), isFalse);
    });

    test('handles network exceptions gracefully', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final service = ChartService(client: mockClient, baseUrl: testBaseUrl);
      service.clearCache();

      final points = await service.getHistory('NETWORK_FAIL');
      expect(points, isEmpty);
    });
  });
}
