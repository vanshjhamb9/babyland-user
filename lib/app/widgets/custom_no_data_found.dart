import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/images.dart';
import '../theme/font_style.dart';

class CustomNoDataFound extends StatelessWidget {
  final Widget? heightBox;
  final bool? isClr;

  const CustomNoDataFound({super.key, this.heightBox, this.isClr=true});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: mediaQueryH(context),
      gradient:isClr  == true ? AppColors.backGroundColor : null,
      child: Column(
        children: [
          heightBox ?? SizedBox(height:100),
          Center(
            child: SvgPicture.asset(
              ImageConstants.noData,
              height: 300,
              width: 200,
            ),
          ),
          Text(
            "We couldn't find any results",
            style: AppFontStyle.text_20_600(color: AppColors.black,fontFamily: AppFontFamily.gilroyMedium),
          ),
          SizedBox(height: 5),
          Text(
            "Explore more and shortlist some items",
            style: AppFontStyle.text_16_400(color: AppColors.black,fontFamily: AppFontFamily.gilroyRegular),
          ),
        ],
      ),
    );
  }
}
