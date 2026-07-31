enum Currency {
  usd(symbol: '\$', code: 'USD', name: 'US Dollar'),
  eur(symbol: '€', code: 'EUR', name: 'Euro'),
  gbp(symbol: '£', code: 'GBP', name: 'British Pound'),
  tryLira(symbol: '₺', code: 'TRY', name: 'Turkish Lira'),
  jpy(symbol: '¥', code: 'JPY', name: 'Japanese Yen'),
  cad(symbol: 'CA\$', code: 'CAD', name: 'Canadian Dollar'),
  aud(symbol: 'A\$', code: 'AUD', name: 'Australian Dollar'),
  chf(symbol: 'CHF', code: 'CHF', name: 'Swiss Franc'),
  cny(symbol: '¥', code: 'CNY', name: 'Chinese Yuan');

  final String symbol;
  final String code;
  final String name;

  const Currency({
    required this.symbol,
    required this.code,
    required this.name,
  });

  // Display label for Dropdowns or ListTile titles
  String get displayName => '$code ($symbol) - $name';

  // Helper to convert Firestore string back to Enum safely
  static Currency fromCode(String? code, {Currency fallback = Currency.usd}) {
    if (code == null) return fallback;
    return Currency.values.firstWhere(
          (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => fallback,
    );
  }
}