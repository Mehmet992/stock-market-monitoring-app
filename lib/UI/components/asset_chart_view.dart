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

  static const int maxChartPoints = 30;

  static List<ChartPoint> downsamplePoints(
    List<ChartPoint> raw, {
    int maxPoints = maxChartPoints,
  }) {
    if (raw.length <= maxPoints) return raw;

    final List<ChartPoint> sampled = [];
    final double step = (raw.length - 1) / (maxPoints - 1);

    for (int i = 0; i < maxPoints; i++) {
      final int index = (i * step).round().clamp(0, raw.length - 1);
      if (sampled.isEmpty || sampled.last.timestamp != raw[index].timestamp) {
        sampled.add(raw[index]);
      }
    }

    if (sampled.isNotEmpty) {
      sampled[0] = raw.first;
      sampled[sampled.length - 1] = raw.last;
    }

    return sampled;
  }

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
        _points = AssetChartView.downsamplePoints(points);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF11161F) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with scrubber stats
          _buildHeader(theme),
          const SizedBox(height: 16),

          // Chart Area
          SizedBox(
            height: 220,
            child: _buildChartContent(theme, isDark),
          ),
          const SizedBox(height: 16),

          // Timeframe Segmented Chips
          _buildTimeframeSelector(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    if (_isLoading) {
      return SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
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
    final trendColor = isPositive ? const Color(0xFF00C805) : const Color(0xFFFF5000);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatPrice(displayPoint.price),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(displayPoint.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                color: trendColor,
                size: 20,
              ),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_points.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              'Historical chart unavailable for this asset',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final isPositive = _points.last.price >= _points.first.price;
    final lineColor = isPositive ? const Color(0xFF00C805) : const Color(0xFFFF5000);

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

    final gridLineColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_points.length - 1).toDouble(),
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (adjustedMaxY - adjustedMinY) / 4 > 0
              ? (adjustedMaxY - adjustedMinY) / 4
              : 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: gridLineColor,
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
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1B222D) : const Color(0xFF1E293B),
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
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.2),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: lineColor,
                      strokeWidth: 2,
                      strokeColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
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
            curveSmoothness: 0.18,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.18),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(ThemeData theme, bool isDark) {
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
