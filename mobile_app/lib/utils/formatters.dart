import 'package:intl/intl.dart';

class AppFormatters {
  static String currency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
