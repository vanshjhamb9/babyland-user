import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../models/ai_message_model.dart';
import 'ira_avatar.dart';

/// A single chat message bubble with optional feedback buttons and TTS.
class AiMessageBubble extends StatelessWidget {
  final AiMessageModel message;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onThumbsUp,
    this.onThumbsDown,
    this.onSpeak,
    this.isSpeaking = false,
  });

  bool get isAssistant => message.role == MessageRole.assistant;

  @override
  Widget build(BuildContext context) {
    if (isAssistant) {
      return _buildAssistantMessage(context);
    }
    return _buildUserMessage(context);
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 60, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Text(
              'IRA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLightClr.withOpacity(0.7),
                fontFamily: AppFontFamily.gilroySemiBold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IraAvatar(size: 32),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppContainer(
                      borderColor: AppColors.borderColor,
                      radius: 12,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      gradient: AppColors.whiteGradientClr,
                      child: _buildContent(),
                    ),
                    if (!message.isStreaming) _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 6, 16, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: IntrinsicWidth(
          child: AppContainer(
            borderColor: AppColors.transparent,
            radius: 12,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            gradient: AppColors.backGroundColor,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (message.isStreaming && message.content.isEmpty) {
      return _buildTypingIndicator();
    }

    return _SafeMarkdownText(text: message.content);
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypingDot(delay: 0),
        const SizedBox(width: 4),
        _TypingDot(delay: 200),
        const SizedBox(width: 4),
        _TypingDot(delay: 400),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbs up
          _FeedbackButton(
            icon: Icons.thumb_up_outlined,
            activeIcon: Icons.thumb_up,
            isActive: message.feedback == MessageFeedback.positive,
            onTap: onThumbsUp,
            tooltip: 'Helpful',
          ),
          const SizedBox(width: 8),
          // Thumbs down
          _FeedbackButton(
            icon: Icons.thumb_down_outlined,
            activeIcon: Icons.thumb_down,
            isActive: message.feedback == MessageFeedback.negative,
            onTap: onThumbsDown,
            tooltip: 'Not helpful',
          ),
          const SizedBox(width: 8),
          // TTS button
          InkWell(
            onTap: onSpeak,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isSpeaking ? Icons.volume_off : Icons.volume_up_outlined,
                size: 18,
                color: AppColors.textLightClr,
              ),
            ),
          ),
          // Latency badge
          if (message.latencyMs != null && message.latencyMs! > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${message.latencyMs}ms',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textLightClr.withValues(alpha: 0.6),
                fontFamily: AppFontFamily.gilroyRegular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback? onTap;
  final String tooltip;

  const _FeedbackButton({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 18,
            color: isActive ? AppColors.buttonClr2 : AppColors.textLightClr,
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.buttonClr2,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Safe markdown text renderer (reused from existing code).
class _SafeMarkdownText extends StatelessWidget {
  final String text;
  const _SafeMarkdownText({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(_header(line.substring(4), 15));
      } else if (line.startsWith('## ')) {
        widgets.add(_header(line.substring(3), 16));
      } else if (line.startsWith('# ')) {
        widgets.add(_header(line.substring(2), 18));
      } else if (line.trim() == '---') {
        widgets.add(const Divider(height: 16));
      } else if (line.trim().startsWith('- ') ||
          line.trim().startsWith('* ')) {
        widgets.add(_bulletItem(line.trim().substring(2)));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        final match = RegExp(r'^(\d+)\.\s(.*)').firstMatch(line.trim());
        widgets.add(_numberedItem(match?.group(1) ?? '1', match?.group(2) ?? line));
      } else if (line.contains('**')) {
        widgets.add(_richText(line));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            line,
            style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _header(String text, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text.trim(),
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          fontFamily: AppFontFamily.gilroySemiBold,
        ),
      ),
    );
  }

  Widget _bulletItem(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(child: _richText(content)),
        ],
      ),
    );
  }

  Widget _numberedItem(String number, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: const TextStyle(fontSize: 14)),
          Expanded(child: _richText(content)),
        ],
      ),
    );
  }

  Widget _richText(String text) {
    if (!text.contains('**')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text.replaceAll('*', ''),
          style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
        ),
      );
    }

    final parts = text.split('**');
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd
            ? AppFontStyle.text_14_600(fontFamily: AppFontFamily.gilroySemiBold)
            : AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}
