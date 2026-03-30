import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/utils/general_utils.dart';
import 'package:dayflow/presentation/common/widgets/buttons/main_text_button.dart';

enum MainButtonType { mainGreen, secondaryGrey }

class AppButtonsTheme {
  static final blueBorderlessButtonStyle = ButtonStyle(
    // minimumSize: MaterialStateProperty.all<Size>(Size(double.infinity, 44.h)),
    overlayColor: WidgetStateProperty.all<Color>(AppColors.whiteColor.withValues(alpha: .25)),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.secondaryBlueColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.secondaryBlueColor),
    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: GeneralUtils.defaultBorderRadius(radius: 15.r)),
    ),
  );

  static final secondaryBlueBorderButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.secondaryBlueColor.withValues(alpha: .08)),
    foregroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
    backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
    side: WidgetStateProperty.all<BorderSide>(const BorderSide(width: 1, color: AppColors.secondaryBlueColor)),
  );
  static final mainPinkButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.whiteColor.withValues(alpha: 0.5)),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.pinkLightEEColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.pinkLightEEColor),
    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero),
  );

  static final transparentBorderlessButtonStyle = secondaryBlueBorderButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.pinkLightEEColor.withValues(alpha: .10)),
    side: WidgetStateProperty.all<BorderSide>(const BorderSide(width: 1, color: Colors.transparent)),
  );

  static final thirdRedButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.greyLightEEEColor.withValues(alpha: 0.5)),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.secondaryRedColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.secondaryRedColor),
  );

  static final socialButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.greyLightEEEColor),
    foregroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
    backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
    side: WidgetStateProperty.all<BorderSide>(const BorderSide(width: 1, color: AppColors.whiteColor)),
  );

  static final acceptButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.greyLightEEEColor),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.successColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.successColor),
  );
  static final declineButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.greyLightEEEColor),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.secondaryGradientRedColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.secondaryGradientRedColor),
  );
  static final mainGreenButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.whiteColor.withValues(alpha: 0.5)),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.primaryGreenColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.primaryGreenColor),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: GeneralUtils.defaultBorderRadius(radius: 100.r)),
    ),
  );
  static final secondaryGreyButtonStyle = blueBorderlessButtonStyle.copyWith(
    overlayColor: WidgetStateProperty.all<Color>(AppColors.whiteColor.withValues(alpha: 0.5)),
    foregroundColor: WidgetStateProperty.all<Color>(AppColors.greyBodyTextColor),
    backgroundColor: WidgetStateProperty.all<Color>(AppColors.greyBodyTextColor),
  );

  static ButtonStyle getMainMainTextButtonTheme({required MainBottonType type}) {
    switch (type) {
      case MainBottonType.mainBlue:
        return blueBorderlessButtonStyle;
      case MainBottonType.secondaryBlueBorder:
        return secondaryBlueBorderButtonStyle;
      case MainBottonType.transparentBorderless:
        return transparentBorderlessButtonStyle;
      case MainBottonType.mainPink:
        return mainPinkButtonStyle;
      case MainBottonType.thirdRed:
        return thirdRedButtonStyle;
      case MainBottonType.social:
        return socialButtonStyle;
      case MainBottonType.acceptGreen:
        return acceptButtonStyle;
      case MainBottonType.declineRed:
        return declineButtonStyle;
    }
  }

  static ButtonStyle getMainButtonTheme({required MainButtonType type}) {
    switch (type) {
      case MainButtonType.mainGreen:
        return mainGreenButtonStyle;
      case MainButtonType.secondaryGrey:
        return secondaryGreyButtonStyle;
    }
  }
}
