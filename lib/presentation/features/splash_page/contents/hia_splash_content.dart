import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/presentation/common/constants/assets_constants.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/common/widgets/images/app_asset_image.dart';

class MainSplashContent extends StatelessWidget {
  const MainSplashContent({super.key, required this.controller});
  final AnimationController controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          MainImageAsset(path: MainImageAssetConstants.splashBackgroundImg, fit: BoxFit.cover),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 110.w),
                  child: MainImageAsset(path: MainImageAssetConstants.dayflowLogoImg, fit: BoxFit.contain),
                ),
                SizedBox(height: 20.h),
                Text('Plan your day, your way.', style: AppTextStyles(context).px14wRegular().toWhiteColor),
                SizedBox(height: 10.h),
                Transform.scale(
                  scale: 0.45,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.w,
                    color: AppColors.whiteColor,
                    backgroundColor: AppColors.whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
