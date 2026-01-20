import 'package:flutter/material.dart';

double mediaQueryW(BuildContext context) => MediaQuery.of(context).size.width;
double mediaQueryH(BuildContext context) => MediaQuery.of(context).size.height;


class SBox extends StatelessWidget {
  final double? h;
  final double? w;
  final Widget? child;

  const SBox({super.key, this.h, this.w, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: h,
      width: w,
      child: child,
    );
  }
}

