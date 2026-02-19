import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/records/records_controller.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/response/status.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_family.dart';
import '../../../theme/font_style.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/validation.dart';

class RecordsView extends StatelessWidget {
  const RecordsView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final String? doctorId = args?['doctorId'];

    return ChangeNotifierProvider(
      create: (context) => RecordsProvider(),
      builder:(context, child) =>  Scaffold(
        appBar: CustomAppBar(
          isIosBackBtn: true,
          title: Text(
            "My Bookings",
            style: AppFontStyle.text_18_600(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textClr),
          ),
        ),
        body: Consumer<RecordsProvider>(
          builder: (context,provider,_) {
            return AppContainer(
              padding: EdgeInsets.symmetric(horizontal: 20),
              gradient: AppColors.backGroundColor,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppContainer(
                      isBordered: true,
                      borderColor: AppColors.buttonClr1.withAlpha(70),
                      radius: 16,
                      width: mediaQueryW(context),
                      color: AppColors.white,
                      /*child:provider.pickedPhoto.isNotEmpty ?
                      Stack(
                        // fit: StackFit.passthrough,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                            child: CustomImage(path: provider.pickedPhoto,
                              h: 390,
                              w: mediaQueryW(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child:InkWell(
                              onTap: () {
                                provider.clearPickedImage();
                              },
                              child: AppContainer(
                                radius: 100,
                                color: AppColors.lightPurple,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(Icons.clear,color: AppColors.black,size: 18),
                                ),
                              ),
                            )
                          ),
                        ],
                      )
                      :*/
                     child:  Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 28.0,bottom: 18),
                            child: CustomImage(path: ImageConstants.uploadImage),
                          ),
                          Text("Upload Your Medical Records",
                            style: AppFontStyle.text_18_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.textClr),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text("Drag and drop files here or choose upload option",
                              maxLines: 3,
                              textAlign: TextAlign.center,
                              style: AppFontStyle.text_14_400(
                                  fontFamily: AppFontFamily.gilroyRegular,
                                  color: AppColors.textClr),
                            ),
                          ),
                          SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Button(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) {
                                    return SizedBox(
                                      height: 230,
                                      width: double.infinity,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                "Pick File",
                                                style: AppFontStyle.text_22_600(),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  // Camera
                                                  GestureDetector(
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      provider.pickImage(imageSource: ImageSource.camera);
                                                    },
                                                    child: Column(
                                                      children: [
                                                        Text("📸", style: AppFontStyle.text_40_600(color: AppColors.textClr)),
                                                        const SizedBox(height: 8),
                                                        Text("Camera", style: AppFontStyle.text_16_500(color: AppColors.textClr)),
                                                      ],
                                                    ),
                                                  ),
                                                  // Gallery
                                                  GestureDetector(
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      provider.pickImage(imageSource: ImageSource.gallery);
                                                    },
                                                    child: Column(
                                                      children: [
                                                        CustomImage(path: ImageConstants.photos, h: 45, w: 45),
                                                        const SizedBox(height: 8),
                                                        Text("Gallery", style: AppFontStyle.text_16_500(color: AppColors.textClr)),
                                                      ],
                                                    ),
                                                  ),
                                                  // Files (PDF, DOC, images)
                                                  GestureDetector(
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      provider.pickFromGoogleDrive(); // supports PDF/doc/images
                                                    },
                                                    child: Column(
                                                      children: [
                                                        Text("📄", style: AppFontStyle.text_40_600(color: AppColors.textClr)),
                                                        const SizedBox(height: 8),
                                                        Text("Files", style: AppFontStyle.text_16_500(color: AppColors.textClr)),
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
                              borderRadius:12,
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomImage(path: ImageConstants.device),
                                  SizedBox(width: 10),
                                  Text(
                                    "Upload from Phone",
                                    maxLines: 3,
                                    textAlign: TextAlign.center,
                                    style: AppFontStyle.text_16_400(
                                        fontFamily: AppFontFamily.gilroyMedium,
                                        color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Button(
                              onTap: () {
                                provider.pickFromGoogleDrive();
                              },
                              border: Border.all(color: AppColors.borderColor),
                              borderRadius:12,
                              color: AppColors.white,
                              child:Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomImage(path: ImageConstants.drive),
                                  SizedBox(width: 10),
                                  Text(
                                    "Upload from Google Drive",
                                    maxLines: 3,
                                    textAlign: TextAlign.center,
                                    style: AppFontStyle.text_16_400(
                                        fontFamily: AppFontFamily.gilroyMedium,
                                        color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                    SizedBox(height: 22),
                    AppContainer(
                      radius: 12,
                      isBordered: true,
                      borderColor: AppColors.green.withAlpha(80),
                      color: AppColors.lightGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomImage(path: ImageConstants.secure),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Secure & Private",
                                  style: AppFontStyle.text_16_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.green,
                                  ),
                                ),
                                Text("Your files are securely stored & only shared with your doctor.",
                                  maxLines: 10,
                                  style: AppFontStyle.text_12_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Uploaded Files (${provider.files.length})",
                      style: AppFontStyle.text_16_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textClr,
                      ),
                    ),
                    SizedBox(height: 10),


                     ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.files.length,
                      itemBuilder: (context, index) {
                        final file = provider.files[index];
                        final ext = file.extension?.toLowerCase();

                        final isPdf = ext == 'pdf';
                        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);

                        return AppContainer(
                          radius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          color: AppColors.white,
                          child: Row(
                            children: [
                              AppContainer(
                                radius: 12,
                                color: isPdf
                                    ? AppColors.red.withAlpha(40)
                                    : AppColors.lightBlue,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CustomImage(
                                    path: isPdf
                                        ? ImageConstants.pdf
                                        : ImageConstants.image,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFontStyle.text_14_400(
                                        fontFamily: AppFontFamily.gilroyMedium,
                                        color: AppColors.textClr,
                                      ),
                                    ),
                                    Text(
                                      "${(file.size / 1024).toStringAsFixed(1)} KB",
                                      style: AppFontStyle.text_12_400(
                                        fontFamily: AppFontFamily.gilroyMedium,
                                        color: AppColors.textLightClr,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => provider.removeFileAt(index),
                                child: CustomImage(path: ImageConstants.delete),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                    ),


                ],
                ),
              ),
            );
          }
        ),
        bottomNavigationBar: Consumer<RecordsProvider>(
        builder: (context, provider, _) {
          provider.setDoctorId(doctorId);
          return AppContainer(
          gradient: AppColors.backGroundColor,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Button(
              borderRadius: 12,
              onTap: (){

                  provider.consultationApi(); // API call method

              },
              height: 56,
              child:provider.ConsultationApiData?.status == ApiStatus.LOADING
                  ? customLoading() : Text("Continue to Consultation",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),
              ),
            ),
          ),
        );}
      ),)
    );
  }
}
