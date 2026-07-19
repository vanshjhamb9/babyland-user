import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/models/health_tracker_models.dart';
import 'package:babyland/core/theme/premium_app_theme.dart';
import 'package:babyland/core/utils/error_ui_handler.dart';
import 'package:flutter/material.dart';

class AddHydrationScreen extends StatefulWidget {
  const AddHydrationScreen({super.key});

  @override
  State<AddHydrationScreen> createState() => _AddHydrationScreenState();
}

class _AddHydrationScreenState extends State<AddHydrationScreen> {
  final _mlController = TextEditingController();
  bool _isSaving = false;

  int _goalMl = 3000;

  int _previewMl() {
    return int.tryParse(_mlController.text.trim()) ?? 0;
  }

  double _ratio() {
    final ml = _previewMl();
    if (_goalMl <= 0) return 0;
    return (ml / _goalMl).clamp(0, 1);
  }

  @override
  void initState() {
    super.initState();
    _mlController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: const Text('Add Water Intake'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Add Water Intake',
                style: AppTextStylesPremium.h2(),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter how much water you drank (ml).',
                style: AppTextStylesPremium.caption(),
              ),
              const SizedBox(height: 14),
              CustomTextFormField(
                controller: _mlController,
                textInputType: TextInputType.number,
                hintText: 'ml',
                borderColor: AppColors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              const SizedBox(height: 14),
              _QuickAmountRow(
                onPick: (v) {
                  setState(() => _mlController.text = v.toString());
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
                  boxShadow: [AppShadowPremium.softShadow()],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress preview',
                      style: AppTextStylesPremium.caption(color: AppColorsPremium.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: _ratio(),
                        minHeight: 10,
                        backgroundColor: AppColors.grey.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColorsPremium.accent),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_previewMl()} ml of $_goalMl ml',
                      style: AppTextStylesPremium.body(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _SaveButton(
                  isSaving: _isSaving,
                  onPressed: _save,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ml = _previewMl();
    if (ml <= 0) {
      ErrorUIHandler.showSnackBar(context, 'Please enter a valid amount.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final summaryData = await sl.dashboardService.refresh();
      _goalMl = summaryData.healthSummary.hydration.goal;

      await sl.healthTrackerService.createHydrationLog(
        HydrationLog(
          timestamp: DateTime.now(),
          amountMl: ml,
          type: 'water',
        ),
      );

      if (!context.mounted) return;
      Navigator.pop(context, true);
      ErrorUIHandler.showSnackBar(context, 'Water added successfully!', isError: false);
    } catch (e) {
      if (!context.mounted) return;
      ErrorUIHandler.showSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _QuickAmountRow extends StatelessWidget {
  final ValueChanged<int> onPick;
  const _QuickAmountRow({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _QuickAmountButton(label: '+250ml', value: 250, onPick: onPick),
        _QuickAmountButton(label: '+500ml', value: 500, onPick: onPick),
        _QuickAmountButton(label: '+1L', value: 1000, onPick: onPick),
      ],
    );
  }
}

class _QuickAmountButton extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onPick;

  const _QuickAmountButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  State<_QuickAmountButton> createState() => _QuickAmountButtonState();
}

class _QuickAmountButtonState extends State<_QuickAmountButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: () => widget.onPick(widget.value),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: AppColorsPremium.hydrationGradient,
            borderRadius: BorderRadius.circular(AppRadiusPremium.buttons),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStylesPremium.body(color: Colors.white).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;
  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey.shade300,
        backgroundColor: AppColorsPremium.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusPremium.buttons),
        ),
      ),
      child: isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
    );
  }
}

