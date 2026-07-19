import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_appbar.dart';
import '../../../app/widgets/text.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/ai_assistant/models/ai_message_model.dart';
import '../controllers/conversation_memory_controller.dart';

/// AI Conversation Memory screen.
///
/// Users can view past AI conversations and saved health insights.
class ConversationMemoryScreen extends StatefulWidget {
  const ConversationMemoryScreen({super.key});

  @override
  State<ConversationMemoryScreen> createState() =>
      _ConversationMemoryScreenState();
}

class _ConversationMemoryScreenState extends State<ConversationMemoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationMemoryController>().refreshAll();
    });

    _tabController.addListener(() {
      context
          .read<ConversationMemoryController>()
          .setTab(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        toolbarHeight: 70,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, color: AppColors.buttonClr2, size: 22),
            const SizedBox(width: 8),
            GradientText(
              '${AppConstants.aiAssistantDisplayName} Memory',
              gradient: AppColors.buttonClr,
              style: AppFontStyle.text_20_400(
                fontFamily: AppFontFamily.gilroyBold,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ConversationMemoryController>(
        builder: (context, controller, _) {
          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: Column(
              children: [
                // Tab bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.buttonClr,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.textLightClr,
                    labelStyle: AppFontStyle.text_13_600(
                      fontFamily: AppFontFamily.gilroySemiBold,
                    ),
                    unselectedLabelStyle: AppFontStyle.text_13_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Conversations'),
                      Tab(text: 'Saved Insights'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: controller.isLoading
                      ? _buildShimmer()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildConversationList(controller),
                            _buildBookmarksList(controller),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationList(ConversationMemoryController controller) {
    if (controller.history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        subtitle:
            'Your ${AppConstants.aiAssistantDisplayName} chat history will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.history.length,
      itemBuilder: (context, index) {
        final message = controller.history[index];
        return _buildMessageTile(message, controller);
      },
    );
  }

  Widget _buildBookmarksList(ConversationMemoryController controller) {
    if (controller.bookmarks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'No saved insights',
        subtitle: 'Bookmark AI messages to save them here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = controller.bookmarks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: Key(bookmark.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => controller.removeBookmark(bookmark.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: AppColors.red),
            ),
            child: AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(14),
              color: AppColors.white,
              borderColor: AppColors.borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bookmark,
                          color: AppColors.buttonClr2, size: 18),
                      const SizedBox(width: 6),
                      _buildCategoryBadge(bookmark.category),
                      const Spacer(),
                      Text(
                        _formatDate(bookmark.savedAt),
                        style: AppFontStyle.text_11_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookmark.content,
                    style: AppFontStyle.text_13_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textClr,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageTile(
    AiMessageModel message,
    ConversationMemoryController controller,
  ) {
    final isAssistant = message.role == MessageRole.assistant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppContainer(
        radius: 14,
        padding: const EdgeInsets.all(12),
        color: isAssistant
            ? AppColors.white
            : AppColors.buttonClr2.withValues(alpha: 0.05),
        borderColor: AppColors.borderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAssistant ? Icons.auto_awesome : Icons.person,
                  size: 16,
                  color: isAssistant
                      ? AppColors.buttonClr2
                      : AppColors.textLightClr,
                ),
                const SizedBox(width: 6),
                Text(
                  isAssistant ? AppConstants.aiAssistantDisplayName : 'You',
                  style: AppFontStyle.text_12_600(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: isAssistant
                        ? AppColors.buttonClr2
                        : AppColors.textClr,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(message.timestamp),
                  style: AppFontStyle.text_10_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                ),
                if (isAssistant) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (controller.isBookmarked(message.id)) {
                        controller.removeBookmark(message.id);
                      } else {
                        controller.bookmarkMessage(message);
                      }
                    },
                    child: Icon(
                      controller.isBookmarked(message.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 18,
                      color: controller.isBookmarked(message.id)
                          ? AppColors.buttonClr2
                          : AppColors.textLightClr,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.content,
              style: AppFontStyle.text_13_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textClr,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    String label;
    switch (category) {
      case 'nutrition':
        color = AppColors.green;
        label = 'Nutrition';
        break;
      case 'exercise':
        color = const Color(0xFF0066CC);
        label = 'Exercise';
        break;
      case 'medical':
        color = AppColors.orangeClr;
        label = 'Medical';
        break;
      case 'growth':
        color = AppColors.purpleClr;
        label = 'Growth';
        break;
      default:
        color = AppColors.buttonClr2;
        label = 'General';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppFontStyle.text_10_400(
          fontFamily: AppFontFamily.gilroySemiBold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppFontStyle.text_16_600(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: AppColors.textLightClr,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFontStyle.text_13_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
