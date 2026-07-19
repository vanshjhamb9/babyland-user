import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.alignment,
    this.height,
    this.width,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.textStyle,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textInputType = TextInputType.text,
    this.maxLines,
    this.hintText,
    this.hintStyle,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
    this.contentPadding,
    this.borderDecoration,
    this.fillColor,
    this.filled = true,
    this.validator,
    this.enabled,
    this.onChanged,
    this.onTapOutside,
    this.onTap,
    this.readOnly = false,
    this.borderRadius,
    this.inputFormatters,
    this.minLines,
    this.errorStyle,
    this.borderColor, this.labelText, this.labelStyle,
    this.onFieldSubmitted,
  });

  final Alignment? alignment;

  final double? width;
  final double? height;

  final TextEditingController? controller;

  final FocusNode? focusNode;

  final bool? autofocus;

  final TextStyle? textStyle;

  final bool? obscureText;

  final TextInputAction? textInputAction;

  final TextInputType? textInputType;

  final int? maxLines;

  final int? minLines;

  final String? hintText;
  final String? labelText;

  final TextStyle? hintStyle;
  final TextStyle? labelStyle;

  final Widget? prefix;

  final BoxConstraints? prefixConstraints;

  final Widget? suffix;

  final BoxConstraints? suffixConstraints;

  final EdgeInsets? contentPadding;

  final InputBorder? borderDecoration;

  final Color? fillColor;

  final bool? filled;

  final BorderRadius? borderRadius;

  final FormFieldValidator<String>? validator;
  final bool? enabled;
  final Function(String value)? onChanged;
  final TapRegionCallback? onTapOutside;
  final Function()? onTap;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? errorStyle;
  final Color? borderColor;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
      alignment: alignment ?? Alignment.center,
      child: textFormFieldWidget,
    )
        : textFormFieldWidget;
  }

  Widget get textFormFieldWidget => SizedBox(
    width: width ?? double.maxFinite,
    height: height,
    child: TextFormField(
      // expands: true,
      onTap: onTap,
      onTapOutside:  onTapOutside ?? (event)=> FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: enabled ?? true,
      controller: controller,
      // focusNode: focusNode ?? FocusNode(),
      autofocus: autofocus ?? false,
      style: textStyle ?? AppFontStyle.text_16_400(color:  AppColors.black,fontFamily: AppFontFamily.gilroyRegular),
      obscureText: obscureText!,
      textInputAction: textInputAction,
      keyboardType: textInputType,
      maxLines: maxLines ?? 1,
      minLines: minLines ?? 1,
      decoration: decoration,
      validator: validator,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
    ),
  );
  InputDecoration get decoration => InputDecoration(
    labelText:labelText ,
    hintText: hintText ?? "",
    hintStyle: hintStyle ?? AppFontStyle.text_14_400(color: AppColors.textLightClr),
    labelStyle: labelStyle ?? AppFontStyle.text_16_400(color: AppColors.textClr),
    errorStyle:errorStyle ??  AppFontStyle.text_12_400(
     color:  AppColors.red,
      fontFamily: AppFontFamily.gilroyMedium,
    ),
    errorMaxLines: 2,
    prefixIcon: prefix,
    prefixIconConstraints:
    prefixConstraints ?? BoxConstraints(minWidth: 30),
    suffixIcon: suffix,
    suffixIconConstraints: suffixConstraints,
    isDense: true,
    // contentPadding: contentPadding ??REdgeInsets.symmetric(vertical: 15, horizontal: 20),
    contentPadding: contentPadding ?? EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    fillColor: fillColor ?? AppColors.white,
    filled: filled,
    border: borderDecoration ??
        OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? AppColors.grey),
          borderRadius:
          borderRadius ?? BorderRadius.all(Radius.circular(8)),
        ),
    enabledBorder: borderDecoration ??
        OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? AppColors.grey),
          borderRadius:
          borderRadius ?? BorderRadius.all(Radius.circular(8)),
        ),
    focusedBorder: borderDecoration ??
        OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? AppColors.grey),
          borderRadius:
          borderRadius ?? BorderRadius.all(Radius.circular(8)),
        ),
  );
}

/// Extension on [CustomTextFormField] to facilitate inclusion of all types of border style etc
extension TextFormFieldStyleHelper on CustomTextFormField {
  static OutlineInputBorder get fillPrimary => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  );
  static OutlineInputBorder get fillWhiteA => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  );
  static OutlineInputBorder get fillPrimaryTL24 => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide.none,
  );
  static UnderlineInputBorder get underLineOnError =>
      const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red,
        ),
      );
  static OutlineInputBorder get outlineBlueGrayTL20 => OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  );
  static OutlineInputBorder get fillWhiteATL16 => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  );
  static OutlineInputBorder get fillPrimaryTL12 => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );
  static OutlineInputBorder get outlineBlueGrayTL15 => OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide.none,
  );
}
