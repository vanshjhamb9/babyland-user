import 'package:flutter/material.dart';
import 'package:babyland/app/constants/images.dart';

import '../../../../main.dart';
import '../../../data/response/api_response.dart';
import '../../../widgets/app_popup.dart';
import '../../../widgets/print.dart';
import '../model/booking_data_model.dart';
import '../model/doctor_data_model.dart';

class BookingController extends ChangeNotifier {
  /// Selected filter button index (for doctor categories)
  int selectedBtn = 0;

  /// Selected tab index (0 = Upcoming, 1 = Past)
  int selectedTabIndex = 0;

  /// Button List (example data)
  final List<Map<String, dynamic>> btnList = [
    {
      "title": "All",
      "image": ImageConstants.razorpayLogo,
    },
    {
      "title": "Nearby",
      "image": ImageConstants.razorpayLogo,
    },
    {
      "title": "Top Rated",
      "image": ImageConstants.star,
    },
  ];

  /// Appointment Data (mock example)
  final List<Map<String, dynamic>> upcomingAppointments = [
    {
      "id": "58967895",
      "date": "Aug 25, 2025, 10:00 PM - 03:00 PM",
      "doctorName": "Dr. Rahul Mehta",
      "specialty": "Cardiologist",
      "distance": "1.0 km away",
      "rating": "4.8",
      "image": ImageConstants.networkImageDemo,
    },
    {
      "id": "58967896",
      "date": "Aug 20, 2025, 09:00 AM - 12:00 PM",
      "doctorName": "Dr. Aditi Sharma",
      "specialty": "Dermatologist",
      "distance": "2.3 km away",
      "rating": "4.9",
      "image": ImageConstants.networkImageDemo,
    },
  ];

  final List<Map<String, dynamic>> pastAppointments = [
    {
      "id": "58967875",
      "date": "Jul 14, 2025, 01:00 PM - 02:00 PM",
      "doctorName": "Dr. Neha Kapoor",
      "specialty": "Pediatrician",
      "distance": "3.1 km away",
      "rating": "4.7",
      "image": ImageConstants.networkImageDemo,
    },
  ];

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

  /// Returns list of appointments based on current tab
  List<Map<String, dynamic>> get currentAppointments {
    return selectedTabIndex == 0
        ? upcomingAppointments
        : pastAppointments;
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
            value.bookings = value.bookings?.where((b) => b.status?.toLowerCase() != "cancelled").toList();
          } else if (selectedTabIndex == 2) {
            // Tab 2: Show ONLY cancelled
            value.bookings = value.bookings?.where((b) => b.status?.toLowerCase() == "cancelled").toList();
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


}
