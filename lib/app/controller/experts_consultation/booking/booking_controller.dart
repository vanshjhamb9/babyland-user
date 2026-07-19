import 'package:flutter/material.dart';

import '../../../../main.dart';
import '../../../data/response/api_response.dart';
import '../../../widgets/app_popup.dart';
import '../../../widgets/print.dart';
import '../model/booking_data_model.dart';

class BookingController extends ChangeNotifier {
  /// Selected filter button index (for doctor categories)
  int selectedBtn = 0;

  /// Selected tab index (0 = Upcoming, 1 = Past)
  int selectedTabIndex = 0;

  /// Sets selected category button index
  void setSelectedBtn(int index) {
    selectedBtn = index;
    notifyListeners();
  }

  /// Sets selected tab (Upcoming / Past / Cancelled)
  void setSelectedTab(int index) {
    selectedTabIndex = index;
    getBookingApi();
    notifyListeners();
  }

  /////////////// get booking data here /////////////

  ApiResponse<BookingDataModel>? _bookingApiData = ApiResponse.completed(null);
  ApiResponse<BookingDataModel>? get bookingApiData => _bookingApiData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setBookingApiData(ApiResponse<BookingDataModel> response) {
    _bookingApiData = response;
    notifyListeners();
  }

  Future<void> getBookingApi() async {
    setLoading(true);
    setBookingApiData(ApiResponse.loading());

    try {
      // Tab 0 (Upcoming) & Tab 2 (Cancelled) -> use upcoming endpoint
      // Tab 1 (Past) -> use past endpoint
      final bool usePastEndpoint = selectedTabIndex == 1;

      final value = await repository.getBookingApi(isPast: usePastEndpoint);

      if (value.success == true) {
        // Filter locally because "upcoming" endpoint returns mixed status
        if (!usePastEndpoint) {
          if (selectedTabIndex == 0) {
            // Tab 0: Show non-cancelled
            value.bookings = value.bookings
                ?.where((b) => b.status?.toLowerCase() != "cancelled")
                .toList();
          } else if (selectedTabIndex == 2) {
            // Tab 2: Show ONLY cancelled
            value.bookings = value.bookings
                ?.where((b) => b.status?.toLowerCase() == "cancelled")
                .toList();
          }
        }

        setBookingApiData(ApiResponse.completed(value));
        pt(name: "response", "${value.bookings}");
      } else {
        setBookingApiData(ApiResponse.error("failed"));
      }
    } catch (e, s) {
      pt("Error in booking api: $e\n$s");
      setBookingApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  /// Upcoming list for reconciliation (does not change [selectedTabIndex]).
  Future<List<Booking>> loadUpcomingBookingsRaw() async {
    try {
      final value = await repository.getBookingApi(isPast: false);
      if (value.success != true) return [];
      final list = value.bookings ?? [];
      return list
          .where((b) => b.status?.toLowerCase() != 'cancelled')
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Polls until a booking with matching `_id` appears (webhook → list lag).
  Future<bool> waitForUpcomingBookingById({
    required String? consultationOrBookingId,
    int attempts = 10,
    Duration delay = const Duration(milliseconds: 700),
  }) async {
    if (consultationOrBookingId == null ||
        consultationOrBookingId.isEmpty) {
      await getBookingApi();
      return false;
    }
    for (var i = 0; i < attempts; i++) {
      final rows = await loadUpcomingBookingsRaw();
      final hit = rows.any((b) => b.sId == consultationOrBookingId);
      if (hit) {
        await getBookingApi();
        return true;
      }
      await Future<void>.delayed(delay);
    }
    await getBookingApi();
    return false;
  }
}
