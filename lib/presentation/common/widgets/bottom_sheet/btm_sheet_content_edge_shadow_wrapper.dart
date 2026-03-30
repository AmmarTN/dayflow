import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomSheetContentEdgeShadowWrapper extends StatelessWidget {
  const BottomSheetContentEdgeShadowWrapper({
    super.key,
    required this.child,
    this.keyboardLiftsContent = true,
  });
  final Widget child;

  final bool keyboardLiftsContent;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SafeArea(
          //delete if there is no bottom padding on device
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMPORTANT: Do NOT clip here; let children overflow for decorative elements
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  children: [
                    child,
                    SizedBox(
                      height: 20.h,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
