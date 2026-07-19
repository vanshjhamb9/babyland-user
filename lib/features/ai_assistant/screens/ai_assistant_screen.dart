import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/common_profile_header/get_user_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_appbar.dart';
import '../../../app/widgets/general_exception.dart';
import '../../../app/widgets/text.dart';
import '../../../app/widgets/user_avatar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_ai_context.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/ai_message_model.dart';
import '../widgets/ai_chat_input.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ira_avatar.dart';

/// Advanced AI Assistant screen with ChatGPT-level experience.
///
/// Features:
/// - Streaming AI responses with typing animation
/// - Voice input (STT) and voice output (TTS)
/// - Message reactions (thumbs up/down → AI learning engine)
/// - Conversation history
/// - Quick-action suggestions
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  static const _quickActions = [
    "Pregnancy diet tips",
    "Is nausea normal?",
    "Baby development this week",
    "Safe exercises",
    "What should I eat today?",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatController = context.read<AiChatController>();
      final userProvider = context.read<GetUserProvider>();
      chatController.updateUserContext(_buildUserAiContext(userProvider));
      chatController.initialize();
    });
  }

  UserAiContext _buildUserAiContext(GetUserProvider userProvider) {
    final user = userProvider.userData?.data?.user?.user;
    final tracker = userProvider.userData?.data?.user?.pregnancyTracker;
    final medicalHistory = user?.medicalHistory?.trim();

    return UserAiContext(
      userId: user?.sId ?? '',
      stage: user?.stage?.toString(),
      pregnancyWeek: int.tryParse(
        tracker?['pregnancy_week']?.toString() ??
            tracker?['week']?.toString() ??
            '',
      ),
      dietPreferences: const [],
      medicalConditions: medicalHistory == null || medicalHistory.isEmpty
          ? const []
          : [medicalHistory],
      location: null,
      previousQuestions: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Consumer<AiChatController>(
        builder: (context, controller, _) {
          if (!controller.isInitialized && controller.isLoading) {
            return _buildShimmer(context);
          }

          if (controller.error != null && !controller.isInitialized) {
            return GeneralExceptionWidget(
              onPress: () {
                controller.clearError();
                controller.initialize();
              },
            );
          }

          return _buildBody(controller);
        },
      ),
    );
  }

  Widget _buildBody(AiChatController controller) {
    return SafeArea(
      child: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Column(
          children: [
            // Quick actions when no messages
            if (controller.messages.isEmpty) _buildQuickActions(controller),

            // Messages list
            Expanded(
              child: ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.messages.length +
                    (controller.isLoading && !controller.isStreaming ? 1 : 0),
                itemBuilder: (context, index) {
                  // Loading indicator at the end
                  if (index == controller.messages.length) {
                    return _buildLoadingBubble();
                  }

                  final message = controller.messages[index];
                  return AiMessageBubble(
                    message: message,
                    isSpeaking: controller.isSpeaking,
                    onThumbsUp: message.role == MessageRole.assistant &&
                            message.traceId != null
                        ? () => controller.submitFeedback(
                              message.id,
                              MessageFeedback.positive,
                            )
                        : null,
                    onThumbsDown: message.role == MessageRole.assistant &&
                            message.traceId != null
                        ? () => controller.submitFeedback(
                              message.id,
                              MessageFeedback.negative,
                            )
                        : null,
                    onSpeak: message.role == MessageRole.assistant
                        ? () => controller.speakMessage(message.content)
                        : null,
                  );
                },
              ),
            ),

            AiChatInput(
              controller: controller.messageController,
              isLoading: controller.isLoading,
              isStreaming: controller.isStreaming,
              isHoldRecording: controller.isHoldRecording,
              onSend: () => controller.sendMessage(),
              onVoiceTap: () => controller.toggleVoiceInput(),
              onVoiceHoldStart: () => controller.startHoldToTalk(),
              onVoiceHoldEnd: () => controller.stopHoldToTalkAndSend(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AiChatController controller) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<GetUserProvider>(
              builder: (context, userProvider, _) {
                return GradientText(
                  'Hello ${userProvider.userData?.data?.user?.user?.name ?? ''},',
                  gradient: AppColors.buttonClr,
                  style: AppFontStyle.text_26_400(
                      fontFamily: AppFontFamily.gilroyBold),
                );
              },
            ),
            Text(
              'Ask ${AppConstants.aiAssistantDisplayName} anything...',
              style: AppFontStyle.text_26_400(
                  fontFamily: AppFontFamily.gilroyMedium),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickActions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => controller.sendQuickMessage(_quickActions[index]),
                  child: AppContainer(
                    radius: 8,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: AppColors.white,
                    isBordered: true,
                    child: Text(
                      _quickActions[index],
                      style: AppFontStyle.text_14_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textClr,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
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
              AppContainer(
                borderColor: AppColors.borderColor,
                radius: 12,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                gradient: AppColors.whiteGradientClr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPulseDot(0),
                    const SizedBox(width: 6),
                    _buildPulseDot(200),
                    const SizedBox(width: 6),
                    _buildPulseDot(400),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.buttonClr2.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  CustomAppBar _buildAppBar() {
    return CustomAppBar(
      toolbarHeight: 100,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppConstants.aiAssistantDisplayName,
            style:
                AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroyMedium),
          ),
          const SizedBox(width: 6),
          const IraAvatar(size: 24),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.read<AiChatController>().loadHistory(),
          icon: const Icon(Icons.history),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppContainer(
              gradient: AppColors.buttonClr,
              radius: 100,
              padding: const EdgeInsets.all(1),
              child: UserAvatar(
                size: 40,
                imageUrl: context.read<GetUserProvider>().userData?.data?.user?.user?.profilePicture,
                name: context.read<GetUserProvider>().userData?.data?.user?.user?.name,
                stage: context.read<GetUserProvider>().userData?.data?.user?.user?.stage,
              ),
            ),
            Consumer<GetUserProvider>(
              builder: (context, provider, _) {
                return Positioned(
                  bottom: -10,
                  child: AppContainer(
                    color: AppColors.white,
                    borderColor: AppColors.buttonClr1,
                    radius: 100,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Text(
                      '${provider.userData?.data?.user?.profileCompletion ?? "0"}%',
                      style: AppFontStyle.text_10_400(
                          fontFamily: AppFontFamily.gilroyMedium),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return AppContainer(
      gradient: AppColors.backGroundColor,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 10,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: index.isEven
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      (index.isEven ? 0.7 : 0.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('', style: TextStyle(color: Colors.transparent)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
