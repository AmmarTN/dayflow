import 'package:dayflow/core/extensions/context_extensions.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/common/widgets/images/app_svg_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BNavBarItem extends StatelessWidget {
  final String unselectedPic;
  final String selectedPic;
  final bool selected;
  final String label;

  const BNavBarItem({
    super.key,
    required this.unselectedPic,
    required this.selectedPic,
    required this.selected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MainSvgImage(path: selected ? selectedPic : unselectedPic, height: 24.h, width: 24.h),
        SizedBox(height: 6.h),
        selected
            ? Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles(context).px12wRegular().copyWith(
                  color: AppColors.primaryGreenColor,
                  letterSpacing: !context.isArabic ? 0.0 : null,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles(context).px12wRegular().copyWith(
                  color: AppColors.iconGreyColor,
                  letterSpacing: !context.isArabic ? 0.0 : null,
                ),
              ),
      ],
    );
  }
}

class BNavBarItemSelected extends StatelessWidget {
  final String unselectedPic;
  final String selectedPic;
  final String label;

  const BNavBarItemSelected({super.key, required this.unselectedPic, required this.selectedPic, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: MainSvgImage(path: selectedPic, height: 24.h, width: 24.h),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles(context).px10wSemiBold().copyWith(color: AppColors.annebiRedColor),
        ),
        SizedBox(height: 4.h),
      ],
    );
  }
}
