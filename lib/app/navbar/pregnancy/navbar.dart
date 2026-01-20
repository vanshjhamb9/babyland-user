import 'package:babyland/app/navbar/pregnancy/navbar_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/flow.dart';

class NavbarView extends StatefulWidget {
  final FlowType? flow;
  const NavbarView({super.key,this.flow});

  @override
  State<NavbarView> createState() => _NavbarViewState();
}

class _NavbarViewState extends State<NavbarView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffdfcff),

      body: Consumer<NavBarProvider>(
        builder: (context, provider, child) {
          return provider.screens[provider.selectedIndex];
        },
      ),

      floatingActionButton: Consumer<NavBarProvider>(
          builder: (context, provider, child) {
            return  provider.selectedIndex != 0 ? SizedBox.shrink() :
            InkWell(
              onTap:()=> Navigator.pushNamed(context, AppRoutes.dailyLogs,
                  arguments: {
                    "prePregnancyFlow" : false,
                    "pregnancyFlow" : widget.flow == FlowType.pregnancy ? true : false,
                  }
              ),
              child: Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: AppContainer(
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 8),
                    radius: 100,
                    gradient: AppColors.buttonClr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add,color: AppColors.white),
                    SizedBox(width: 2),
                    Text("Add Daily log",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.white),),
                  ],
                ),
              ),
                        ),
            );
        }
      ),


      bottomNavigationBar:Consumer<NavBarProvider>(
        builder: (context, provider, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 10,
              color: Colors.white,
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem( "Home", 0, provider),
                    _buildNavItem( "Tracker", 1, provider),
                    _buildNavItem("Insights", 2, provider),
                    _buildNavItem("Community", 3, provider),
                    _buildProfileItem(4, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(String label, int index, NavBarProvider provider) {
    final isSelected = provider.selectedIndex == index;
    return InkWell(
      highlightColor: AppColors.transparent,
      splashColor: AppColors.transparent,
      onTap: () => provider.setSelectedIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImage(path: provider.imagesList[index],color:isSelected ? AppColors.buttonClr1 : AppColors.textLightClr),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppFontStyle.text_12_400(
                fontFamily:isSelected? AppFontFamily.gilroySemiBold : AppFontFamily.gilroyMedium,
                color:isSelected ? AppColors.textClr : AppColors.textLightClr)
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(int index, NavBarProvider provider) {
    final isSelected = provider.selectedIndex == index;
    return InkWell(
      splashColor: AppColors.transparent,
      highlightColor: AppColors.transparent,
      onTap: () => provider.setSelectedIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppContainer(
            gradient: AppColors.buttonClr,
            radius: 100,
            padding: EdgeInsets.all(1),
            child: CustomImage(
              h: 26,
              w: 26,
              borderRadius: BorderRadius.circular(100),
              path: "https://i.pravatar.cc/300",),
          ),
          const SizedBox(height: 2),
          Text(
            "Profile",
              style: AppFontStyle.text_12_400(
                  fontFamily:isSelected? AppFontFamily.gilroySemiBold : AppFontFamily.gilroyMedium,
                  color:isSelected ? AppColors.textClr : AppColors.textLightClr)
          ),
        ],
      ),
    );
  }
}
