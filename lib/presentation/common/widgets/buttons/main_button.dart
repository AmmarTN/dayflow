import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/constants/assets_constants.dart';
import 'package:dayflow/presentation/common/theme/app_buttons_theme.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:lottie/lottie.dart';

class MainButton extends StatelessWidget {
  final Function onPressed;
  final double? width;
  final double? height;
  final String? text;
  final TextStyle? textStyle;
  final MainButtonType type;
  final Widget? child;
  final bool isLoading;
  final bool disabled;

  const MainButton({
    super.key,
    required this.onPressed,
    this.width,
    this.height,
    this.text,
    this.textStyle,
    this.type = MainButtonType.mainGreen,
    this.child,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 55.h,
      child: Stack(
        children: [
          // Base button
          TextButton(
            style: AppButtonsTheme.getMainButtonTheme(type: type),
            onPressed: () {
              if (!isLoading && !disabled) {
                onPressed();
              }
            },
            child: Center(
              child: isLoading
                  ? Transform.scale(
                      scale: 2,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          type == MainButtonType.mainGreen ? AppColors.whiteColor : AppColors.secondaryBlueColor,
                          BlendMode.srcATop,
                        ),
                        child: Lottie.asset(
                          MainAssetConstantsAnimations.buttonLoader,

                          height: 30.h,
                          fit: BoxFit.contain,
                          repeat: true,
                          reverse: true,
                          animate: true,
                        ),
                      ),
                    )
                  : child ??
                        Text(
                          text ?? "",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              textStyle ??
                              AppTextStyles(context).px16wMedium().copyWith(
                                color: _getTextColorForType(type),
                                letterSpacing: -0.084,
                                height: 1.43,
                              ),
                        ),
            ),
          ),

          // Glassy overlay for mainBlack type
        ],
      ),
    );
  }

  Color _getTextColorForType(MainButtonType type) {
    switch (type) {
      case MainButtonType.mainGreen:
        return AppColors.whiteColor;
      case MainButtonType.secondaryGrey:
        return AppColors.blackColor;
    }
  }
}
