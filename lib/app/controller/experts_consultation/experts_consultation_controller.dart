import 'dart:async';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../main.dart';
import '../../data/response/api_response.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_popup.dart';
import '../../widgets/print.dart';
import 'model/availableslotdatamodel.dart';
import 'model/booking_add_model.dart';
import 'model/doctor_data_model.dart';

class ExpertConsultationProvider extends ChangeNotifier {
  final searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  String _searchQuery = '';

  // Store all doctors from API
  List<Doctor>? _allDoctors = [];

  // Store filtered doctors (by specialty/today)
  List<Doctor>? _filteredBySpecialty = [];

  // Combined filtered list (specialty + search)
  List<Doctor>? _combinedFilteredDoctors = [];

  List<Doctor>? get filteredDoctors => _combinedFilteredDoctors?.isNotEmpty == true
      ? _combinedFilteredDoctors
      : (_searchQuery.isEmpty && _filteredBySpecialty == null)
      ? _allDoctors
      : null;

  //--------------------------------------for api booking
  String selectedDoctorId = "";

  setSelectedDoctorId(String id) {
    selectedDoctorId = id;
    pt("doctor id >>>> $id");
    notifyListeners();
  }

  //--------------------------------------doctor profile view code
  DateTime? selectedDate;
  String? selectedTime;

  void pickDate(DateTime date) {
    pt(date.toString());
    selectedDate = date;
    notifyListeners();
  }

  void pickTime(String time) {
    selectedTime = time;
    notifyListeners();
  }

  List<String> timeSlots = [
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
  ];

  int _selectedIndex = -1;
  int get selectedIndex => _selectedIndex;

  setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  int _selectedTimeIndex = -1;
  int get selectedTimeIndex => _selectedTimeIndex;

  setSelectedTimeIndex(int index) {
    _selectedTimeIndex = index;
    notifyListeners();
  }

  DateTime today = DateTime.now();

  //--------------------------------------Select Time slot
  bool _isSelectedTimeSlot = false;
  bool get isSelectedTimeSlot => _isSelectedTimeSlot;
  int slotIndex = -1;

  setIsSelectedTimeSlot(bool val, int index) {
    slotIndex = index;
    _isSelectedTimeSlot = val;
    notifyListeners();
  }

  Map<int, int?> selectedShiftIndex = {};

  void setShiftIndex(int shiftIndex, int slotIndex) {
    selectedShiftIndex[slotIndex] = shiftIndex;
    notifyListeners();
  }

  int? getShiftIndexForSlot(int slotIndex) {
    return selectedShiftIndex[slotIndex];
  }

  int _selectedBtn = 0;
  int get selectedBtn => _selectedBtn;

  setSelectedBtn(int index) {
    _selectedBtn = index;
    // Clear search when filter changes
    searchController.clear();
    _searchQuery = '';

    // Apply specialty filter
    if (index == 1) { // Today filter
      _applyTodayFilter();
    } else {
      // Reset to all doctors
      _filteredBySpecialty = null;
      _combinedFilteredDoctors = null;
    }

    _applyCombinedFilters();
    notifyListeners();
  }

  List<Map<String, String>> btnList = [
    {"image": ImageConstants.allSpecalist, "title": "All Specialties"},
    {"image": ImageConstants.calenderClr, "title": "Today"},
    {"image": ImageConstants.english, "title": "English"},
  ];

  bool isRazorPaySelected = false;

  void toggleRazorPay() {
    isRazorPaySelected = !isRazorPaySelected;
    notifyListeners();
  }

  void selectRazorPayExclusive() {
    isRazorPaySelected = true;
    notifyListeners();
  }

  ApiResponse<DoctorDataModel>? _doctorApiData = ApiResponse.completed(null);
  ApiResponse<DoctorDataModel>? get doctorApiData => _doctorApiData;

  bool _isLoadingDoc = false;
  bool get isLoadingDoc => _isLoadingDoc;

  void setLoadingDoc(bool loading) {
    _isLoadingDoc = loading;
    notifyListeners();
  }

  /// Set API data and apply current search filter
  void setDoctorApiData(ApiResponse<DoctorDataModel> response) {
    _doctorApiData = response;

    // Store all doctors
    _allDoctors = _doctorApiData?.data?.data != null
        ? List.from(_doctorApiData!.data!.data!)
        : [];

    // Reset filters
    _filteredBySpecialty = null;
    _combinedFilteredDoctors = null;
    _searchQuery = '';

    // Apply current filter if any
    if (_selectedBtn == 1) {
      _applyTodayFilter();
    }

    _applyCombinedFilters();
    notifyListeners();
  }

  /// Apply today filter
  void _applyTodayFilter() {
    if (_allDoctors == null || _allDoctors!.isEmpty) return;

    // Filter doctors available today
    // You should adjust this logic based on your actual availability data
    _filteredBySpecialty = _allDoctors!.where((doctor) {
      // This is a placeholder - replace with actual availability check
      // For example, if doctor has availability data:
      // return doctor.availableDays?.contains(today.weekday) ?? false;

      // For now, return all as example
      return true;
    }).toList();
  }

  /// Apply combined filters (specialty + search)
  void _applyCombinedFilters() {
    List<Doctor>? sourceList = _filteredBySpecialty ?? _allDoctors;

    if (sourceList == null || sourceList.isEmpty) {
      _combinedFilteredDoctors = null;
      return;
    }

    if (_searchQuery.isEmpty) {
      // If no search query, use the specialty filtered list or all doctors
      _combinedFilteredDoctors = _filteredBySpecialty ?? List.from(_allDoctors!);
    } else {
      // Apply search on the current list
      final searchQuery = _searchQuery.toLowerCase().trim();

      _combinedFilteredDoctors = sourceList.where((doctor) {
        final name = doctor.name?.toLowerCase() ?? '';
        final specialization = doctor.name?.toLowerCase() ?? '';
        final qualifications = doctor.email?.toLowerCase() ?? '';

        return name.contains(searchQuery) ||
            specialization.contains(searchQuery) ||
            qualifications.contains(searchQuery);
      }).toList();
    }
  }

  /// API call
  Future<void> doctorDetailApiData({
    String? doctorId,
    DateTime? date,
    String? time,
  }) async {
    setLoadingDoc(true);
    setDoctorApiData(ApiResponse.loading());

    Map<String, dynamic> data = {
      if (doctorId?.isNotEmpty ?? false) "doctorId": doctorId,
      if (date != null) "date": formatDate(date),
      if (time?.isNotEmpty ?? false) "time": time,
    };

    pt("data>>>>>>>>>> $data");

    try {
      final value = await repository.getDoctorApi(data);

      if (value.success == true) {
        setDoctorApiData(ApiResponse.completed(value));
      } else {
        setDoctorApiData(ApiResponse.error(value.message ?? "failed"));
      }
    } catch (e) {
      setDoctorApiData(ApiResponse.error(e.toString()));
    } finally {
      setLoadingDoc(false);
    }
  }

  /// DEBOUNCED SEARCH FUNCTIONALITY
  void searchDoctors(String query) {
    // Cancel previous timer
    if (_searchDebounceTimer != null && _searchDebounceTimer!.isActive) {
      _searchDebounceTimer!.cancel();
    }

    _searchQuery = query;

    // Set new timer for debounce (300ms)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyCombinedFilters();
      notifyListeners();
    });
  }

  /// Clean up when provider is disposed
  @override
  void dispose() {
    searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  ///================================================add booking
  ApiResponse<BookingAddModel>? _addBooking = ApiResponse.completed(null);
  ApiResponse<BookingAddModel>? get addBooking => _addBooking;

  /// Set API data and apply current search filter
  void addBookingData(ApiResponse<BookingAddModel> response) {
    _addBooking = response;
    notifyListeners();
  }

  Future<void> addBookingApi({required String date, required String time}) async {
    setLoadingDoc(true);
    addBookingData(ApiResponse.loading());
    final docId = await UserLocalData.getDoctorId();
    Map<String, dynamic> data = {
      "doctorId": selectedDoctorId == "" ? docId : selectedDoctorId,
      "date": extractOnlyDate(date),
      "time": time,
      "consultationFee": 500,
      "currency": "INR",
      "paymentMethod": isRazorPaySelected ? "Razorpay" : "COD"
    };
    pt("data>>>>>>>>>> $data");
    try {
      final value = await repository.bookingAdd(data);
      if (value.success == true) {
        addBookingData(ApiResponse.completed(value));
        showBookingSuccessDialog(navigatorKey.currentContext!,name: capitalizeFirstLetter(value.data?.doctorId?.name ??""));
        AppPopUp.showToast(
            message: value.message ?? "Something went wrong",
            lineColor: AppColors.red
        );
      } else {
        AppPopUp.showToast(
            message: value.message ?? "Something went wrong",
            lineColor: AppColors.red
        );
        addBookingData(ApiResponse.error(value.message ?? "failed"));
      }
    } catch (e) {
      addBookingData(ApiResponse.error(e.toString()));
    } finally {
      setLoadingDoc(false);
    }
  }
 ///================================================cancel booking
  ApiResponse<CommonResponseModel>? _cancelBooking = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get cancelBooking => _cancelBooking;

  // int _selectedIndex = (-1);

  /// Set API data and apply current search filter
  void cancelBookingData(ApiResponse<CommonResponseModel> response) {
    _cancelBooking = response;
    notifyListeners();
  }

  Future<void> cancelBookingApi({required String id}) async {
    cancelBookingData(ApiResponse.loading());
    try {
      final value = await repository.cancelBooking(id);
      if (value.success == true) {
        cancelBookingData(ApiResponse.completed(value));
        AppPopUp.showToast(
            message: value.message ?? "Something went wrong",
            lineColor: AppColors.red
        );
      } else {
        AppPopUp.showToast(
            message: value.message ?? "Something went wrong",
            lineColor: AppColors.red
        );
        cancelBookingData(ApiResponse.error(value.message ?? "failed"));
      }
    } catch (e) {
      cancelBookingData(ApiResponse.error(e.toString()));
    }
  }

  String formatDate(DateTime date) {
    try {
      final outputFormat = DateFormat('yyyy-MM-dd');
      return outputFormat.format(date);
    } catch (e) {
      pt("Date format error: $e");
      return "";
    }
  }

  String extractOnlyDate(String dateTimeString) {
    if (dateTimeString.contains(" ")) {
      return dateTimeString.split(" ").first;
    }
    return dateTimeString;
  }

  Future<void> showBookingSuccessDialog(BuildContext context,{required String name}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppContainer(
                    radius: 100,
                    color: AppColors.greenLight.withAlpha(100),
                    padding: EdgeInsets.all(10),
                    child: AppContainer(
                      padding: EdgeInsets.all(8),
                      radius: 100,
                      color: AppColors.green.withAlpha(180),
                      child: Icon(Icons.check_circle, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Booking Successful",
                    style: AppFontStyle.text_20_600(
                        color: AppColors.textClr,
                        fontFamily: AppFontFamily.gilroySemiBold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: "Your appointment booking completed.\n",
                      style: AppFontStyle.text_13_400(
                          color: AppColors.textLightClr,
                          fontFamily: AppFontFamily.gilroyMedium
                      ),
                      children: [
                        TextSpan(
                          text: name ?? "",
                          style: AppFontStyle.text_15_600(
                              color: AppColors.textClr,
                              fontFamily: AppFontFamily.gilroyMedium
                          ),
                        ),
                        TextSpan(
                          text: " will message you soon.",
                          style: AppFontStyle.text_13_400(
                              color: AppColors.textLightClr,
                              fontFamily: AppFontFamily.gilroyMedium
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Button(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.myBookingsView);
                    },
                    borderRadius: 8,
                    gradient: LinearGradient(colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade300
                    ]),
                    child: Text(
                      "Done",
                      style: AppFontStyle.text_16_600(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.textClr
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String getDayName(DateTime date) {
    final formatter = DateFormat('EEEE');  // Monday (full) या 'EEE' for Mon
    return formatter.format(date);
  }


  String formatDateMMMMddyyyy(DateTime date) {
    final formatter = DateFormat('MMMM dd, yyyy');  // March 14, 2022
    return formatter.format(date);
  }


  /// get available slot data here

  ApiResponse<AvailableSlotDataModel>? _getAvailableSlot = ApiResponse.completed(null);
  ApiResponse<AvailableSlotDataModel>? get getAvailableSlot => _getAvailableSlot;

  /// Set API data and apply current search filter
  void setAvailableSlotData(ApiResponse<AvailableSlotDataModel> response) {
    _getAvailableSlot = response;
    notifyListeners();
  }


  Future<void> getAvailableSlotApiData({
    DateTime? date,
  }) async {
    setAvailableSlotData(ApiResponse.loading());

    Map<String, dynamic> data = {
      if (date != null) "date": formatDate(date),
    };

    pt("data>>>>>>>>>> $data");

    try {
      final value = await repository.getSlotApi(data);

      if (value.success == true) {
        setAvailableSlotData(ApiResponse.completed(value));
      } else {
        setAvailableSlotData(ApiResponse.error(value.message ?? "failed"));
      }
    } catch (e) {
      setAvailableSlotData(ApiResponse.error(e.toString()));
    }
  }


}


