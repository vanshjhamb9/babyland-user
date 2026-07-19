import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';

/// Non-blocking hint while REST reconciliation or slot refresh is in flight.
class StaleSyncBanner extends StatelessWidget {
  const StaleSyncBanner({
    super.key,
    this.message = 'Refreshing latest availability...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppFontStyle.text_13_600(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textClr,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
