import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/images.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_family.dart';
import '../../../theme/font_style.dart';
import '../../../widgets/container.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_image.dart';
import '../../../widgets/general_exception.dart';
import '../../../widgets/icon_text_row.dart';
import '../../../widgets/sub_custom_container.dart';
import '../pregnancy/pregnancy_sub_screen.dart';

class PostSubScreen extends StatefulWidget {

  const PostSubScreen({super.key});
  @override
  State<PostSubScreen> createState() => _PostSubScreenState();

}

class _PostSubScreenState extends State<PostSubScreen> {

  bool doneValue1 = true;
  bool doneValue2 = false;
  bool doneValue3 = false;
  bool imgValue1 = true;
  bool imgValue2 = false;
  bool imgValue3 = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<SubscriptionProvider>().getSubscriptionPlanApi();
    },);
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,isLeading: false,
        title: Text("Subscription Plans",
          style: AppFontStyle.text_20_400(
              color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            height: mediaQueryH(context),
            gradient: AppColors.backGroundColor,
            child: () {
              switch (provider.allSubscription?.status) {
                case ApiStatus.LOADING:
                  return subscriptionShimmer();
                case ApiStatus.COMPLETED:
                  return body(provider);
                case ApiStatus.ERROR:
                  return GeneralExceptionWidget(onPress: () => provider.getSubscriptionPlanApi(),);
                default:
                  return SizedBox.shrink();
              }
            }(),
          );
        },
      ),
      bottomNavigationBar: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16,0,16,10),
          child: Consumer<SubscriptionProvider>(
              builder: (context,provider,_) {
                return Button(
                  onTap: () {
                    if( provider.planName.toLowerCase() != "basic" && provider.selectedPlanIndex != 0){
                      if(provider.addSubscription?.status != ApiStatus.LOADING) {
                        provider.addSubscriptionPlanApi();
                      }
                    }
                  },
                  height: 50,borderRadius: 8,
                  textStyle: AppFontStyle.text_16_600(
                      color: AppColors.white,fontFamily: AppFontFamily.gilroyBold),
                  child:provider.addSubscription?.status == ApiStatus.LOADING ? customLoading() : Text(
                    provider.planName.toLowerCase() == "basic" || provider.selectedPlanIndex == 0? "Your Current Plan" :
                    "Get Full Access",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),),
                );
              }
          ),
        ),
      ),
    );
  }

  SingleChildScrollView body(SubscriptionProvider provider) {
    return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppContainer(
                    height: 122,
                    width: 118,
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: CustomImage(path:ImageConstants.dimands),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  AppContainer(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      children: [
                        Text("Unlock Premium Features",
                          style: AppFontStyle.text_20_400(
                              color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
                        ),
                        Text("Get unlimited access to all features",
                          style: AppFontStyle.text_13_400(
                              color: AppColors.textClr,fontFamily: AppFontFamily.gilroyLight),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 14,
                  ),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Post Pregnancy (0-12 months)',
                        style:  AppFontStyle.text_20_400(
                            color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),
                        // children: [
                        //   TextSpan(
                        //     text: '(Fertility & Hormonal Balance)',
                        //     style: AppFontStyle.text_20_400(
                        //         color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),
                        //   ),
                        // ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 23,
                  ),
                  ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final plans =provider.allSubscription?.data?.plans?[index];
                        return InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: (){
                              setState(() {
                                provider.selectedPlanID = plans?.sId ?? "";
                                provider.selectedPlanIndex = index;
                              });
                              provider.setPLanName(plans?.name ?? "");

                            },
                            child: SubCustomContainer(title:plans?.name ?? "", price: "₹${plans?.price ?? "0"}/month",borderValue:   provider.selectedPlanIndex == index));
                      },
                      separatorBuilder: (context, index) => SBox(h: 15),
                      itemCount: provider.allSubscription?.data?.plans?.length ?? 0),
                  SizedBox(
                    height: 16,
                  ),

                  AppContainer(
                    margin: EdgeInsets.symmetric(horizontal: 14),
                    padding: EdgeInsets.symmetric(horizontal: 16,vertical: 14),
                    color: AppColors.white,
                    radius: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [


                        Text("Plan Features",style: AppFontStyle.text_18_400(
                            color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),),

                        SizedBox(
                          height: 12,
                        ),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: provider.allSubscription?.data?.plans?[provider.selectedPlanIndex].features?.length ?? 0,
                          itemBuilder: (context, index) {
                            final feature = provider.allSubscription?.data?.plans?[provider.selectedPlanIndex].features?[index];
                            final imgPath = provider.allSubscription?.data?.plans?[provider.selectedPlanIndex].isActive == true ? ImageConstants.done2 : ImageConstants.cancel;

                            return IconTextRow(
                              label: feature?.name ?? "",
                              imagePath: imgPath,
                            );
                          },
                          separatorBuilder: (context, index) => SizedBox(height: 8), // spacing between rows
                        ),
                        // IconTextRow(label: "Personalized Diet Plan",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),
                        //
                        // IconTextRow(label: "Yoga Classes Access",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),
                        //
                        // IconTextRow(label: "Doctor Consult(Gynenologist)",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),
                        //
                        // IconTextRow(label: "Therapy/Mindfulness sessions",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),
                        //
                        // IconTextRow(label: "Supplement & Lifestyle guide",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),
                        //
                        // IconTextRow(label: "Fertility expert support",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),
                        //
                        // IconTextRow(label: "Lab/test integration",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                ],
              ),
            );
  }
}
