import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/slider_widget.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/images.dart';
import '../../controller/pregnancy_flow/pregnancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/button.dart';

class DailyLogs extends StatefulWidget {
  final String? flowType;
  const DailyLogs({super.key, this.flowType});

  @override
  State<DailyLogs> createState() => _DailyLogsState();
}

class _DailyLogsState extends State<DailyLogs> {


  bool? prePregnancyFlow;
  bool? pregnancyFlow;
  String? flowType;
  DateTime? selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    prePregnancyFlow = args?['prePregnancyFlow'];
    pregnancyFlow = args?['pregnancyFlow'];
    pregnancyFlow = args?['pregnancyFlow'];
    flowType = args?['flowType'] ?? "";
    selectedDate = args?['date'];
    pt("prePregnancyFlow $prePregnancyFlow");
    pt("pregnancyFlow $pregnancyFlow");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
         title: Text("Daily Logs",
           style: AppFontStyle.text_20_400(
               color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
         ),
      ),
      body: Consumer<CycleCalenderProvider>(
        builder: (context,provider,_) {
          return AppContainer(
            color: AppColors.backgroundClr,
            gradient: AppColors.backGroundColor,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 18),
                  AppContainer(
                    height: 60,
                    radius: 8,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    color: AppColors.white,
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,size: 28,color: AppColors.black.withValues(
                          alpha: 170
                        ),),
                        SizedBox(width: 16,),
                        AppContainer(
                          height: 25,
                          width: 271,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('EEEE').format(selectedDate ?? DateTime.now()).toString(),style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),),
                              VerticalDivider(
                                color: AppColors.greyStroke,
                                thickness: 1,
                                width: 19,
                                indent: 2,
                                endIndent: 2,
                              ),
                              Text(formatDateForDisplay(selectedDate ?? DateTime.now()),style: AppFontStyle.text_13_400(fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.lightGrey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 18,),
                  AppContainer(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        todayMoodCard(provider),
                        SizedBox(height: 18,),
                        AppContainer(
                          // height: 225,
                          radius: 8,
                            color: AppColors.white,
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("Symptoms (select all that apply)",
                                style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),

                              ),
                              SizedBox(height: 12,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  CheckBoxList(text: "Fatigue"),
                                  CheckBoxList(text: "Back Pain"),
                                ],
                              ),
                              SizedBox(height: 12,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  CheckBoxList(text: "Nausea"),
                                  CheckBoxList(text: "Heartburn"),
                                ],
                              ),
                              SizedBox(height: 12,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  CheckBoxList(text: "Cramps"),
                                  CheckBoxList(text: "Bloating"),
                                ],
                              ),
                              SizedBox(height: 12,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  CheckBoxList(text: "Headache"),
                                  CheckBoxList(text: "Mood Swings"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18,),
                        AppContainer(
                          // height: 128,
                          radius: 8,
                          color: AppColors.white,
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CustomImage(path: ImageConstants.stress,scale: 4,),
                                      SizedBox(width: 12,),
                                      Text("Stress Level",style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium),),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      Text("${provider.stressLevel.toStringAsFixed(0)}/5",style: AppFontStyle.text_13_400(fontFamily: AppFontFamily.gilroyRegular),),
                                    ],
                                  )
                                ],
                              ),
                              // SizedBox(height: 10,),
                              CustomSlider(
                                value: provider.stressLevel,
                                onChanged: (value) {
                                  setState(() {
                                    provider.stressLevel = value;
                                  });
                                },
                              ),
                              SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Low",style: AppFontStyle.text_11_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textLightClr),),
                                  Text("High",style: AppFontStyle.text_11_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textLightClr),),

                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 18,),
                        AppContainer(
                          // height: 128,
                          radius: 8,
                          color: AppColors.white,
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CustomImage(path: ImageConstants.anxiety,scale: 4,),
                                      SizedBox(width: 12,),
                                      Text("Anxiety Level",
                                        style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium),
                                      ),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      Text("${provider.anxietyLevel.toStringAsFixed(0)}/5",style: AppFontStyle.text_13_400(fontFamily: AppFontFamily.gilroyRegular),),
                                    ],
                                  )
                                ],
                              ),
                              CustomSlider(
                                value: provider.anxietyLevel,
                                onChanged: (value) {
                                  setState(() {
                                    provider.anxietyLevel = value;
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Low",style: AppFontStyle.text_11_400(fontFamily:
                                  AppFontFamily.gilroyRegular,color: AppColors.textLightClr),),
                                  Text("High",style: AppFontStyle.text_11_400(fontFamily:
                                  AppFontFamily.gilroyRegular,color: AppColors.textLightClr),),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 18,),
                        AppContainer(
                          height: 175,
                          radius: 8,
                          color: AppColors.white,
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Others (Notes or Journal)",
                                style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),

                              ),
                              SizedBox(height: 15,),
                              CustomTextFormField(
                                controller: provider.otherController,
                                borderColor: AppColors.transparent,
                                fillColor: AppColors.greyLight,
                                hintText: "Any thoughts or concerns?",
                              hintStyle:  AppFontStyle.text_11_400(fontFamily: AppFontFamily.gilroyRegular),
                            minLines: 6,maxLines: 6,height: 100,
                              borderRadius: BorderRadius.circular(12),
                              )

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30,)
                ],
              ),
            ),
          );
        }
      ),
      bottomNavigationBar: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Consumer<CycleCalenderProvider>(
            builder: (context, provider, _) {

              final postProvider = context.watch<PostpregnancyProvider>();
              final pregnancyController = context.watch<PregnancyController>();

              return Button(
                onTap: () {
                  if(provider.selectedMood?.isEmpty ?? false){
                    AppPopUp.showToast(message: "Please select your mood today",lineColor: AppColors.red);
                  }else if(provider.selectedSymptoms.isEmpty){
                    AppPopUp.showToast(message: "Please select symptoms..",lineColor: AppColors.red);
                  }else {
                  if (prePregnancyFlow == true) {

                    provider.addDailyLogsMentural(date: selectedDate);

                  }else if(pregnancyFlow == true){
                    pregnancyController.addDailyLogsApiPregnancy(
                        mood: provider.selectedMood ?? "",
                        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                        symptoms: provider.selectedSymptoms
                            .map((e) => e.toLowerCase()).toList(),
                        stressLevel: provider.stressLevel.toStringAsFixed(0),
                        notes:provider.otherController.text,
                        anxietyLevel: provider.anxietyLevel.toStringAsFixed(0)
                    );
                  } else {
                    postProvider.postpartumsLogsAddApi(
                      mood: provider.selectedMood ?? "",
                      date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                      symptoms: provider.selectedSymptoms
                          .map((e) => e.toLowerCase()).toList(),
                      stressLevel: provider.stressLevel.toStringAsFixed(0),
                      notes:provider.otherController.text,
                      anxietyLevel: provider.anxietyLevel.toStringAsFixed(0)
                    );
                  }}
                },

                height: 56,

                child: (
                    provider.menturalAddDailyLogs?.status == ApiStatus.LOADING ||
                    pregnancyController.addDailyLogsApiData?.status == ApiStatus.LOADING ||
                        postProvider.postpartumsLogsAdd?.status == ApiStatus.LOADING
                )
                    ? customLoading()
                    : Text(
                  "Save Log",
                  style: AppFontStyle.text_16_400(
                    fontFamily: AppFontFamily.gilroyBold,
                    color: AppColors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppContainer todayMoodCard(CycleCalenderProvider provider) {
    return AppContainer(
      height: 144,
      radius: 8,
      color: AppColors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("How’s your Mood today?",
            style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),

          ),
          SizedBox(height: 14,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              EmojiList(
                path: ImageConstants.great,
                text: "Great",
                isSelected: provider.selectedMood == "Great",
                onTap: () => provider.selectMood("Great"),
              ),
              EmojiList(
                path: ImageConstants.good,
                text: "Good",
                isSelected: provider.selectedMood == "Good",
                onTap: () => provider.selectMood("Good"),
              ),
              EmojiList(
                path: ImageConstants.okay,
                text: "Okay",
                isSelected: provider.selectedMood == "Okay",
                onTap: () => provider.selectMood("Okay"),
              ),
              EmojiList(
                path: ImageConstants.low,
                text: "Low",
                isSelected: provider.selectedMood == "Low",
                onTap: () => provider.selectMood("Low"),
              ),
              EmojiList(
                path: ImageConstants.sad,
                text: "Sad",
                isSelected: provider.selectedMood == "Sad",
                onTap: () => provider.selectMood("Sad"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}







class EmojiList extends StatelessWidget {
  final String path;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const EmojiList({
    super.key,
    required this.path,
    required this.text,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.buttonClr1 : AppColors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.buttonClr1 : AppColors.transparent,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(1),
            child: CustomImage(
              path: path,
              scale: 5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFontStyle.text_11_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color:
              isSelected ? AppColors.black : AppColors.textLightClr,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckBoxList extends StatelessWidget {
  final String text;

  const CheckBoxList({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CycleCalenderProvider>(context);
    final isChecked = provider.selectedSymptoms.contains(text);

    return Expanded(
      child: InkWell(
        onTap: () => provider.toggleSymptom(text),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: Checkbox(
                value: isChecked,
                activeColor: AppColors.black,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                onChanged: (_) => provider.toggleSymptom(text),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: AppFontStyle.text_13_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color:AppColors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
