import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

extension CustomTextStyles on TextStyle {
  /// Font Family
  /// Latin
  // Calibri

  /// Latin - Inter
  TextStyle get toEnglishFont =>
      GoogleFonts.urbanist(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: 0.0);

  /// Arabic
  TextStyle get toArabicFont => GoogleFonts.almarai(fontSize: fontSize, fontWeight: fontWeight, color: color);

  /// Text Color
  TextStyle get toPrimaryWhiteColor => copyWith(color: AppColors.whiteColor);
  TextStyle get toRamliColor => copyWith(color: AppColors.ramliColor);
  TextStyle get toPrimaryGreyColor => copyWith(color: AppColors.primaryGreyA7Color);
  TextStyle get toPrimaryRedColor => copyWith(color: AppColors.secondaryBlueColor);
  TextStyle get toTextB9BlueColor => copyWith(color: AppColors.textB9BlueColor);
  TextStyle get toPrimaryBlueColor => copyWith(color: AppColors.primaryBlueColor);
  TextStyle get toPrimaryBlackishColor => copyWith(color: AppColors.primaryBlackishColor);
  TextStyle get toTextThirdBlueColor => copyWith(color: AppColors.textThirdBlueColor);
  TextStyle get toPinkLightEEColor => copyWith(color: AppColors.pinkLightEEColor);
  TextStyle get toWhiteColor => copyWith(color: AppColors.whiteColor);
  TextStyle get toBlackColor => copyWith(color: AppColors.blackColor);
  TextStyle get toSecondaryBlueColor => copyWith(color: AppColors.secondaryBlueColor);
}

class TextStylesManager {
  static TextTheme getAppTextTheme({required bool isArabic}) {
    TextTheme defaultTextTheme = isArabic
        ? GoogleFonts.almaraiTextTheme()
        : const TextTheme().copyWith(labelSmall: TextStyle().toEnglishFont);
    return defaultTextTheme;
  }
}

class AppTextStyles {
  final BuildContext context;
  late final bool isArabic;
  AppTextStyles(this.context) {
    final locale = Localizations.localeOf(context);
    isArabic = locale.languageCode == 'ar';
  }

  TextStyle _getStyle(double fontSize, FontWeight fontWeight) {
    if (isArabic) {
      return GoogleFonts.almarai(fontSize: fontSize.sp, fontWeight: fontWeight);
    } else {
      return GoogleFonts.urbanist(fontSize: fontSize.sp, fontWeight: fontWeight, letterSpacing: 0);
    }
  }

  // px10
  TextStyle px10wRegular() => _getStyle(10, FontWeight.w400);
  TextStyle px10wMedium() => _getStyle(10, FontWeight.w500);
  TextStyle px10wSemiBold() => _getStyle(10, FontWeight.w600);
  TextStyle px10wBold() => _getStyle(10, FontWeight.w700);
  // px11
  TextStyle px11wRegular() => _getStyle(11, FontWeight.w400);
  TextStyle px11wMedium() => _getStyle(11, FontWeight.w500);
  TextStyle px11wSemiBold() => _getStyle(11, FontWeight.w600);
  TextStyle px11wBold() => _getStyle(11, FontWeight.w700);

  // px12
  TextStyle px12wRegular() => _getStyle(12, FontWeight.w400);
  TextStyle px12wMedium() => _getStyle(12, FontWeight.w500);
  TextStyle px12wSemiBold() => _getStyle(12, FontWeight.w600);
  TextStyle px12wBold() => _getStyle(12, FontWeight.w700);
  // px12
  TextStyle px13wRegular() => _getStyle(13, FontWeight.w400);
  TextStyle px13wMedium() => _getStyle(13, FontWeight.w500);
  TextStyle px13wSemiBold() => _getStyle(13, FontWeight.w600);
  TextStyle px13wBold() => _getStyle(13, FontWeight.w700);
  // px14
  TextStyle px14wRegular() => _getStyle(14, FontWeight.w400);
  TextStyle px14wMedium() => _getStyle(14, FontWeight.w500);
  TextStyle px14wSemiBold() => _getStyle(14, FontWeight.w600);
  TextStyle px14wBold() => _getStyle(14, FontWeight.w700);
  // px14.7
  TextStyle px14_7wRegular() => _getStyle(14.7, FontWeight.w400);
  TextStyle px14_7wMedium() => _getStyle(14.7, FontWeight.w500);
  TextStyle px14_7wSemiBold() => _getStyle(14.7, FontWeight.w600);
  TextStyle px14_7wBold() => _getStyle(14.7, FontWeight.w700);
  // px15
  TextStyle px15wRegular() => _getStyle(15, FontWeight.w400);
  TextStyle px15wMedium() => _getStyle(15, FontWeight.w500);
  TextStyle px15wSemiBold() => _getStyle(15, FontWeight.w600);
  TextStyle px15wBold() => _getStyle(15, FontWeight.w700);
  // px16
  TextStyle px16wRegular() => _getStyle(16, FontWeight.w400);
  TextStyle px16wMedium() => _getStyle(16, FontWeight.w500);
  TextStyle px16wSemiBold() => _getStyle(16, FontWeight.w600);
  TextStyle px16wBold() => _getStyle(16, FontWeight.w700);
  // px18
  TextStyle px18wRegular() => _getStyle(18, FontWeight.w400);

  TextStyle px18wSemiBold() => _getStyle(18, FontWeight.w600);
  TextStyle px18wBold() => _getStyle(18, FontWeight.w700);
  // px17
  TextStyle px17wRegular() => _getStyle(17, FontWeight.w400);

  TextStyle px17wSemiBold() => _getStyle(17, FontWeight.w600);
  TextStyle px17wBold() => _getStyle(17, FontWeight.w700);

  // px19
  TextStyle px19wRegular() => _getStyle(19, FontWeight.w400);
  TextStyle px19wMedium() => _getStyle(19, FontWeight.w500);
  TextStyle px19wSemiBold() => _getStyle(19, FontWeight.w600);
  TextStyle px19wBold() => _getStyle(19, FontWeight.w700);
  // px20
  TextStyle px20wRegular() => _getStyle(20, FontWeight.w400);
  TextStyle px20wMedium() => _getStyle(20, FontWeight.w500);
  TextStyle px20wSemiBold() => _getStyle(20, FontWeight.w600);
  TextStyle px20wBold() => _getStyle(20, FontWeight.w700);
  // px22
  TextStyle px22wRegular() => _getStyle(22, FontWeight.w400);
  TextStyle px22wMedium() => _getStyle(22, FontWeight.w500);
  TextStyle px22wSemiBold() => _getStyle(22, FontWeight.w600);
  TextStyle px22wBold() => _getStyle(22, FontWeight.w700);
  // px24
  TextStyle px24wRegular() => _getStyle(24, FontWeight.w400);
  TextStyle px24wMedium() => _getStyle(24, FontWeight.w500);

  TextStyle px24wSemiBold() => _getStyle(24, FontWeight.w600);

  TextStyle px24wBold() => _getStyle(24, FontWeight.w700);

  // px28
  TextStyle px28wRegular() => _getStyle(28, FontWeight.w400);
  TextStyle px28wMedium() => _getStyle(28, FontWeight.w500);
  TextStyle px28wSemiBold() => _getStyle(28, FontWeight.w600);
  TextStyle px28wBold() => _getStyle(28, FontWeight.w700);
  // px32
  TextStyle px32wMedium() => _getStyle(32, FontWeight.w500);

  TextStyle px32wSemiBold() => _getStyle(32, FontWeight.w600);

  TextStyle px32wBold() => _getStyle(32, FontWeight.w700);
  // px44.75
  TextStyle px44_75wBold() => _getStyle(44.75, FontWeight.w700);
}
