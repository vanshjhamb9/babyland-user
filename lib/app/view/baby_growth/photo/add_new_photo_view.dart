import 'dart:io';
import 'package:babyland/app/controller/photo/photo_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/common_select_date_textfield.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/app_popup.dart';

class AddNewPhotoView extends StatelessWidget {
  AddNewPhotoView({super.key});

  final dateController = TextEditingController();
  final captionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text("Add New Photo", style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold),
        ),
      ),
      body: Consumer<PhotoProvider>(
        builder: (context,provider,_) {
          return AppContainer(
            padding: EdgeInsets.symmetric(horizontal: 14),
            gradient: AppColors.backGroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(provider.pickedPhoto.isNotEmpty)...[
                SizedBox(height: 16),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomImage(path: provider.pickedPhoto,h: 80,w: 80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    Positioned(
                      right: -22,
                      top: -19,
                      child: IconButton(onPressed: (){
                        provider.clearPickedImage();
                      }, icon: Icon(Icons.cancel,color: AppColors.black)),
                    ),
                  ],
                ),
                ],
                SizedBox(height: 16),
                textFieldTitle(title: "Date"),
                SizedBox(height: 4),
                buildCustomTextFormFieldSelectDate(controller: dateController),
                SizedBox(height: 16),
                textFieldTitle(title: "Add Caption"),
                SizedBox(height: 4),
                CustomTextFormField(
                  controller:captionController,
                  hintText: "Describe this special moment...",
                  minLines: 4,
                  maxLines: 4,
                  borderColor: AppColors.borderColor,
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        }
      ),
      bottomNavigationBar: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Consumer<PhotoProvider>(
          builder: (context,provider,_) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Button(
                onTap: (){
                  if(dateController.text.isEmpty){
                    AppPopUp.showToast(message: "Please select date",lineColor: AppColors.red);
                  }else if(captionController.text.isEmpty){
                    AppPopUp.showToast(message: "Please select caption",lineColor: AppColors.red);
                  }else if(provider.pickedPhoto.isEmpty){
                    AppPopUp.showToast(message: "Please pick photos");
                  }else{
                    provider.addBabyPhotosApi(fields: {
                      "caption": captionController.text,
                      "date": formatDateForApi(dateController.text),
                    },
                      files: {
                        "photo": File(provider.pickedPhoto),
                      },
                    );
                  }
                },
                height: 56,
                child:provider.addBabyPhotos?.status == ApiStatus.LOADING ? customLoading() : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,color: AppColors.white),
                    SizedBox(width: 4),
                    Text("Add",style:AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white)),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
