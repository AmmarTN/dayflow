import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/common/widgets/buttons/main_text_button.dart';

class ConfirmationSheetContent extends StatelessWidget {
  const ConfirmationSheetContent(
      {super.key,
      required this.text,
      required this.onConfirmCallback,
      this.confirmationTitle,
      this.confirmationTitleTextStyle});
  final String text;
  final Function onConfirmCallback;
  final String? confirmationTitle;
  final TextStyle? confirmationTitleTextStyle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24.h),
          Row(
            children: [
              Text(
                confirmationTitle ?? context.t.common.confirm,
                style: confirmationTitleTextStyle ??
                    AppTextStyles(context).px19wMedium(),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(text, style: AppTextStyles(context).px14wRegular()),
          SizedBox(height: 24.h),
          Row(children: [
            Flexible(
              child: MainTextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirmCallback();
                  },
                  text: context.t.common.confirm),
            ),
            SizedBox(width: 20.w),
            Flexible(
              child: MainTextButton(
                onPressed: () => Navigator.pop(context),
                text: context.t.common.cancel,
                type: MainBottonType.mainBlue,
              ),
            ),
          ]),
          SizedBox(height: 28.h),
        ],
      ),
    );
  }
}
