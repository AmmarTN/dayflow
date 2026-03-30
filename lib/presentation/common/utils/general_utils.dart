import 'package:flutter/material.dart';
import 'package:dayflow/core/debug/logger.dart';
import 'package:dayflow/core/extensions/context_extensions.dart';
import 'package:dayflow/core/extensions/string_extensions.dart';
import 'package:dayflow/presentation/common/constants/ui_constants.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';


class GeneralUtils {
  static BorderRadius defaultBorderRadius({double? radius}) {
    return BorderRadius.all(
        Radius.circular(radius ?? UIConstants.defaultBorderRadius));
  }

  static BorderRadius borderRadius15() {
    return const BorderRadius.all(Radius.circular(15));
  }

  static LinearGradient defaultLinearGradient(BuildContext context,
      {Alignment begin = Alignment.topCenter,
      Alignment end = Alignment.bottomCenter}) {
    return LinearGradient(
      colors: [AppColors.pinkLightEEColor, AppColors.secondaryRedColor],
      begin: begin,
      end: end,
    );
  }

  static BoxDecoration defaultGradientDecoration(BuildContext context,
      {double? radius,
      Alignment begin = Alignment.topCenter,
      Alignment end = Alignment.bottomCenter}) {
    return BoxDecoration(
        gradient: defaultLinearGradient(context, begin: begin, end: end),
        borderRadius: GeneralUtils.borderRadius15());
  }

  static LocaleLanguage getLocaleLanguageFromCode(String code) {
    return code == "en" ? LocaleLanguage.en : LocaleLanguage.ar;
  }

  static String trField(
    BuildContext context, {
    required String textAr,
    required String textEn,
  }) {
    return (context.isArabic ? textAr : textEn).toCapitalized;
  }

  static double timeElapsedInSeconds(int start, int end, {String? message}) {
    Duration duration = Duration(milliseconds: end - start);
    double elapsedSeconds = duration.inMilliseconds / 1000;
    final value = double.parse(elapsedSeconds.toStringAsFixed(2));
    logger.i((message ?? "timeElapsedInSeconds") + "=> $value" 's');
    return value;
  }
}
