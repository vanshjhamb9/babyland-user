import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common_profile_header/get_user_controller.dart';
import '../theme/app_colors.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';
import 'container.dart';
import 'user_avatar.dart';
import 'package:intl/intl.dart';
import 'package:babyland/core/moderation/ugc_moderation_actions.dart';

class CommunityPostCardWidget extends StatelessWidget {
  final dynamic post;
  final String? myUserId;
  final bool isLikedByMe;
  final bool isSavedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onSaveTap;
  /// Called after a successful local block so parents can refresh/filter.
  final VoidCallback? onUserBlocked;

  const CommunityPostCardWidget({
    super.key,
    required this.post,
    required this.myUserId,
    required this.isLikedByMe,
    required this.isSavedByMe,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onSaveTap,
    this.onUserBlocked,
  });

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final time = DateFormat('hh:mm a').format(date);
      final day = date.day;
      final month = DateFormat('MMMM').format(date);
      final year = date.year;
      return "$time. $month $day, $year";
    } catch (e) {
      return dateStr;
    }
  }

  String? get _authorId => post?.userId?.sId?.toString();
  String? get _postId => post?.sId?.toString();
  bool get _isOwnPost =>
      myUserId != null &&
      _authorId != null &&
      myUserId == _authorId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AppContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Consumer<GetUserProvider>(
                  builder: (context, userProvider, _) {
                    final isMe = myUserId != null &&
                        post?.userId?.sId?.toString() == myUserId;
                    final avatarUrl = post?.userId?.profilePicture ??
                        (isMe
                            ? userProvider
                                .userData?.data?.user?.user?.profilePicture
                            : null);
                    return UserAvatar(
                      size: 50,
                      imageUrl: avatarUrl,
                      name: post?.userId?.name,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post?.userId?.name ?? "",
                        style: AppFontStyle.text_18_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                        ),
                      ),
                      Text(
                        "@${post?.userId?.name ?? ""}",
                        style: AppFontStyle.text_16_400(
                          fontFamily: AppFontFamily.gilroyRegular,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isOwnPost)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'report') {
                        final postId = _postId;
                        if (postId == null || postId.isEmpty) return;
                        await showReportContentSheet(
                          context,
                          targetType: 'post',
                          targetId: postId,
                        );
                      } else if (value == 'block') {
                        final authorId = _authorId;
                        if (authorId == null || authorId.isEmpty) return;
                        final blocked = await confirmAndBlockUser(
                          context,
                          userId: authorId,
                          userName: post?.userId?.name?.toString(),
                        );
                        if (blocked) onUserBlocked?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'report',
                        child: Text('Report'),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Text('Block user'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post?.message ?? "",
              maxLines: 5,
              style: AppFontStyle.text_14_400(
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
            if (post?.hashtags != null && (post!.hashtags as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                (post!.hashtags as List).join(" "),
                style: AppFontStyle.text_14_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: onLikeTap,
                  child: Icon(
                    isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    color: isLikedByMe ? AppColors.red : AppColors.textLightClr,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  post?.likes?.length.toString() ?? "0",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onCommentTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      const SizedBox(width: 4),
                      Text(
                        post?.commentsCount?.toString() ?? "0",
                        style: AppFontStyle.text_14_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onSaveTap,
                  child: Icon(
                    isSavedByMe ? Icons.bookmark : Icons.bookmark_border,
                    color: isSavedByMe ? AppColors.buttonClr1 : AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post?.createdAt != null
                  ? formatDate(post?.createdAt ?? "")
                  : "",
              style: AppFontStyle.text_14_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textLightClr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
