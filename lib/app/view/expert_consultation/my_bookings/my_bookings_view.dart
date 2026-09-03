import 'dart:async';

import 'package:babyland/app/constants/images.dart';
import 'package:babyland/features/patient_consultation/consultation_booking_detail_view.dart';
import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/app/widgets/stale_sync_banner.dart';
import 'package:babyland/core/consultation/booking_lifecycle.dart';
import 'package:babyland/core/consultation/consultation_join_guard.dart';
import 'package:babyland/features/patient_consultation/widgets/consultation_countdown_row.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/core/sync/consultation_sync_service.dart';
import 'package:babyland/core/sync/polling_consultation_sync.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controller/experts_consultation/experts_consultation_controller.dart';
import '../../../controller/experts_consultation/model/booking_data_model.dart';
import '../../../data/response/status.dart';

class MyBookingsView extends StatefulWidget {
  const MyBookingsView({super.key});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  StreamSubscription<ConsultationSyncReason>? _syncSub;
  PollingConsultationSyncService? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = context.read<BookingController>();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['forceRefresh'] == true) {
        unawaited(booking.getBookingApi());
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (mounted) unawaited(booking.getBookingApi());
        });
      } else {
        booking.getBookingApi();
      }
      _sync = context.read<PollingConsultationSyncService>();
      _sync!.startBookingPolling();
      _syncSub = _sync!.invalidations.listen((_) {
        if (!mounted) return;
        booking.getBookingApi();
      });
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _sync?.stopBookingPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingController>();
    final apiData = provider.bookingApiData;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundClr,
        appBar: CustomAppBar(
          leadingOnTap: () => Navigator.pop(context),
          isIosBackBtn: true,
          title: Text(
            "My Bookings",
            style: AppFontStyle.text_18_600(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textClr,
            ),
          ),
        ),
        body: AppContainer(
          gradient: AppColors.backGroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer2<
                AppStateReconciliationCoordinator,
                SubscriptionProvider
              >(
                builder: (context, coord, sub, _) {
                  final show =
                      coord.isReconciling || sub.isEntitlementSnapshotStale;
                  if (!show) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const StaleSyncBanner(),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
              // Tabs
              AppContainer(
                gradient: AppColors.backGroundColor,
                radius: 12,
                color: AppColors.lightWhite,
                child: Row(
                  children: List.generate(3, (index) {
                    final titles = ["Upcoming", "Past", "Cancelled"];
                    final isSelected = provider.selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setSelectedTab(index),
                        child: AppContainer(
                          gradient: AppColors.backGroundColor,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          radius: 12,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.lightWhite,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: Center(
                            child: Text(
                              titles[index],
                              style: AppFontStyle.text_16_600(
                                fontFamily: isSelected
                                    ? AppFontFamily.gilroyMedium
                                    : AppFontFamily.gilroyRegular,
                                color: AppColors.textClr,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: switch (provider.bookingApiData?.status) {
                  ApiStatus.LOADING => Center(child: _buildShimmerList()),

                  ApiStatus.COMPLETED => _buildBookingsList(
                    apiData?.data?.bookings ?? [],
                    provider.selectedTabIndex,
                  ),

                  ApiStatus.ERROR => Center(
                    child: Text(
                      provider.bookingApiData?.message ??
                          "Something went wrong",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                  _ => const SizedBox(), // null / default
                },
              ),
            ],
          ),
        ),
      ), // closes WillPopScope child: Scaffold
    ); // closes WillPopScope
  }

  Widget _buildBookingsList(List<Booking> bookings, int selectedTabIndex) {
    if (bookings.isEmpty) {
      return const CustomNoDataFound(isClr: false);
    }

    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final phase = bookingLifecycleFromBooking(booking);
        return Card(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AppContainer(
            gradient: AppColors.backGroundColor,
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order ID: ${booking.sId ?? 'N/A'}",
                  style: AppFontStyle.text_16_600(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Order Date: ${_formatDateTime(booking.date)} - ${booking.time ?? ''}",
                  style: AppFontStyle.text_12_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bookingLifecycleLabel(phase),
                  style: AppFontStyle.text_13_600(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ConsultationCountdownRow(booking: booking),
                const SizedBox(height: 10),

                // Doctor Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomImage(
                      path: ImageConstants.networkImageDemo,
                      h: 64,
                      w: 64,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                booking.doctorId?.name?.capitalizeFirst() ?? "",
                                style: AppFontStyle.text_16_600(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.textClr,
                                ),
                              ),
                              const Spacer(),
                              if (phase == BookingLifecyclePhase.readyToJoin)
                                TextButton(
                                  onPressed: () =>
                                      ConsultationJoinGuard.maybeOpenVideo(
                                        context: context,
                                        booking: booking,
                                      ),
                                  child: Text(
                                    'Join',
                                    style: AppFontStyle.text_14_600(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.doctorId?.specialization
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? booking.doctorId!.specialization!
                                : 'Specialty',
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                              color: AppColors.textClr,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "1.0 km away",
                                style: AppFontStyle.text_13_400(
                                  fontFamily: AppFontFamily.gilroyRegular,
                                  color: AppColors.textClr,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.star,
                                color: AppColors.orangeClr,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "4.8",
                                style: AppFontStyle.text_13_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.textClr,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (phase == BookingLifecyclePhase.readyToJoin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      borderRadius: 12,
                      height: 46,
                      onTap: () => ConsultationJoinGuard.maybeOpenVideo(
                        context: context,
                        booking: booking,
                      ),
                      child: Center(
                        child: Text(
                          'Join consultation',
                          style: AppFontStyle.text_16_500(
                            fontFamily: AppFontFamily.gilroySemiBold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Button Row Logic based on Tab
                Row(
                  children: [
                    // LEFT BUTTON
                    if (selectedTabIndex == 0) ...[
                      // Upcoming: CANCEL
                      Expanded(
                        child: AppContainer(
                          onTap: () async {
                            await context
                                .read<ExpertConsultationProvider>()
                                .cancelBookingApi(id: booking.sId ?? "");
                            if (context.mounted) {
                              context.read<BookingController>().getBookingApi();
                            }
                          },
                          radius: 12,
                          color: AppColors.greyLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child:
                                context
                                            .watch<ExpertConsultationProvider>()
                                            .cancelBooking
                                            ?.status ==
                                        ApiStatus.LOADING &&
                                    context
                                            .read<ExpertConsultationProvider>()
                                            .selectedBookingId ==
                                        booking.sId
                                ? customLoading(color: AppColors.primary)
                                : Text(
                                    "Cancel",
                                    style: AppFontStyle.text_16_500(
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                      color: AppColors.textClr,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Past/Cancelled: Write Review (Only for Past) OR just placeholder
                      // For Cancelled, maybe we don't show "Write Review".
                      // Let's hide it for Cancelled, show for Past.
                      if (selectedTabIndex == 1) ...[
                        // Past
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.recordsView,
                                arguments: {'doctorId': booking.doctorId ?? ""},
                              );
                            },
                            child: AppContainer(
                              radius: 12,
                              color: AppColors.greyLight,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  "Write a Review",
                                  style: AppFontStyle.text_16_500(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                    color: AppColors.textClr,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Cancelled (Tab 2) -> Maybe nothing? Or empty expanded to keep alignment?
                        // Or just show View Details full width on right?
                        // Let's just put an empty container or "Book Again"
                        const Spacer(), // Placeholder for left side
                      ],
                    ],

                    const SizedBox(width: 12),

                    // RIGHT BUTTON
                    Expanded(
                      child: Button(
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                        height: 44,
                        onTap: () {
                          if (selectedTabIndex == 0) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ConsultationBookingDetailView(
                                  booking: booking,
                                ),
                              ),
                            );
                            return;
                          }
                          final doctorIdStr = booking.doctorId?.id ?? "";
                          if (doctorIdStr.isEmpty) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.doctorProfileView,
                            arguments: {'doctorId': doctorIdStr},
                          );
                        },
                        child: Center(
                          child: Text(
                            selectedTabIndex == 0
                                ? 'View details'
                                : 'Book again',
                            style: AppFontStyle.text_16_500(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              // Add layout placeholders similar to your real UI
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "-";
    return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
  }
}
