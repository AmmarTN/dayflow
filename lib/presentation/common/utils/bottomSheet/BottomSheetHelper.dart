import 'package:flutter/material.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/widgets/bottom_sheet/btm_sheet_content_edge_shadow_wrapper.dart';
import 'package:dayflow/presentation/common/widgets/bottom_sheet/confirmation_sheet_content.dart';
import 'package:dayflow/presentation/common/widgets/bottom_sheet/operation_status_sheet.dart';

enum SheetStatusType { success, failure }

class BottomSheetHelper {
  BottomSheetHelper();
  static showConfirmationSheet({
    required BuildContext context,
    required String text,
    String? confirmationTitle,
    TextStyle? confirmationTitleTextStyle,
    required Function onConfirmCallback,
  }) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        barrierColor: AppColors.hiaMainRedColor.withValues(alpha: 0.1),
        isDismissible: false,
        enableDrag: true,
        context: context,
        builder: (contextt) => BottomSheetContentEdgeShadowWrapper(
                child: ConfirmationSheetContent(
              onConfirmCallback: onConfirmCallback,
              text: text,
              confirmationTitle: confirmationTitle,
              confirmationTitleTextStyle: confirmationTitleTextStyle,
            )));
  }

  static showWidgetBottomSheet({
    required BuildContext context,
    required Widget content,
    bool isDismissible = true,
    bool enableDrag = true,
    bool textFieldKeepFocus = true,
    bool keyboardLiftsContent = true,
  }) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        isScrollControlled: true,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        context: context,
        builder: (contextt) {
          if (!textFieldKeepFocus) {
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              child: BottomSheetContentEdgeShadowWrapper(
                child: content,
              ),
            );
          }
          return BottomSheetContentEdgeShadowWrapper(
            child: content,
          );
        });
  }

  static showStatusSheet({
    required String text,
    required BuildContext context,
    required SheetStatusType statusType,
    TextStyle? textStyle,
    bool overlayDelayed = true,
  }) async {
    if (overlayDelayed) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isDismissible: true,
        isScrollControlled: true,
        barrierColor: AppColors.secondaryBlueColor.withValues(alpha: 0.1),
        context: context,
        builder: (context) => BottomSheetContentEdgeShadowWrapper(
              child: OperationStatusSheetContent(
                text: text,
                statusType: statusType,
                textStyle: textStyle,
              ),
            ));
  }
}
