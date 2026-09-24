import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stock_market_monitoring_app/Enums/currency.dart';
import 'package:stock_market_monitoring_app/Models/chart_point.dart';
import 'package:stock_market_monitoring_app/Services/chart_service.dart';

class AssetChartView extends StatefulWidget {
  final String symbol;
  final String currency;
  final ChartService? chartService;

  const AssetChartView({
    super.key,
    required this.symbol,
    required this.currency,
    this.chartService,
  });

  @override
  State<AssetChartView> createState() => _AssetChartViewState();
}

class _AssetChartViewState extends State<AssetChartView> {
  late final ChartService _chartService;
  String _selectedRange = '1D';
  bool _isLoading = true;
  List<ChartPoint> _points = [];
  ChartPoint? _touchedPoint;

  static const List<String> _ranges = ['1D', '1W', '1M', '1Y'];

  @override
  void initState() {
    super.initState();
    _chartService = widget.chartService ?? ChartService();
    _loadChartData(_selectedRange);
  }

  @override
  void didUpdateWidget(covariant AssetChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _loadChartData(_selectedRange);
    }
  }

  Future<void> _loadChartData(String range) async {
    setState(() {
      _isLoading = true;
      _touchedPoint = null;
    });

    final points = await _chartService.getHistory(
      widget.symbol,
      range: range.toLowerCase(),
    );

    if (mounted) {
      setState(() {
        _points = points;
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    final currencyObj = Currency.fromCode(widget.currency);
    return '${currencyObj.symbol}${price.toStringAsFixed(price < 1 ? 4 : 2)}';
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    if (_selectedRange == '1D') {
      return '$hour:$minute';
    } else if (_selectedRange == '1W') {
      return '$day/$month $hour:$minute';
    } else {
      return '$day/$month/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with scrubber stats
          _buildHeader(),
          const SizedBox(height: 16),

          // Chart Area
          SizedBox(
            height: 220,
            child: _buildChartContent(),
          ),
          const SizedBox(height: 16),

          // Timeframe Segmented Chips
          _buildTimeframeSelector(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_points.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayPoint = _touchedPoint ?? _points.last;
    final firstPoint = _points.first;
    final change = displayPoint.price - firstPoint.price;
    final changePercent = firstPoint.price > 0 ? (change / firstPoint.price) * 100 : 0.0;
    final isPositive = change >= 0;
    final color = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatPrice(displayPoint.price),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(displayPoint.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: color,
                size: 20,
              ),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_points.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: Colors.grey[600], size: 40),
            const SizedBox(height: 8),
            Text(
              'Historical chart unavailable for this asset',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    final isPositive = _points.last.price >= _points.first.price;
    final lineColor = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    // Compute min and max
    double minPrice = _points.first.price;
    double maxPrice = _points.first.price;
    for (final p in _points) {
      if (p.price < minPrice) minPrice = p.price;
      if (p.price > maxPrice) maxPrice = p.price;
    }
    final rangePadding = (maxPrice - minPrice) * 0.05;
    final adjustedMinY = (minPrice - rangePadding) > 0 ? (minPrice - rangePadding) : 0.0;
    final adjustedMaxY = maxPrice + rangePadding;

    final spots = _points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_points.length - 1).toDouble(),
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (adjustedMaxY - adjustedMinY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white10,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.grey[900]!,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                if (idx >= 0 && idx < _points.length) {
                  final pt = _points[idx];
                  return LineTooltipItem(
                    '${_formatPrice(pt.price)}\n${_formatDate(pt.timestamp)}',
                    TextStyle(
                      color: lineColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              final spotIdx = response.lineBarSpots!.first.spotIndex;
              if (spotIdx >= 0 && spotIdx < _points.length) {
                setState(() {
                  _touchedPoint = _points[spotIdx];
                });
              }
            } else {
              setState(() {
                _touchedPoint = null;
              });
            }
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.1,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withAlpha(64),
                  lineColor.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _ranges.map((range) {
        final isSelected = _selectedRange == range;
        return InkWell(
          onTap: () {
            if (_selectedRange != range) {
              setState(() {
                _selectedRange = range;
              });
              _loadChartData(range);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
