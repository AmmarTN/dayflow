import 'package:dayflow/presentation/common/constants/assets_constants.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/common/widgets/images/app_svg_image.dart';

final textFieldEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(100.r),
  borderSide: BorderSide(color: AppColors.hiaBorderColor, width: 1.w),
);
final textFieldFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(100.r),
  borderSide: BorderSide(color: AppColors.blackColor, width: 1.w),
);
final textFieldErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(100.r),
  borderSide: BorderSide(color: AppColors.hiaErrorBorderColor, width: 1.w),
);

class MainTextField extends StatefulWidget {
  const MainTextField({
    super.key,
    this.hintText,
    this.prefixWidget,
    this.suffixWidget,
    this.controller,
    this.hintStyle,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputType = TextInputType.text,
    this.obscure = false,
    this.widePrefix = false,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.maxLines = 1,
    this.inputFormatters,
    this.fillColor,
    this.textAlign,
    this.inputBorder,
    this.contentPadding,
    this.textStyle,
    this.textAlignVertical,
    this.labelText,
    this.textDirection,
    this.readOnly = false,
    this.cursorHeight,
    this.onTap,
    this.errorBorder,
    this.autoFocus = false,
  });
  final String? hintText;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final TextEditingController? controller;
  final TextStyle? hintStyle;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputType? textInputType;
  final bool obscure;
  final bool widePrefix;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final void Function(String)? onChanged;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;
  final TextAlign? textAlign;
  final InputBorder? inputBorder;
  final InputBorder? errorBorder;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextAlignVertical? textAlignVertical;
  final String? labelText;
  final TextDirection? textDirection;
  final bool readOnly;
  final double? cursorHeight;
  final GestureTapCallback? onTap;
  final bool autoFocus;

  @override
  State<MainTextField> createState() => _MainTextFieldState();
}

class _MainTextFieldState extends State<MainTextField> {
  bool fieldFocused = false;
  bool obscuring = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    obscuring = widget.obscure;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != fieldFocused) {
      setState(() {
        fieldFocused = _focusNode.hasFocus;
      });
    }
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixWidget == null) return null;

    final iconColor = fieldFocused ? AppColors.blackColor : AppColors.iconGreyColor;

    // Helper to apply color filter to any widget
    Widget applyColorFilter(Widget w, Color color) {
      // Check if widget is an Icon
      if (w is Icon) {
        return Icon(w.icon, color: color, size: w.size);
      }

      // For SVG and other widgets, wrap in ColorFiltered
      // Use srcIn to replace the color of the graphics
      return ColorFiltered(colorFilter: ColorFilter.mode(color, BlendMode.srcIn), child: w);
    }

    // Handle wrapped prefix widgets (like Padding)
    Widget processWidget(Widget w) {
      if (w is Padding) {
        final child = w.child;
        if (child == null) return w;
        return Padding(padding: w.padding, child: applyColorFilter(child, iconColor));
      } else {
        return applyColorFilter(w, iconColor);
      }
    }

    return processWidget(widget.prefixWidget!);
  }

  InputBorder _getFocusedBorder() {
    if (widget.inputBorder != null) {
      // If custom border is provided, create a focused version with black color
      if (widget.inputBorder is OutlineInputBorder) {
        final border = widget.inputBorder as OutlineInputBorder;
        return border.copyWith(
          borderSide: BorderSide(color: AppColors.blackColor, width: border.borderSide.width),
        );
      }
      return widget.inputBorder!;
    }
    return textFieldFocusedBorder;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 55.h),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AbsorbPointer(
          absorbing: widget.onTap != null,
          child: TextFormField(
            obscuringCharacter: '*',
            autofocus: widget.autoFocus,
            readOnly: widget.readOnly,
            textDirection: widget.textDirection,
            autocorrect: false,
            validator: widget.validator,
            autovalidateMode: widget.autovalidateMode,
            obscureText: obscuring,
            cursorColor: Colors.black,
            cursorErrorColor: AppColors.hiaErrorBorderColor,
            scrollPadding: EdgeInsets.only(bottom: 30.h),
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: widget.labelText,
              labelStyle: widget.labelText != null
                  ? AppTextStyles(context).px14wBold().copyWith(
                      fontSize: fieldFocused ? 14.sp : 12.sp,
                      fontWeight: fieldFocused ? FontWeight.w700 : FontWeight.w400,
                      color: !fieldFocused ? AppColors.primaryGreyA7Color : AppColors.textB9BlueColor,
                    )
                  : null,
              enabledBorder: widget.inputBorder ?? textFieldEnabledBorder,
              disabledBorder: widget.inputBorder ?? textFieldEnabledBorder,
              focusedBorder: _getFocusedBorder(),
              focusedErrorBorder: widget.errorBorder ?? textFieldErrorBorder,
              border: widget.inputBorder ?? textFieldEnabledBorder,
              errorBorder: widget.errorBorder ?? textFieldErrorBorder,
              errorStyle: AppTextStyles(context).px10wRegular().copyWith(color: AppColors.hiaErrorBorderColor),
              filled: true,
              hintStyle:
                  widget.hintStyle ?? AppTextStyles(context).px14wRegular().copyWith(color: AppColors.hiatextBodyColor),
              hintText: widget.hintText,
              contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              fillColor: widget.fillColor ?? Colors.white,
              focusColor: widget.fillColor ?? Colors.white,
              prefixIcon: widget.widePrefix
                  ? _buildPrefixIcon()
                  : _buildPrefixIcon() != null
                  ? IconButton(icon: _buildPrefixIcon()!, onPressed: () {})
                  : null,
              suffixIcon: widget.obscure
                  ? GestureDetector(
                      onTap: () => setState(() => obscuring = !obscuring),
                      child: Transform.scale(
                        scale: 0.6,
                        child: MainSvgImage(path: MainSvgImageConstants.eyeLogo, height: 2.h, width: 2.w),
                      ),
                    )
                  : widget.suffixWidget,
            ),
            textAlignVertical: widget.textAlignVertical,
            textAlign: widget.textAlign ?? TextAlign.start,
            controller: widget.controller,
            onChanged: widget.onChanged,
            textInputAction: widget.textInputAction,
            cursorHeight: widget.cursorHeight ?? 18.h,
            cursorWidth: 1.0.w,
            style:
                widget.textStyle ?? AppTextStyles(context).px14wRegular().copyWith(color: AppColors.hiatextBodyColor),
            focusNode: _focusNode,
            onFieldSubmitted: widget.onFieldSubmitted,
            keyboardType: widget.textInputType,
            maxLines: widget.maxLines,
            inputFormatters: widget.inputFormatters,
          ),
        ),
      ),
    );
  }
}
