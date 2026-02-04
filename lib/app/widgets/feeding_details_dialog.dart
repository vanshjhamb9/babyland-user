import 'package:babyland/app/controller/post_pregenancy/model/recovery_progress_model.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedingDetailsDialog extends StatelessWidget {
  final Feedings feeding;

  const FeedingDetailsDialog({super.key, required this.feeding});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Feeding Details",
                    style: AppFontStyle.text_18_400(
                      fontFamily: AppFontFamily.gilroySemiBold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 20),

              _buildDetailItem("Type", feeding.type ?? "N/A"),
              
              if (feeding.type == "Breastfeeding")
                _buildDetailItem("Side", feeding.side ?? "N/A"),
              
              _buildDetailItem(
                "Date & Time", 
                fetchingDate(feeding.time),
              ),
              
              if (feeding.durationMinutes != null && feeding.durationMinutes != "0")
                _buildDetailItem("Duration", "${feeding.durationMinutes} minutes"),
                
              if (feeding.quantity != null && feeding.quantity!.isNotEmpty)
                _buildDetailItem("Quantity", feeding.quantity ?? "N/A"),
                
              if (feeding.notes != null && feeding.notes!.isNotEmpty)
                _buildDetailItem("Notes", feeding.notes ?? "N/A"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFontStyle.text_14_400(
            fontFamily: AppFontFamily.gilroyMedium,
            color: AppColors.textLightClr,
          ),
        ),
        SizedBox(height: 4),
        AppContainer(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          radius: 8,
          color: AppColors.white,
          isBordered: true,
          child: Text(
            value,
            style: AppFontStyle.text_16_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textClr,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  String fetchingDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy h:mm a').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
