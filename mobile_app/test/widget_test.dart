import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/utils/formatters.dart';

void main() {
  test('AppFormatters currency and date test', () {
    String currency = AppFormatters.currency(150000);
    expect(currency, 'Rp 150.000');
  });
}
