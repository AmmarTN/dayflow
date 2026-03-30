import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:dayflow/presentation/common/constants/assets_constants.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/common/utils/bottomSheet/BottomSheetHelper.dart';
import 'package:dayflow/presentation/common/widgets/buttons/main_button.dart';
import 'package:dayflow/presentation/common/widgets/images/app_svg_image.dart';

class OperationStatusSheetContent extends StatelessWidget {
  const OperationStatusSheetContent({super.key, required this.text, required this.statusType, this.textStyle});
  final String text;
  final SheetStatusType statusType;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight - 120.h;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.loose,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.r),
                topRight: Radius.circular(30.r),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 100.h,
              ),
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          text,
                          style: textStyle ?? AppTextStyles(context).px16wRegular(),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 27.h),
                        MainButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          text: statusType == SheetStatusType.success ? t.common.done : t.common.back,
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -57.h,
          left: 0,
          right: 0,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(top: 70.h, child: MainSvgImage(path: MainSvgImageConstants.commonEclipseShape)),
                // Decorative circle
                Container(
                  width: 144.w,
                  height: 145.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Main WiFi icon container
                Container(
                  width: 116.w,
                  height: 116.h,
                  padding: EdgeInsets.all(3.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A0D14).withValues(alpha: 0.06),
                        offset: const Offset(0, 0),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: MainSvgImage(
                      path: statusType == SheetStatusType.success
                          ? MainSvgImageConstants.commonSuccessIcon
                          : MainSvgImageConstants.commonFailureIcon),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    /*  Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            OperationStatusWidget(statusType: statusType),
            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: AutoSizeText(
                text,
                style: textStyle ?? AppTextStyles(context).px14wRegular(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 27.h),
            Center(
              child: SizedBox(
                  height: 44.h,
                  width: double.infinity,
                  child: MainTextButton(
                    type: MainBottonType.secondaryBlueBorder,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    text: statusType == SheetStatusType.success ? t.common.done : t.common.back,
                  )),
            ),
          ],
        )
      ],
    );*/
  }
}
