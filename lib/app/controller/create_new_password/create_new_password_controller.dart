import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateNewPasswordProvider extends ChangeNotifier{

  final passwordController  = TextEditingController();
  final confirmPasswordController  = TextEditingController();
  //strong password validation
  bool hasMinLength = false;
  bool hasLetter = false;
  bool hasNumberOrSymbol = false;

  int trueConditionsCount = 0;

  void validatePassword(String value) {
    hasMinLength = value.length >= 8;
    hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(value);
    bool hasSymbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value);
    hasNumberOrSymbol = hasNumber || hasSymbol;

    trueConditionsCount = [
      hasMinLength,
      hasLetter,
      hasNumberOrSymbol
    ].where((c) => c).length;
    notifyListeners();
  }


  bool get isPasswordValid => hasMinLength && hasLetter && hasNumberOrSymbol;

  String getPasswordStrength() {
    switch (trueConditionsCount) {
      case 0:
      case 1:
        return "Weak";
      case 2:
        return "Medium";
      case 3:
        return "Strong";
      default:
        return "";
    }
  }

  Color getStrengthColor() {
    switch (trueConditionsCount) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

}