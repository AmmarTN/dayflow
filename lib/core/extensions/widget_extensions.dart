import 'package:flutter/material.dart';
import 'package:dayflow/presentation/common/utils/general_utils.dart';


extension WidgetExtension on Widget {
  Widget gradientShader(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          GeneralUtils.defaultLinearGradient(context).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: this,
    );
  }

  Widget toSafer() {
    return SafeArea(child: this);
  }

  Widget withOpacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }
}
