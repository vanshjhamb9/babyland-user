import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final bool isLeading;
  final double? leadingWidth;
  final bool? centerTitle;
  final bool isActions;
  final double? toolbarHeight;
  final double? appbarRightPadding;
  final bool? isPop;
  final bool? isIosBackBtn;
  final Color? backgroundClr;
  final Function()? leadingOnTap;

  const CustomAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.isLeading = true,
    this.leadingWidth,
    this.centerTitle,
    this.isActions = false,
    this.toolbarHeight,
    this.appbarRightPadding,
    this.backgroundClr,
    this.isPop = true,
    this.leadingOnTap,
    this.isIosBackBtn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 0, right: appbarRightPadding ?? 0),
      child: AppBar(
        flexibleSpace: AppContainer(
          gradient: AppColors.backGroundColor.withOpacity(0.11),
        ),
        backgroundColor:backgroundClr?? AppColors.backgroundClr,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
        leading: isLeading
            ? Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: leading ??
              InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap:leadingOnTap ?? (){
                    isPop == true ? Navigator.pop(context) : null;
                  },
                  child:  Icon(
                    isIosBackBtn == true ? Icons.arrow_back_ios : Icons.arrow_back,
                    color: AppColors.black,
                    size: 20,
                  ),
              ),
            )
            : null,
        titleSpacing: 0,
        centerTitle:centerTitle,
        // centerTitle:isLeading,
        title: title,
        leadingWidth: leadingWidth ?? 40,
        toolbarHeight: toolbarHeight ?? 60,
        actions: actions ??
            (isActions
                ? [
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  // Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.notificationScreen);
                },
                child:  Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.white.withValues(alpha: 0.09),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ]
                : []),
        // backgroundColor: Colors.transparent,
        surfaceTintColor: AppColors.backgroundClr,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(65);
}
