import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  final Widget? child;
  final double? radius;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final bool? isBordered;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;
  final BoxBorder? border;
  final BoxShape? shape;
  final Function()? onTap;
  const AppContainer({super.key, this.child, this.radius, this.gradient, this.color, this.padding, this.height, this.width, this.border, this.borderColor, this.isBordered = false, this.shape, this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:onTap,
      child: Container(
        padding: padding,
        margin: margin,
        height: height,
        width: width,
        decoration: BoxDecoration(
          // shape: shape ?? BoxShape.rectangle,
            border: border ?? Border.all(color: borderColor ?? ((isBordered ?? true) ? AppColors.borderColor : AppColors.transparent),),
            borderRadius: BorderRadius.circular(radius ?? 0),
            gradient: gradient,
            color: color
        ),
        child: child,
      ),
    );
  }
}
