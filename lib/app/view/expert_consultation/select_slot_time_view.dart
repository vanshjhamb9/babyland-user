import 'dart:async';

import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/app/widgets/stale_sync_banner.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/core/sync/consultation_sync_service.dart';
import 'package:babyland/core/sync/polling_consultation_sync.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_controller.dart';

import '../../data/response/status.dart';
import '../../widgets/general_exception.dart'; // Assuming you have CustomNoDataFound too
import '../../widgets/custom_no_data_found.dart'; // Add if missing

/// UI-side view of a bookable slot, independent of the underlying endpoint.
/// Built from either the legacy `Datum` (status: bool) or the new `LiveSlot`
/// (status: AVAILABLE/HELD/BOOKED/PAST). The slot grid only needs the label
/// and a bookable flag.
class _SelectableSlot {
  const _SelectableSlot({required this.time, required this.bookable});
  final String time;
  final bool bookable;
}

class SelectSlotTimeView extends StatefulWidget {
  const SelectSlotTimeView({super.key});

  @override
  State<SelectSlotTimeView> createState() => _SelectSlotTimeViewState();
}

class _SelectSlotTimeViewState extends State<SelectSlotTimeView> {
  String? time;
  String? date;
  String? doctorId;

  StreamSubscription<ConsultationSyncReason>? _syncSub;
  PollingConsultationSyncService? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      date = args?['appointmentDate'];
      time = args?['appointmentTime'];
      doctorId = args?['doctorId'];
      final provider = context.read<ExpertConsultationProvider>();
      // Endpoint-agnostic dispatch: legacy `/available-slots` by default,
      // new `/doctors/:id/live-slots` when the build flag is on (§8).
      provider.getSlotsForDoctor(
        doctorId: doctorId ?? "",
        date: DateTime.parse(date.toString()),
      );
      _sync = context.read<PollingConsultationSyncService>();
      _sync!.startSlotPolling();
      _syncSub = _sync!.invalidations.listen((_) {
        if (!mounted || doctorId == null || date == null) return;
        provider.getSlotsForDoctor(
          doctorId: doctorId!,
          date: DateTime.parse(date.toString()),
        );
      });
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _sync?.stopSlotPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        height: mediaQueryH(context),
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Consumer<ExpertConsultationProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Consumer2<AppStateReconciliationCoordinator, SubscriptionProvider>(
                  builder: (context, coord, sub, _) {
                    final show = coord.isReconciling ||
                        sub.isEntitlementSnapshotStale;
                    if (!show) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const StaleSyncBanner(),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.getSlotsForDoctor(
                      doctorId: doctorId ?? "",
                      date: DateTime.parse(date.toString()),
                    ),
                    child: switch (_activeStatus(provider)) {
                      ApiStatus.LOADING => _buildShimmerLoading(),
                      ApiStatus.COMPLETED => _buildCompletedUI(provider),
                      ApiStatus.ERROR => GeneralExceptionWidget(
                        onPress: () => provider.getSlotsForDoctor(
                          doctorId: doctorId ?? "",
                          date: DateTime.parse(date.toString()),
                        ),
                      ),
                      _ => const SizedBox(),
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading UI
  Widget _buildShimmerLoading() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, index) => AppContainer(
        radius: 8,
        padding: const EdgeInsets.all(12),
        color: AppColors.white,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 20, width: 150, color: Colors.white),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 14, width: 80, color: Colors.white),
                  Container(height: 20, width: 20, color: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      height: 30,
                      width: 80,
                      color: Colors.white,
                    ),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }

  /// Status of the state slot that matches the active endpoint.
  ApiStatus? _activeStatus(ExpertConsultationProvider provider) {
    if (ExpertConsultationProvider.useLiveSlotsEndpoint) {
      return provider.liveSlots?.status;
    }
    return provider.getAvailableSlot?.status;
  }

  /// Endpoint-agnostic view of the slot list. Returns an empty list when
  /// the API is still loading or yielded no slots.
  List<_SelectableSlot> _activeSlots(ExpertConsultationProvider provider) {
    if (ExpertConsultationProvider.useLiveSlotsEndpoint) {
      final ls = provider.liveSlots?.data;
      if (ls == null) return const [];
      return ls.slots
          .map((s) => _SelectableSlot(time: s.time, bookable: s.isBookable))
          .toList(growable: false);
    }
    final model = provider.getAvailableSlot?.data;
    final rows = model?.data;
    if (rows == null) return const [];
    return rows
        .map((d) => _SelectableSlot(
              time: d.time ?? '',
              // Legacy `Datum.status` is a bool flag: `true` == available.
              bookable: d.status == true,
            ))
        .toList(growable: false);
  }

  // Handle completed state - check empty data
  Widget _buildCompletedUI(ExpertConsultationProvider provider) {
    final slots = _activeSlots(provider);
    if (slots.isEmpty) {
      return CustomNoDataFound(isClr: false);
    }
    return _buildSlotsList(provider, slots);
  }

  // Dynamic slots list — works for both `/available-slots` and `/live-slots`.
  Widget _buildSlotsList(
    ExpertConsultationProvider provider,
    List<_SelectableSlot> slots,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: 1,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            final isCardSelected = provider.slotIndex != -1;
            final isTimeSelected =
                isCardSelected && provider.selectedShiftIndex[provider.slotIndex] != -1;
            if (!isCardSelected || !isTimeSelected) {
              AppPopUp.showToast(
                  message: "Please select date & time slot", lineColor: AppColors.red);
              return;
            }

            final shiftIdx = provider.getShiftIndexForSlot(provider.slotIndex);
            final slotLabel = shiftIdx != null && shiftIdx < slots.length
                ? slots[shiftIdx].time
                : time?.toString() ?? '';

            if (doctorId == null ||
                doctorId!.isEmpty ||
                date == null ||
                shiftIdx == null) {
              AppPopUp.showToast(
                  message: "Missing slot selection", lineColor: AppColors.red);
              return;
            }

            final effectiveTime = slotLabel.isNotEmpty
                ? slotLabel
                : (time?.toString().isNotEmpty == true ? time!.toString() : '');
            if (effectiveTime.isEmpty) {
              AppPopUp.showToast(
                  message: "Please select date & time slot", lineColor: AppColors.red);
              return;
            }

            provider.setSelectedDoctorId(doctorId!);
            final checkout = context.read<ConsultationCheckoutController>();
            checkout.clearForNewFlow();

            final dateFmt = provider.formatDate(DateTime.parse(date!));
            final locked = await checkout.requestSlotLock(
              doctorId: doctorId!,
              slotDate: dateFmt,
              slotTime: effectiveTime,
            );
            if (!context.mounted) return;
            if (!locked.ok) {
              AppPopUp.showToast(
                message:
                    locked.message ?? "Unable to reserve this slot. Pick another time.",
                lineColor: AppColors.red,
              );
              return;
            }

            Navigator.pushNamed(context, AppRoutes.bookingsView, arguments: {
              'appointmentDate': date?.toString(),
              'appointmentTime': effectiveTime,
              'doctorId': doctorId?.toString(),
            });
          },
          child: AppContainer(
            radius: 8,
            padding: const EdgeInsets.all(12),
            color: AppColors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.formatDateMMMMddyyyy(DateTime.parse(date.toString())),
                  style: AppFontStyle.text_16_600(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.getDayName(DateTime.parse(date.toString())),
                      style: AppFontStyle.text_12_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textLightClr,
                      ),
                    ),
                    GradientCheckbox(
                      value: provider.slotIndex == index ? provider.isSelectedTimeSlot : false,
                      onChanged: (val) => provider.setIsSelectedTimeSlot(val, index),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: slots
                        .asMap()
                        .entries
                        // Both shapes filter the same way: bookable means
                        // AVAILABLE for /live-slots or status==true for legacy.
                        .where((entry) => entry.value.bookable)
                        .map((entry) {
                      final slotIndex = entry.key;
                      final slot = entry.value;
                      final isSelectedShift = provider.getShiftIndexForSlot(index) == slotIndex;
                      final isSlotSelected = provider.slotIndex == index && provider.isSelectedTimeSlot;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: InkWell(
                          highlightColor: AppColors.transparent,
                          splashColor: AppColors.transparent,
                          onTap: isSlotSelected ? () => provider.setShiftIndex(slotIndex, index) : null,
                          child: Opacity(
                            opacity: isSlotSelected ? 1.0 : 0.5,
                            child: AppContainer(
                              radius: 4,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              gradient: isSelectedShift && isSlotSelected
                                  ? AppColors.buttonClr
                                  : LinearGradient(
                                colors: [Colors.grey.shade100, Colors.grey.shade200],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              child: Text(
                                slot.time,
                                style: AppFontStyle.text_12_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: isSelectedShift && isSlotSelected ? AppColors.white : AppColors.textLightClr,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      title: Text(
        "Select Time Slot",
        style: AppFontStyle.text_18_600(
          color: AppColors.textClr,
          fontFamily: AppFontFamily.gilroyMedium,
        ),
      ),
    );
  }
}
