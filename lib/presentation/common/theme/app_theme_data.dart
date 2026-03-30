import 'package:flutter/material.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';
import 'package:dayflow/presentation/common/theme/app_buttons_theme.dart';
import 'package:dayflow/presentation/common/utils/general_utils.dart';
import 'package:dayflow/presentation/common/widgets/buttons/main_text_button.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppThemeData {
  const AppThemeData._();
  static ThemeData getAppThemeData({required LocaleLanguage language, required BuildContext context}) {
    bool isDarkMode = false;
    bool isArabic = language == LocaleLanguage.ar;
    final dynamicBgColor = isDarkMode ? AppColors.blackColor : AppColors.primaryGreyA7Color;
    final dynamicTextColor = isDarkMode ? AppColors.whiteColor : AppColors.blackColor;
    final dynamicCardColor = isDarkMode ? AppColors.primaryBlackishColor : AppColors.whiteColor;
    // final focusedDecorationBorder = OutlineInputBorder(
    //   borderSide: const BorderSide(color: AppColors.whiteColor, width: 1),
    //   borderRadius: GeneralUtils.defaultBorderRadius(),
    // );
    final inputDecorationBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.whiteColor, width: 0),
      borderRadius: GeneralUtils.defaultBorderRadius(),
    );
    final dynamicThemeData = ThemeData(
      textTheme: TextStylesManager.getAppTextTheme(isArabic: isArabic),
      scaffoldBackgroundColor: dynamicBgColor,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      disabledColor: AppColors.greyDarkCEColor,
      appBarTheme: AppBarTheme(
        backgroundColor: dynamicCardColor,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.secondaryBlueColor),
      colorScheme: ColorScheme.fromSwatch(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        backgroundColor: dynamicBgColor,
        cardColor: dynamicCardColor,
      ).copyWith(
        primary: isDarkMode ? AppColors.ramliColor : AppColors.textB9BlueColor,
        onPrimary: isDarkMode ? AppColors.ramliColor : AppColors.ramliColor,
        secondary: isDarkMode ? AppColors.secondaryBlueColor : AppColors.secondaryBlueColor,
        onSecondary: isDarkMode ? AppColors.secondaryBlueColor : AppColors.secondaryBlueColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.whiteColor,
        focusColor: AppColors.whiteColor,
        focusedBorder: inputDecorationBorder,
        enabledBorder: inputDecorationBorder,
        errorBorder: inputDecorationBorder,
        border: inputDecorationBorder,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: dynamicTextColor,
        selectionHandleColor: AppColors.textB9BlueColor,
        selectionColor: AppColors.hiaMainRedColor,
      ),
      textButtonTheme:
          TextButtonThemeData(style: AppButtonsTheme.getMainMainTextButtonTheme(type: MainBottonType.mainBlue)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.whiteColor,
      ),
    );

    return dynamicThemeData;
  }
}
