import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/photo/photo_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../widgets/button.dart';

class PhotoView extends StatefulWidget {
  const PhotoView({super.key});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  final List<String> images = [
    "https://img.freepik.com/free-photo/portrait-adorable-newborn-baby_23-2150763164.jpg?t=st=1760037819~exp=1760041419~hmac=440a352f580a1d3c34a2b3fb42cd8b54b2da347e32dcbd415cf307b224553863&w=740",
    "https://img.freepik.com/free-photo/dreamy-children-s-day-celebration_23-2151435983.jpg?t=st=1760037903~exp=1760041503~hmac=e51a2ba9282bc18de3c37271583fad4c8acce4d25cdfed1908dc090ac021e2d7&w=740",
    "https://img.freepik.com/free-photo/cute-little-boy-red-striped-hat-sits-floor_1304-4935.jpg?t=st=1760037932~exp=1760041532~hmac=98bbb2274338b99ec380579b96d6f725ba639d1ba0e474b8bb01119d18412789&w=740",
    "https://img.freepik.com/free-photo/portrait-adorable-newborn-baby_23-2150763164.jpg?t=st=1760037819~exp=1760041419~hmac=440a352f580a1d3c34a2b3fb42cd8b54b2da347e32dcbd415cf307b224553863&w=740",
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<PhotoProvider>().getBabyPhotosApis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text(
          "Photo Journal",
          style: AppFontStyle.text_20_400(
            fontFamily: AppFontFamily.gilroySemiBold,
          ),
        ),
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, provider, _) {
          final status = provider.babyPhotoDataGet?.status;
          return switch (status) {
            ApiStatus.LOADING => photoShimmer(),
            ApiStatus.ERROR => GeneralExceptionWidget(
              onPress: () => provider.getBabyPhotosApis(),
            ),
            ApiStatus.COMPLETED => body(provider),
            _ => const SizedBox.shrink(),
          };
        },
      ),
      bottomNavigationBar: Consumer<PhotoProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Button(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 📸 Camera
                                    GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        provider.pickImage(
                                          imageSource: ImageSource.camera,
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            "📸",
                                            style: AppFontStyle.text_40_600(
                                              color: AppColors.textClr,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Camera",
                                            style: AppFontStyle.text_16_500(
                                              color: AppColors.textClr,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        provider.pickImage(
                                          imageSource: ImageSource.gallery,
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          CustomImage(
                                            path: ImageConstants.photos,
                                            h: 45,
                                            w: 45,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Gallery",
                                            style: AppFontStyle.text_16_500(
                                              color: AppColors.textClr,
                                            ),
                                          ),
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
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: AppColors.white),
                    SizedBox(width: 4),
                    Text(
                      "Add New Photo",
                      style: AppFontStyle.text_16_400(
                        fontFamily: AppFontFamily.gilroyBold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget body(PhotoProvider provider) {
    return (provider.babyPhotoDataGet?.data?.photos?.isEmpty ?? true)
        ? CustomNoDataFound()
        : AppContainer(
            gradient: AppColors.backGroundColor,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: RefreshIndicator(
              onRefresh: () => provider.getBabyPhotosApis(),
              child: GridView.builder(
                itemCount: provider.babyPhotoDataGet?.data?.photos?.length ?? 0,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final allPhotos =
                      provider.babyPhotoDataGet?.data?.photos?[index];

                  return InkWell(
                    onTap: () {
                      buildShowDialog(context, index, provider);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomImage(
                          path: allPhotos?.photoUrl ?? "",
                          borderRadius: BorderRadius.circular(8),
                          fit: BoxFit.cover,
                        ),

                        // DATE TOP RIGHT
                        Positioned(
                          top: 6,
                          right: 6,
                          child: AppContainer(
                            radius: 8,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            color: AppColors.white,
                            child: Text(
                              formatDate(allPhotos?.date ?? ""),
                              style: AppFontStyle.text_11_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.textClr,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
  }

  Future<dynamic> buildShowDialog(
    BuildContext context,
    int index,
    PhotoProvider provider,
  ) {
    return showDialog(
      context: context,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: CustomImage(
                        path:
                            provider
                                .babyPhotoDataGet
                                ?.data
                                ?.photos?[index]
                                .photoUrl ??
                            "",
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(
                            provider
                                    .babyPhotoDataGet
                                    ?.data
                                    ?.photos?[index]
                                    .date ??
                                "",
                          ),
                          style: AppFontStyle.text_11_400(
                            fontFamily: AppFontFamily.gilroyMedium,
                            color: AppColors.textLightClr,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          provider
                                  .babyPhotoDataGet
                                  ?.data
                                  ?.photos?[index]
                                  .caption ??
                              "",
                          style: AppFontStyle.text_16_400(
                            fontFamily: AppFontFamily.gilroyMedium,
                            color: AppColors.textClr,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),
                ],
              ),
              Positioned(
                right: -10,
                top: -10,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.cancel, color: AppColors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget photoShimmer() {
    return AppContainer(
      gradient: AppColors.backGroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
