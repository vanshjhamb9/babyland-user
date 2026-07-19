import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../core/constants/app_constants.dart';
import '../models/smart_post_model.dart';

/// A community post card with AI recommendation badge.
class SmartPostCard extends StatefulWidget {
  final SmartPostModel post;

  const SmartPostCard({super.key, required this.post});

  @override
  State<SmartPostCard> createState() => _SmartPostCardState();
}

class _SmartPostCardState extends State<SmartPostCard> {
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _likeCount = widget.post.likes;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return AppContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      borderColor: AppColors.borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.buttonClr2.withValues(alpha: 0.15),
                child: Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : '?',
                  style: AppFontStyle.text_14_600(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.buttonClr2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: AppFontStyle.text_13_600(
                        fontFamily: AppFontFamily.gilroySemiBold,
                      ),
                    ),
                    Text(
                      _formatTime(post.createdAt),
                      style: AppFontStyle.text_11_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textLightClr,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isRecommended)
                _buildBadge(
                    '${AppConstants.aiAssistantDisplayName} Pick',
                    AppColors.buttonClr2),
              if (post.isTrending)
                _buildBadge('Trending', AppColors.buttonClr1),
              if (post.relevantWeek != null)
                _buildBadge('Week ${post.relevantWeek}', AppColors.green),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            post.title,
            style: AppFontStyle.text_15_600(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: AppColors.textClr,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          Text(
            post.content,
            style: AppFontStyle.text_13_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textLightClr,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          if (post.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '#$tag',
                    style: AppFontStyle.text_11_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: const Color(0xFF0066CC),
                    ),
                  ),
                );
              }).toList(),
            ),
          if (post.tags.isNotEmpty) const SizedBox(height: 10),

          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (_liked) {
                      _liked = false;
                      _likeCount = (_likeCount > 0) ? _likeCount - 1 : 0;
                    } else {
                      _liked = true;
                      _likeCount += 1;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: _liked ? AppColors.red : AppColors.textLightClr,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_likeCount',
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.textLightClr,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.comments}',
                style: AppFontStyle.text_12_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textLightClr,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.bookmark_border,
                size: 18,
                color: AppColors.textLightClr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
