class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  static const usd = AppCurrency(code: 'USD', name: 'US Dollar', symbol: r'$');

  static const values = [
    usd,
    AppCurrency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    AppCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
    AppCurrency(code: 'GBP', name: 'British Pound', symbol: '£'),
    AppCurrency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    AppCurrency(code: 'AUD', name: 'Australian Dollar', symbol: r'$'),
    AppCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: r'$'),
    AppCurrency(code: 'SGD', name: 'Singapore Dollar', symbol: r'$'),
  ];

  static AppCurrency fromCode(String? code) {
    return values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => usd,
    );
  }
}

abstract final class CurrencyFormatter {
  static AppCurrency _currency = AppCurrency.usd;

  static AppCurrency get currency => _currency;

  static String get symbol => _currency.symbol;

  static void setCurrency(AppCurrency currency) {
    _currency = currency;
  }

  static String rupees(num value) => format(value);

  static String cents(int value) => format(value / 100);

  static String format(num value) {
    final isNegative = value < 0;
    final text = value.abs().toStringAsFixed(0);
    if (text.length <= 3) {
      return '${isNegative ? '-' : ''}${_currency.symbol}$text';
    }

    final head = text.substring(0, text.length - 3);
    final tail = text.substring(text.length - 3);
    final groups = <String>[];
    for (var index = head.length; index > 0; index -= 2) {
      final start = (index - 2).clamp(0, head.length);
      groups.insert(0, head.substring(start, index));
    }

    return '${isNegative ? '-' : ''}${_currency.symbol}${groups.join(',')},$tail';
  }

  static String compact(num value) {
    final amount = value.toDouble();
    final text = amount.toStringAsFixed(
      amount.truncateToDouble() == amount ? 0 : 2,
    );
    return '${_currency.symbol}$text';
  }
}
