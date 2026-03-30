import 'package:flutter/cupertino.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';

extension ScreenExtension on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get paddingTop => MediaQuery.of(this).padding.top;
  bool get isArabic =>
      Localizations.localeOf(this).languageCode == LocaleLanguage.ar.name;
}
