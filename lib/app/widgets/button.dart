import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/cupertino.dart';

class Button extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;
  final void Function()? onTap;
  final BoxBorder? border;
  final double? width;
  final double? height;
  final String? text;
  final TextStyle? textStyle;
  final double? borderRadius;

  const Button({
    super.key,
    this.child,
    this.padding,
    this.color,
    this.gradient,
    this.onTap,
    this.border,
    this.width,
    this.height,
    this.text,
    this.textStyle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        padding: padding ?? EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          border: border,
          gradient: (gradient == null && color == null) ? AppColors.buttonClr : gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? 100),
        ),
        child: Center(child: child ?? Text(text ?? "",style: textStyle ?? AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),)),
      ),
    );
  }
}