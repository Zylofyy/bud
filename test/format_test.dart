import 'package:bud/src/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatMoney groups thousands and keeps two decimals', () {
    expect(formatMoney(0), r'$0.00');
    expect(formatMoney(5.8), r'$5.80');
    expect(formatMoney(1015.85), r'$1,015.85');
    expect(formatMoney(-184.15), r'$184.15');
    expect(formatMoney(1234567.891), r'$1,234,567.89');
  });

  test('dates', () {
    final d = DateTime(2026, 10, 2);
    expect(shortDate(d), '2 Oct');
    expect(longDate(d), '2 Oct 2026');
    expect(monthTitle(d), 'October 2026');
    expect(isoDate(d), '2026-10-02');
  });

  test('ordinal', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 112].map(ordinal), [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '11th',
      '12th',
      '13th',
      '21st',
      '22nd',
      '23rd',
      '101st',
      '112th',
    ]);
  });

  test('parseAmount and editableAmount', () {
    expect(parseAmount(''), isNull);
    expect(parseAmount('.'), isNull);
    expect(parseAmount('12.'), 12);
    expect(parseAmount('.5'), 0.5);
    expect(editableAmount(2400), '2400');
    expect(editableAmount(1200.5), '1200.5');
    expect(editableAmount(19.99), '19.99');
  });

  group('AmountInputFormatter', () {
    final formatter = AmountInputFormatter();
    String type(String before, String after) => formatter
        .formatEditUpdate(
          TextEditingValue(text: before),
          TextEditingValue(text: after),
        )
        .text;

    test('accepts digits and one decimal point with two decimals', () {
      expect(type('', '1'), '1');
      expect(type('12', '12.'), '12.');
      expect(type('12.3', '12.34'), '12.34');
    });

    test('turns a comma into a decimal point', () {
      expect(type('12', '12,'), '12.');
    });

    test('rejects anything else', () {
      expect(type('12.34', '12.345'), '12.34');
      expect(type('1.2', '1.2.'), '1.2');
      expect(type('1', '1a'), '1');
      expect(type('1', '-1'), '1');
    });
  });
}
