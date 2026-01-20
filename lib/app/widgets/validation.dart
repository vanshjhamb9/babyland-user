import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

bool isValidEmail(String? inputString, {bool isRequired = false,}) {
  bool isInputStringValid = false;

  if (!isRequired && (inputString == null ? true : inputString.isEmpty)) {
    isInputStringValid = true;
  }

  if (inputString != null && inputString.isNotEmpty) {
    const pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    final regExp = RegExp(pattern);

    isInputStringValid = regExp.hasMatch(inputString);
  }

  return isInputStringValid;
}




//-------------------------formatDateForApi 16-11-2025

String formatDateForApi(String inputDate) {
  try {
    final inputFormat = DateFormat('dd-MM-yyyy');
    final outputFormat = DateFormat('yyyy-MM-dd');
    final parsedDate = inputFormat.parse(inputDate);
    return outputFormat.format(parsedDate);
  } catch (e) {
    pt("Date format error: $e");
    return "";
  }
}


//fotmat === 2025-11-16
String formatDateForApiYMD(String inputDate) {
  try {
    // If already in required format, return directly
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(inputDate)) {
      return inputDate;
    }

    final inputFormat = DateFormat('dd-MM-yyyy');
    final outputFormat = DateFormat('yyyy-MM-dd');
    final parsedDate = inputFormat.parse(inputDate);

    return outputFormat.format(parsedDate);
  } catch (e) {
    pt("Date format error: $e");
    return "";
  }
}


String formatDateForDisplay(DateTime date) {
  final outputFormat = DateFormat('MMMM d, yyyy');
  return outputFormat.format(date);
}

String formatDateToDayMonth(String inputDate) {
  try {
    final date = DateTime.parse(inputDate); // parse "2025-11-01"
    return DateFormat("dd MMM").format(date); // output: "01 Nov"
  } catch (e) {
    return inputDate; // fallback if parsing fails
  }
}


//-------------------------loder
 customLoading({Color? color}) {
  return  Center(
    child: SpinKitThreeBounce(
      color:color ?? AppColors.white,
      size: 24,
    ),
  );
}

//jab api se response aata hai
String formatDate(String dateString) {
  try {
    // Try parsing API format (yyyy-MM-dd)
    DateTime date = DateTime.parse(dateString);

    return DateFormat('MMMM d, yyyy').format(date);
  } catch (e) {
    // If the input is already like "November 2, 2024"
    try {
      DateTime date = DateFormat('MMMM d, yyyy').parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (_) {
      return "Invalid date"; // fallback
    }
  }

}


String capitalizeFirstLetter(String name) {
  if (name.isEmpty) return name;
  return name[0].toUpperCase() + name.substring(1);
}
