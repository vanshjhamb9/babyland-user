import 'package:babyland/app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:babyland/app/routes/app_routes.dart';
class CycleCalendarView extends StatefulWidget {
  const CycleCalendarView({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  State<CycleCalendarView> createState() => _CycleCalendarViewState();
}

class _CycleCalendarViewState extends State<CycleCalendarView> with RouteAware {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      CycleCalendarView.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    CycleCalendarView.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    final p = context.read<CycleCalenderProvider>();
    p.cycleCalender(year: p.focusedDay.year, month: p.focusedDay.month);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<CycleCalenderProvider>().cycleCalender(
        year: now.year,
        month: now.month,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isNavbarTab: true,
        centerTitle: true,
        title: Text(
          "Cycle Calendar",
          style: AppFontStyle.text_20_400(
              fontFamily: AppFontFamily.gilroySemiBold),
        ),
      ),
      body: Consumer<CycleCalenderProvider>(
        builder: (context, provider, _) {

          if(provider.calendarApi?.status == ApiStatus.LOADING){
            return AppContainer(
                gradient: AppColors.backGroundColor,
                child: buildCalendarShimmer(showDetails: true));
          }

          return RefreshIndicator(
            onRefresh: () {
              return provider.cycleCalender(
                year: provider.focusedDay.year,
                month: provider.focusedDay.month,
              );
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  calendar(context, provider),
                  SizedBox(height: 20),

                  _legend(),

                  SizedBox(height: 20),

                  AppContainer(
                    margin: EdgeInsets.symmetric(horizontal: 14),
                    color: AppColors.white,
                    // height: 50,
                    radius: 8,
                    isBordered: true,
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            // Use the same month-scoped lists as the calendar grid
                            // (not API nextPeriod/nextOvulation, which stay on "next" cycle).
                            final predictedRange =
                                provider.monthSummaryPredictedPeriodRange;
                            final fertileRange =
                                provider.monthSummaryFertileWindowRange;
                            final ovulationDay =
                                provider.monthSummaryOvulationDay;

                            return Column(
                              children: [
                                if (predictedRange != null &&
                                    predictedRange.isNotEmpty)
                                  buildRow(
                                    title: "Next Period:",
                                    date: predictedRange,
                                  ),
                                if (fertileRange != null &&
                                    fertileRange.isNotEmpty)
                                  buildRow(
                                    title: "Fertile window:",
                                    date: fertileRange,
                                  ),
                                if (ovulationDay != null &&
                                    ovulationDay.isNotEmpty)
                                  buildRow(
                                    title: "Ovulation day:",
                                    date: ovulationDay,
                                  ),
                                SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: AppContainer(
        margin: EdgeInsets.only(bottom: 14.0),
        child: InkWell(
          onTap: () {
            showAddPeriodLogDialog(context, context.read<CycleCalenderProvider>());
          },
          child: AppContainer(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            radius: 100,
            gradient: AppColors.buttonClr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: AppColors.white),
                SizedBox(width: 2),
                Text(
                  "Add Period Log",
                  style: AppFontStyle.text_16_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // ADD MANUAL PERIOD LOG DIALOG
  // ---------------------------------------------------------
  void showAddPeriodLogDialog(BuildContext context, CycleCalenderProvider provider) {
    DateTime? startDate;
    DateTime? endDate;

    // Constraints: previous months and current month, up to today
    final DateTime now = DateTime.now();
    // Allow going back for example 12 months, but restrict to current month max
    final DateTime firstDate = DateTime(now.year - 1, now.month, now.day); 
    final DateTime lastDate = now;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Add Period Log",
                style: AppFontStyle.text_20_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select the actual start and end dates of your period.",
                    style: AppFontStyle.text_14_400(color: AppColors.textLightClr),
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Start Date", style: AppFontStyle.text_16_400()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : "Select",
                          style: AppFontStyle.text_14_400(
                             color: startDate != null ? AppColors.black : AppColors.textLightClr,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_month, color: AppColors.buttonClr2),
                      ],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? now,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.buttonClr2,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          // Reset end date if it's before new start date
                          if (endDate != null && endDate!.isBefore(startDate!)) {
                            endDate = null;
                          }
                        });
                      }
                    },
                  ),
                  
                  // End Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("End Date", style: AppFontStyle.text_16_400()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : "Select",
                          style: AppFontStyle.text_14_400(
                             color: endDate != null ? AppColors.black : AppColors.textLightClr,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_month, color: AppColors.buttonClr2),
                      ],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? (startDate ?? now),
                        firstDate: startDate ?? firstDate, // End date cannot physically be before start date
                        lastDate: lastDate,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.buttonClr2,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: AppFontStyle.text_14_600(color: AppColors.textLightClr)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonClr2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (startDate == null || endDate == null)
                      ? null
                      : () {
                          Navigator.pop(context);
                          // Call controller
                          provider.addMenstrualCycle(
                            startDate: startDate!,
                            endDate: endDate!,
                          );
                        },
                  child: Text("Add", style: AppFontStyle.text_14_600(color: AppColors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------
  // CALENDAR
  // ---------------------------------------------------------
  Widget calendar(BuildContext context, CycleCalenderProvider provider) {
    return AppContainer(
      color: AppColors.white,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      radius: 8,
      child: Column(
        children: [
          // ⬆ HEADER — Month + Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.formattedMonthYear,
                  style: AppFontStyle.text_20_400(
                    color: AppColors.black,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: provider.previousMonth,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_ios,
                            size: 18, color: AppColors.lightGrey),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: provider.nextMonth,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 📅 TABLE CALENDAR
          TableCalendar(
            key: ValueKey('${provider.focusedDay.year}-${provider.focusedDay.month}-${provider.predictedPeriod.length}-${provider.fertileWindow.length}'),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: provider.focusedDay,
            onPageChanged: provider.updateFocusedDay,
            onDaySelected: (selectedDay, focusedDay) {
              provider.onDaySelected(selectedDay, focusedDay);
            },
            selectedDayPredicate: (day) => provider.isSameDay(provider.selectedDay, day),
            headerVisible: false,
            daysOfWeekVisible: true,

            calendarStyle: CalendarStyle(
              cellMargin: EdgeInsets.zero,
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),

            // ✅ BACKGROUND CIRCLE YAHAN BANEGA
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final dotColor = provider.getDotColor(day);
                return _buildDayCellWithBackground(day, dotColor, isToday: false);
              },
              todayBuilder: (context, day, focusedDay) {
                final dotColor = provider.getDotColor(day);
                return _buildDayCellWithBackground(day, dotColor, isToday: true);
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDayCellWithBackground(DateTime day, Color? bgColor, {bool isToday = false}) {
    return Container(
      decoration: bgColor != null
          ? BoxDecoration(
        color: bgColor.withOpacity(0.5),  // Light background
        shape: BoxShape.circle,
      )
          : null,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppFontStyle.text_14_600(
                color: isToday ? Colors.white : AppColors.black,
                fontFamily: isToday ? AppFontFamily.gilroyMedium : AppFontFamily.gilroyRegular,
              ),
            ),
            // Chhota dot bhi rakh sakte ho center mein
            // if (bgColor != null)
            //   Container(
            //     margin: EdgeInsets.only(top: 2),
            //     height: 4,
            //     width: 4,
            //     decoration: BoxDecoration(
            //       color: bgColor,
            //       shape: BoxShape.circle,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem("Predicted", Colors.red),
        _legendItem("Fertile", Colors.green),
        _legendItem("Ovulation", Colors.yellow),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 6),
        Text(text,style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),),
      ],
    );
  }

  Widget buildRow({required String title, required String date}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFontStyle.text_14_400(
            color: AppColors.textLightClr,
            fontFamily: AppFontFamily.gilroyMedium,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            date,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFontStyle.text_14_400(
              color: AppColors.textClr,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ),
        ),
      ],
    ),
  );



  Widget buildCalendarShimmer({bool showDetails = true}) {
    return Column(
      children: [
        // 📅 CALENDAR SHIMMER
        Container(
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14)
          ),
          margin: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              // Header shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Week days shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    7,
                        (index) => Container(
                      width: 30,
                      height: 16,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Calendar grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) => Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Legend shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
                (index) => Row(
              children: [
                Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (showDetails) ...[
          const SizedBox(height: 20),

          // Details box shimmer
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Next Period row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fertile window row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Ovulation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showOptionsBottomSheet(BuildContext context, CycleCalenderProvider provider) {
    if (provider.selectedDay == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Selected Date: ${DateFormat('dd MMM yyyy').format(provider.selectedDay!)}",
                style: AppFontStyle.text_16_600(
                    color: AppColors.black, fontFamily: AppFontFamily.gilroySemiBold),
              ),
              const SizedBox(height: 20),
              _actionButton(
                context,
                'Log Symptoms',
                Icons.edit_note,
                    () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                      context,
                      AppRoutes.dailyLogs,
                      arguments: {
                        'prePregnancyFlow': true,
                        'date': provider.selectedDay,
                      }
                  );
                },
              ),
              const SizedBox(height: 10),
              _actionButton(
                context,
                "Period Start",
                Icons.water_drop,
                    () {
                  Navigator.pop(context);
                  provider.addMenstrualCycle(startDate: provider.selectedDay);
                },
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              _actionButton(
                context,
                "Period End",
                Icons.water_drop_outlined,
                    () {
                  Navigator.pop(context);
                  provider.addMenstrualCycle(endDate: provider.selectedDay);
                },
                color: Colors.redAccent.shade100,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton(BuildContext context, String text, IconData icon, VoidCallback onTap,
      {Color color = AppColors.buttonClr1}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              text,
              style: AppFontStyle.text_14_600(
                color: AppColors.black,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

}
//
// class CycleCalendarView extends StatefulWidget {
//   const CycleCalendarView({super.key});
//
//   @override
//   State<CycleCalendarView> createState() => _CycleCalendarViewState();
// }
//
// class _CycleCalendarViewState extends State<CycleCalendarView> {
//
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) => context.read<CycleCalenderProvider>().cycleCalender(year: 2025, month: 11),);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => CycleCalenderProvider(),
//       child: Scaffold(
//         appBar: CustomAppBar(
//           centerTitle: true,
//           title: Text(
//             "Cycle Calendar",
//             style: AppFontStyle.text_20_400(
//               fontFamily: AppFontFamily.gilroySemiBold,
//             ),
//           ),
//           backgroundClr: AppColors.transparent,
//         ),
//         body: SafeArea(
//           child: AppContainer(
//             height: mediaQueryH(context),
//             gradient: AppColors.backGroundColor,
//             child: Consumer<CycleCalenderProvider>(
//               builder: (context, provider, _) => RefreshIndicator(
//                 onRefresh: () {
//                   final now = DateTime.now();
//                   return provider.cycleCalender(year: now.year, month: now.month);
//                 },
//                 child: SingleChildScrollView(
//                   physics: AlwaysScrollableScrollPhysics(),
//                   child: Column(
//                     children: [
//                       calendar(provider),
//                       SizedBox(height: 16),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _legendItem(color: AppColors.darkBrown, label: "Predicted Period"),
//                             _legendItem(color: AppColors.green, label: "Fertile Window"),
//                             _legendItem(color: AppColors.yellow, label: "Ovulation"),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 30),
//                       AppContainer(
//                         margin: EdgeInsets.symmetric(horizontal: 14),
//                         color: AppColors.white,
//                         // height: 50,
//                         radius: 8,
//                         isBordered: true,
//                         child: Column(
//                           children: [
//                             SizedBox(height: 8),
//                             buildRow(title: "Next Period",date: "29 Aug"),
//                             buildRow(title: "Fertile window:",date: "29 Aug"),
//                             buildRow(title: "Ovulation day:",date: "29 Aug"),
//                             SizedBox(height: 8),
//                           ],
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildRow({required String title, required String date}) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: AppFontStyle.text_14_400(
//             color: AppColors.textLightClr,
//             fontFamily: AppFontFamily.gilroyMedium,
//           ),
//         ),
//         Text(
//           date,
//           style: AppFontStyle.text_14_400(
//             color: AppColors.textClr,
//             fontFamily: AppFontFamily.gilroyMedium,
//           ),
//         ),
//       ],
//     ),
//   );

//   Widget calendar(CycleCalenderProvider provider) {
//     return AppContainer(
//       color: AppColors.white,
//       margin: const EdgeInsets.symmetric(horizontal: 14),
//       radius: 8,
//       child: Column(
//         children: [
//           // ---------------------- HEADER ----------------------
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   provider.formattedMonthYear,
//                   style: AppFontStyle.text_20_400(
//                     color: AppColors.black,
//                     fontFamily: AppFontFamily.gilroyMedium,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     InkWell(
//                       onTap: provider.previousMonth,
//                       child: Padding(
//                         padding: EdgeInsets.all(4),
//                         child: Icon(Icons.arrow_back_ios,
//                             size: 18, color: AppColors.lightGrey),
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     InkWell(
//                       onTap: provider.nextMonth,
//                       child: const Padding(
//                         padding: EdgeInsets.all(4),
//                         child: Icon(Icons.arrow_forward_ios, size: 18),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           SizedBox(height: 8),
//
//           // ---------------------- CALENDAR ----------------------
//           TableCalendar(
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2030, 12, 31),
//             focusedDay: provider.focusedDay,
//             onPageChanged: provider.updateFocusedDay,
//             onDaySelected: null,
//             selectedDayPredicate: (day) => false,
//             headerVisible: false,
//             daysOfWeekVisible: true,
//
//             daysOfWeekStyle: DaysOfWeekStyle(
//               weekdayStyle: AppFontStyle.text_12_400(
//                 color: AppColors.textLightClr,
//                 fontFamily: AppFontFamily.gilroyMedium,
//               ),
//               weekendStyle: AppFontStyle.text_12_400(
//                 color: AppColors.textLightClr,
//                 fontFamily: AppFontFamily.gilroyMedium,
//               ),
//             ),
//
//             calendarStyle: CalendarStyle(
//               cellMargin: const EdgeInsets.all(0),
//               outsideDaysVisible: false,
//               todayDecoration:
//               const BoxDecoration(color: Colors.transparent),
//             ),
//
//             // ---------------------- DOT BUILDER FIXED ----------------------
//             calendarBuilders: CalendarBuilders(
//               defaultBuilder: (context, day, focusedDay) {
//                 final color = provider.getDotColor(day);
//                 return _buildDayCell(day, color);
//               },
//               todayBuilder: (context, day, focusedDay) {
//                 final color = provider.getDotColor(day);
//                 return _buildDayCell(day, color, isToday: true);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDayCell(DateTime day, Color? dotColor, {bool isToday = false}) {
//     return SizedBox(
//       height: 48,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             '${day.day}',
//             style: AppFontStyle.text_14_400(
//               color: isToday ? AppColors.primary : AppColors.black,
//               fontFamily: AppFontFamily.gilroyRegular,
//             ),
//           ),
//           const SizedBox(height: 4),
//           if (dotColor != null)
//             AppContainer(
//               height: 6,
//               width: 6,
//               radius: 100,
//               color: dotColor,
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _legendItem({required Color color, required String label}) {
//     return Row(
//       children: [
//         Container(
//           height: 8,
//           width: 8,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: AppFontStyle.text_12_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyRegular),
//         ),
//       ],
//     );
//   }
// }
