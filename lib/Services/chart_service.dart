import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_market_monitoring_app/Models/chart_point.dart';
import 'package:stock_market_monitoring_app/main_api.dart';

class CachedChartData {
  final List<ChartPoint> points;
  final DateTime fetchedAt;
  final Duration ttl;

  CachedChartData({
    required this.points,
    required this.fetchedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(fetchedAt) > ttl;
}

class ChartService {
  static final ChartService _instance = ChartService._internal();
  factory ChartService({http.Client? client, String? baseUrl}) {
    if (client != null || baseUrl != null) {
      return ChartService._internal(client: client, baseUrl: baseUrl);
    }
    return _instance;
  }

  final http.Client _client;
  final String _baseUrl;

  ChartService._internal({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? kBackendBaseUrl;

  final Map<String, CachedChartData> _cache = {};

  /// Determines cache TTL based on timeframe
  Duration _getTtlForRange(String range) {
    switch (range.toLowerCase()) {
      case '1w':
      case '5d':
        return const Duration(minutes: 15);
      case '1m':
        return const Duration(hours: 1);
      case '1y':
        return const Duration(hours: 4);
      case '1d':
      default:
        return const Duration(minutes: 2);
    }
  }

  /// Fetches historical chart points with two-tier cache protection
  Future<List<ChartPoint>> getHistory(
    String symbol, {
    String range = '1d',
    bool forceRefresh = false,
  }) async {
    final sym = symbol.toUpperCase().trim();
    final rng = range.toLowerCase().trim();
    final cacheKey = '${sym}_$rng';

    // 1. Check in-memory client cache
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        if (kDebugMode) {
          debugPrint('[ChartService] Client cache hit for $cacheKey (${cached.points.length} points)');
        }
        return cached.points;
      }
    }

    // 2. Fetch from backend
    try {
      final encodedSymbol = Uri.encodeComponent(sym);
      final url = Uri.parse('$_baseUrl/assets/$encodedSymbol/history?range=$rng');

      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'x-app-secret-key': kAppSecretKey,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> rawData = json['data'] ?? [];

        final List<ChartPoint> points = rawData
            .whereType<Map<String, dynamic>>()
            .map((item) => ChartPoint.fromJson(item))
            .where((p) => p.price > 0)
            .toList();

        if (points.isNotEmpty) {
          _cache[cacheKey] = CachedChartData(
            points: points,
            fetchedAt: DateTime.now(),
            ttl: _getTtlForRange(rng),
          );
        }

        return points;
      } else {
        if (kDebugMode) {
          debugPrint('[ChartService] HTTP ${response.statusCode} for $cacheKey: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChartService] Error fetching history for $cacheKey: $e');
      }
    }

    // Fallback to expired cache if available during error
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!.points;
    }

    return [];
  }

  bool isCached(String symbol, {String range = '1d'}) {
    final cacheKey = '${symbol.toUpperCase().trim()}_${range.toLowerCase().trim()}';
    return _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired;
  }

  void clearCache() {
    _cache.clear();
  }
}
