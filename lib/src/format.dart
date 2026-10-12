import 'package:flutter/services.dart';

import 'theme.dart';

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// `$1,234.50` — always positive, two decimals, comma thousands.
String formatMoney(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '$currencySymbol$grouped${fixed.substring(dot)}';
}

/// `12 Oct`
String shortDate(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]}';

/// `12 Oct 2026`
String longDate(DateTime d) => '${shortDate(d)} ${d.year}';

/// `October 2026`
String monthTitle(DateTime d) => '${_months[d.month - 1]} ${d.year}';

/// `2026-10-12`
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

double roundCents(double v) => (v * 100).roundToDouble() / 100;

/// Parses what [AmountInputFormatter] lets through; null when there's no number.
double? parseAmount(String text) {
  final v = double.tryParse(text.trim());
  return v != null && v.isFinite ? v : null;
}

/// The text to prefill an amount field with: `2400`, `1200.5`.
String editableAmount(double v) {
  if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
  var s = v.toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return s;
}

/// Accepts digits with at most one decimal point and two decimals. A comma
/// typed on a locale keypad becomes a decimal point.
class AmountInputFormatter extends TextInputFormatter {
  static final _valid = RegExp(r'^\d{0,9}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (!_valid.hasMatch(text)) return oldValue;
    return newValue.copyWith(text: text);
  }
}
