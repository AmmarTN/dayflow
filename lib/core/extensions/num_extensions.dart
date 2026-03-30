import 'package:intl/intl.dart';

final oCcyFraction = NumberFormat("#,##0.00", "en_US");
final oCcy = NumberFormat("#,##0", "en_US");

extension NumExtension on num {
  String currencyFormat({bool withFraction = false}) {
    return withFraction ? oCcyFraction.format(this) : oCcy.format(this);
  }
}
