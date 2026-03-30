import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/constants/assets_constants.dart';
import 'package:dayflow/presentation/common/theme/app_buttons_theme.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:lottie/lottie.dart';


enum MainBottonType {
  mainBlue,
  secondaryBlueBorder,
  transparentBorderless,
  mainPink,
  thirdRed,
  social,
  declineRed,
  acceptGreen
}

class MainTextButton extends StatelessWidget {
  final Function onPressed;
  final double? width;
  final double? height;
  final String? text;
  final TextStyle? textStyle;
  final MainBottonType type;
  final Widget? child;
  final bool isLoading;
  final bool disabled;
  const MainTextButton({
    super.key,
    required this.onPressed,
    this.width,
    this.height,
    this.text,
    this.textStyle,
    this.type = MainBottonType.mainBlue,
    this.child,
    this.isLoading = false,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 40.h,
      child: TextButton(
        style: AppButtonsTheme.getMainMainTextButtonTheme(type: type),
        onPressed: () {
          if (!isLoading && !disabled) {
            onPressed();
          }
        },
        child: Center(
          child: isLoading
              ? type == MainBottonType.mainPink ||
                      type == MainBottonType.thirdRed
                  ? Transform.scale(
                      scale: 2,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          AppColors.whiteColor,
                          BlendMode.srcATop,
                        ),
                        child: Lottie.asset(
                            MainAssetConstantsAnimations.buttonLoader,
                            fit: BoxFit.contain,
                            repeat: true,
                            reverse: true,
                            animate: true),
                      ),
                    )
                  : Transform.scale(
                      scale: 2,
                      child: Lottie.asset(
                          MainAssetConstantsAnimations.buttonLoader,
                          fit: BoxFit.contain,
                          repeat: true,
                          reverse: true,
                          animate: true),
                    )
              : child ??
                  Text(
                    text!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle ??
                        AppTextStyles(context).px14wBold().copyWith(
                            color: type == MainBottonType.mainBlue ||
                                    type == MainBottonType.mainPink ||
                                    type == MainBottonType.thirdRed ||
                                    type == MainBottonType.acceptGreen ||
                                    type == MainBottonType.declineRed
                                ? AppColors.whiteColor
                                : type == MainBottonType.secondaryBlueBorder
                                    ? AppColors.textThirdBlueColor
                                    : type ==
                                            MainBottonType.transparentBorderless
                                        ? AppColors.textB9BlueColor
                                        : AppColors.blackColor),
                  ),
        ),
      ),
    );
  }
}
