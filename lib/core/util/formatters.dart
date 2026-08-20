import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final _currency = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);
  static final _date = DateFormat('yyyy/MM/dd');
  static final _dateTime = DateFormat('yyyy/MM/dd HH:mm');

  static String yen(num value) => _currency.format(value);
  static String date(DateTime? d) => d == null ? '-' : _date.format(d);
  static String dateTime(DateTime? d) => d == null ? '-' : _dateTime.format(d);

  static String quantity(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }
}
