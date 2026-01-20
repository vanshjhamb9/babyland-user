import 'dart:io';

import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/baby_growth/baby_growth_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/common_select_date_textfield.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddMildStones extends StatelessWidget {
  AddMildStones({super.key});

  final dateController = TextEditingController();
  final nameController = TextEditingController();
  final notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BabyGrowthProvider>(
      create: (context) => BabyGrowthProvider(),
      builder: (context, child) =>  Scaffold(
        appBar: CustomAppBar(
          centerTitle: true,
          title: Text(
            "Add New milestones",
            style: AppFontStyle.text_20_400(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: AppColors.textClr,
            ),
          ),
        ),
        body: AppContainer(
          gradient: AppColors.backGroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Consumer<BabyGrowthProvider>(
              builder: (context, provider, _){
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textFieldTitle(title: "Milestone Title"),
                    SizedBox(height: 4),
                    CustomTextFormField(
                      controller: nameController,
                      hintText: "e.g. First smile, first step etc.",
                      borderColor: AppColors.borderColor,
                    ),
                    SizedBox(height: 16),
                    textFieldTitle(title: "Date"),
                    SizedBox(height: 4),
                    buildCustomTextFormFieldSelectDate(controller: dateController),
                    SizedBox(height: 16),
                    textFieldTitle(title: "Add Notes"),
                    SizedBox(height: 4),
                    CustomTextFormField(
                      controller: notesController,
                      hintText: "Describe this special moment...",
                      minLines: 4,
                      maxLines: 4,
                      borderColor: AppColors.borderColor,
                    ),
                    SizedBox(height: 16),

                    if(provider.pickedPhoto.isNotEmpty)...[
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomImage(path: provider.pickedPhoto,h: 100,w: 100,
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
                      )
                    ]
                    else...[
                    Center(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              return SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Text(
                                          "Pick Image",
                                          style: AppFontStyle.text_22_600(),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 50.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // 📸 Camera
                                            GestureDetector(
                                              onTap: () async {
                                                Navigator.pop(context);
                                                provider.pickImage(imageSource: ImageSource.camera);
                                              },
                                              child: Column(
                                                children: [
                                                  Text("📸" ,style: AppFontStyle.text_40_600(
                                                  color: AppColors.textClr)),
                                                  const SizedBox(height: 8),
                                                  Text("Camera",
                                                      style: AppFontStyle.text_16_500(
                                                          color: AppColors.textClr))
                                                ],
                                              ),
                                            ),

                                            GestureDetector(
                                              onTap: () async {
                                                Navigator.pop(context);
                                                provider.pickImage(imageSource: ImageSource.gallery);
                                              },
                                              child: Column(
                                                children: [
                                                  CustomImage(path: ImageConstants.photos,h: 45,w: 45),
                                                  const SizedBox(height: 8),
                                                  Text("Gallery",
                                                      style: AppFontStyle.text_16_500(
                                                          color: AppColors.textClr))
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: AppContainer(
                          radius: 100,
                          padding: EdgeInsets.symmetric(horizontal: 9,vertical: 9),
                          color: AppColors.white,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppContainer(
                                  gradient: AppColors.buttonClr,
                                  radius: 100,
                                  child: Icon(Icons.add,color: AppColors.white),
                              ),
                              SizedBox(width: 10),
                              Text("Add Photo (optional)",
                                style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium,color:AppColors.textClr),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    ],
                  ],
                );
              }
            ),
          ),
        ),
        bottomNavigationBar: Consumer<BabyGrowthProvider>(
          builder: (context,provider,_) {
            return AppContainer(
              gradient: AppColors.backGroundColor,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Button(
                  onTap: ()async{
                    if(nameController.text.isEmpty){
                      AppPopUp.showToast(message: "Please enter title",lineColor: AppColors.red);
                    }else if(dateController.text.isEmpty){
                      AppPopUp.showToast(message: "Please select date",lineColor: AppColors.red);
                    }else if(notesController.text.isEmpty){
                      AppPopUp.showToast(message: "Please enter notes.",lineColor: AppColors.red);
                    }else if(provider.pickedPhoto.isEmpty){
                      AppPopUp.showToast(message: "Please select photo.",lineColor: AppColors.red);
                    } else {
                      provider.addMildStoneDetails(
                        fields: {
                          "title": nameController.text,
                          "date": formatDateForApi(dateController.text),
                          "note": notesController.text,
                        },
                        files: {
                          "photo": File(provider.pickedPhoto),
                        },
                      );
                    }
                    pt("formatDateForApi(dateController.text) ${formatDateForApi(dateController.text)}");
                    // AppPopUp.showToast(message: "New Milestone added!");
                    // Navigator.pushNamed(context, AppRoutes.addMildStones);
                  },
                  height: 56,
                  child:provider.addMildStoneApi?.status == ApiStatus.LOADING ? customLoading() : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add,color: AppColors.white),
                      SizedBox(width: 4),
                      Text("Add New milestones",style:AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white)),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
