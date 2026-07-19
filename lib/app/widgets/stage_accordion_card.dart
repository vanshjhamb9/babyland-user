import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

/// Data for a single stage row in the accordion list.
class StageAccordionData {
  const StageAccordionData({
    required this.title,
    required this.imagePath,
    required this.description,
    required this.features,
    this.compactImagePadding = false,
  });

  final String title;
  final String imagePath;
  final String description;
  final List<String> features;
  final bool compactImagePadding;
}

/// Expandable stage card with animated height, rotating chevron, and optional Next CTA.
class StageAccordionCard extends StatefulWidget {
  const StageAccordionCard({
    super.key,
    required this.data,
    required this.isExpanded,
    required this.isSelected,
    required this.onHeaderTap,
    this.onNext,
    this.showNextButton = true,
  });

  final StageAccordionData data;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onHeaderTap;
  final VoidCallback? onNext;
  final bool showNextButton;

  static const Duration animationDuration = Duration(milliseconds: 300);

  @override
  State<StageAccordionCard> createState() => _StageAccordionCardState();
}

class _StageAccordionCardState extends State<StageAccordionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;
  late Animation<double> _rotationTurns;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: StageAccordionCard.animationDuration,
    );
    _rotationTurns = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) {
      _rotateController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant StageAccordionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _rotateController.forward();
      } else {
        _rotateController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  /// AppFontStyle sets [TextOverflow.ellipsis], which limits text to one line
  /// when maxLines is null — use a plain TextStyle for multi-line body copy.
  TextStyle _bodyStyle({Color? color, double? height}) {
    return TextStyle(
      color: color ?? AppColors.textLightClr,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: height ?? 1.5,
      fontFamily: AppFontFamily.gilroyRegular,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.buttonClr1
        : AppColors.borderColor;
    final borderWidth = widget.isSelected ? 2.0 : 1.0;
    final fillColor = widget.isSelected
        ? AppColors.buttonClr1.withValues(alpha: 0.08)
        : AppColors.white;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: AppColors.textClr.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.onHeaderTap,
              splashColor: AppColors.buttonClr1.withValues(alpha: 0.12),
              highlightColor: AppColors.buttonClr1.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: widget.data.compactImagePadding
                          ? const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            )
                          : const EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: CustomImage(
                          path: widget.data.imagePath,
                          w: 44,
                          h: 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFontStyle.text_15_400(
                              color: widget.isSelected
                                  ? AppColors.buttonClr1
                                  : AppColors.textClr,
                              fontFamily: AppFontFamily.gilroySemiBold,
                            ),
                          ),
                          if (!widget.isExpanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.data.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _bodyStyle(color: AppColors.textLightClr),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: _rotationTurns,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: widget.isSelected
                            ? AppColors.buttonClr1
                            : AppColors.textLightClr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: StageAccordionCard.animationDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: widget.isExpanded
                  ? _ExpandedBody(
                      data: widget.data,
                      showNextButton: widget.showNextButton,
                      onNext: widget.onNext,
                      bodyStyle: _bodyStyle,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.data,
    required this.showNextButton,
    required this.bodyStyle,
    this.onNext,
  });

  final StageAccordionData data;
  final bool showNextButton;
  final TextStyle Function({Color? color, double? height}) bodyStyle;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1,
            color: AppColors.borderColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            softWrap: true,
            style: bodyStyle(color: AppColors.textLightClr, height: 1.55),
          ),
          const SizedBox(height: 12),
          ...data.features.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.buttonClr1.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: bodyStyle(
                        color: AppColors.textClr,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showNextButton && onNext != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.buttonClr1,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Next',
                  style: AppFontStyle.text_15_400(
                    color: AppColors.white,
                    fontFamily: AppFontFamily.gilroySemiBold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
