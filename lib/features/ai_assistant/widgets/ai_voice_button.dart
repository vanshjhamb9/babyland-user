import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';

/// Animated voice input button for the AI assistant.
class AiVoiceButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const AiVoiceButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<AiVoiceButton> createState() => _AiVoiceButtonState();
}

class _AiVoiceButtonState extends State<AiVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AiVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                isBordered: true,
                radius: 100,
                color: AppColors.white,
                borderColor: AppColors.buttonClr2.withValues(alpha: 0.5),
                child: Text(
                  'Listening...',
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.buttonClr2.withValues(alpha: 0.2),
                      width: 3,
                    ),
                    boxShadow: widget.isListening
                        ? [
                            BoxShadow(
                              color: AppColors.buttonClr2.withValues(
                                alpha: _pulseAnimation.value * 0.4,
                              ),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isListening
                          ? AppColors.buttonClr2.withValues(alpha: 0.15)
                          : AppColors.white,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none,
                      color: widget.isListening
                          ? AppColors.buttonClr2
                          : AppColors.textClr,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
