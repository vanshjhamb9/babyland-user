import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedingEntryDialog extends StatefulWidget {
  const FeedingEntryDialog({super.key});

  @override
  State<FeedingEntryDialog> createState() => _FeedingEntryDialogState();
}

class _FeedingEntryDialogState extends State<FeedingEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _durationController = TextEditingController();
  
  String _selectedType = "Breastfeeding";
  String _selectedSide = "Both";
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  final List<String> _feedingTypes = ["Breastfeeding", "Bottle", "Pumping"];
  final List<String> _sides = ["Left", "Right", "Both"];

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitFeeding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        "time": _selectedDateTime.toIso8601String(),
        "type": _selectedType,
        "side": _selectedSide,
        if (_durationController.text.isNotEmpty)
          "durationMinutes": int.tryParse(_durationController.text) ?? 0,
        if (_quantityController.text.isNotEmpty)
          "quantity": _quantityController.text,
        if (_notesController.text.isNotEmpty)
          "notes": _notesController.text,
      };

      final response = await Repository().addFeeding(data);

      setState(() => _isLoading = false);

      if (response.success == true) {
        if (mounted) {
          AppPopUp.showToast(message: "Feeding log added successfully!");
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          AppPopUp.showToast(
            message: response.message ?? "Failed to add feeding log",
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppPopUp.showToast(message: "Error: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Add Feeding Log",
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

                // Feeding Type
                Text(
                  "Feeding Type *",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                SizedBox(height: 8),
                AppContainer(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  radius: 8,
                  color: AppColors.white,
                  isBordered: true,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      items: _feedingTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Side (only for Breastfeeding)
                if (_selectedType == "Breastfeeding") ...[
                  Text(
                    "Side",
                    style: AppFontStyle.text_14_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                  ),
                  SizedBox(height: 8),
                  AppContainer(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    radius: 8,
                    color: AppColors.white,
                    isBordered: true,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSide,
                        isExpanded: true,
                        items: _sides.map((side) {
                          return DropdownMenuItem(
                            value: side,
                            child: Text(side),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSide = value);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Date & Time
                Text(
                  "Date & Time *",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateTime(context),
                  child: AppContainer(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    radius: 8,
                    color: AppColors.white,
                    isBordered: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy h:mm a')
                              .format(_selectedDateTime),
                          style: AppFontStyle.text_14_400(),
                        ),
                        Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Duration
                Text(
                  "Duration (minutes)",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                SizedBox(height: 8),
                AppContainer(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  radius: 8,
                  color: AppColors.white,
                  isBordered: true,
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "e.g., 20",
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Quantity
                Text(
                  "Quantity",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                SizedBox(height: 8),
                AppContainer(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  radius: 8,
                  color: AppColors.white,
                  isBordered: true,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "e.g., 100ml",
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Notes
                Text(
                  "Notes",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                SizedBox(height: 8),
                AppContainer(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  radius: 8,
                  color: AppColors.white,
                  isBordered: true,
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Any additional notes...",
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Submit Button
                Button(
                  onTap: _isLoading ? null : _submitFeeding,
                  height: 48,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Add Feeding Log",
                          style: AppFontStyle.text_16_400(
                            fontFamily: AppFontFamily.gilroyBold,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
