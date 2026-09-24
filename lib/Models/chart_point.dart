class ChartPoint {
  final DateTime timestamp;
  final double price;

  const ChartPoint({
    required this.timestamp,
    required this.price,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    final rawTs = json['timestamp'];
    DateTime parsedTime;
    if (rawTs is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is num) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTs.toInt());
    } else if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    final rawPrice = json['price'];
    final parsedPrice = rawPrice is num ? rawPrice.toDouble() : 0.0;

    return ChartPoint(
      timestamp: parsedTime,
      price: parsedPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'price': price,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartPoint &&
          runtimeType == other.runtimeType &&
          timestamp.millisecondsSinceEpoch == other.timestamp.millisecondsSinceEpoch &&
          price == other.price;

  @override
  int get hashCode => timestamp.millisecondsSinceEpoch.hashCode ^ price.hashCode;

  @override
  String toString() => 'ChartPoint(timestamp: $timestamp, price: $price)';
}
