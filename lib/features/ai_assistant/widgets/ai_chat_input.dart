import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_image.dart';
import '../../../app/widgets/custom_textform_field.dart';
import '../../../app/constants/images.dart';

/// Chat input bar with text field, voice input toggle, and send button.
class AiChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isStreaming;
  final bool isHoldRecording;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;
  final VoidCallback onVoiceHoldStart;
  final VoidCallback onVoiceHoldEnd;

  const AiChatInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.isStreaming,
    required this.isHoldRecording,
    required this.onSend,
    required this.onVoiceTap,
    required this.onVoiceHoldStart,
    required this.onVoiceHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 15, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isHoldRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recording… release to send',
                    style: AppFontStyle.text_13_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          Row(
        children: [
          Expanded(
            child: CustomTextFormField(
              borderRadius: BorderRadius.circular(100),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              borderColor: AppColors.borderColor,
              filled: true,
              fillColor: AppColors.white,
              hintText: 'Type your message...',
              controller: controller,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: CustomImage(path: ImageConstants.attachIcon),
              ),
              suffix: InkWell(
                onTap: onVoiceTap,
                splashColor: AppColors.transparent,
                highlightColor: AppColors.transparent,
                child: GestureDetector(
                  onLongPressStart: (_) => onVoiceHoldStart(),
                  onLongPressEnd: (_) => onVoiceHoldEnd(),
                  child: SizedBox(
                    height: 15,
                    width: 15,
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Opacity(
                        opacity: isHoldRecording ? 0.6 : 1,
                        child: CustomImage(path: ImageConstants.micIcon),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: (isLoading || isStreaming) ? null : onSend,
            child: AppContainer(
              gradient: AppColors.buttonClr,
              radius: 100,
              padding: const EdgeInsets.all(16),
              child: (isLoading || isStreaming)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : CustomImage(path: ImageConstants.sendIcon),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
