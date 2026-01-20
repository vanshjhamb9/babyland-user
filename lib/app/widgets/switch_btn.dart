import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({
    super.key,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 65,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isEnabled
              ? AppColors.buttonClr
              : null,
          color: isEnabled ? null : Colors.white,
          border: isEnabled
              ? null
              : Border.all(color: Colors.grey.shade300),
        ),
        child: AnimatedAlign(
          alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: !isEnabled ? AppColors.buttonClr : LinearGradient(colors: [AppColors.white,AppColors.white]) ,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 2),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
