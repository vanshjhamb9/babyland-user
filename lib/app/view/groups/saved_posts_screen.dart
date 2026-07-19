import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import '../../controller/group_controller/group_controller.dart';
import '../../common_profile_header/get_user_controller.dart';
import '../../widgets/community_post_card_widget.dart';
import '../../widgets/custom_appbar.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupController>().fetchSavedPosts();
    });
  }

  bool _isLikedByMe(dynamic post, String? myUserId) {
    if (myUserId == null || myUserId.isEmpty) return false;
    final likes = post?.likes as List?;
    if (likes == null || likes.isEmpty) return false;
    for (final e in likes) {
      if (e == myUserId) return true;
      if (e is Map) {
        final id = e['_id']?.toString() ?? e['userId']?.toString();
        if (id == myUserId) return true;
      }
    }
    return false;
  }

  Future<void> _openCommentSheet(GroupController provider, dynamic post, String? myUserId) async {
    final postId = post?.sId?.toString();
    if (postId == null || postId.isEmpty) return;
    
    final textCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add a comment',
                style: AppFontStyle.text_18_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final msg = textCtrl.text;
                  Navigator.pop(ctx);
                  await provider.addComment(postId, msg, myUserId, isSavedScreen: true);
                },
                child: const Text('Post comment'),
              ),
            ],
          ),
        );
      },
    );
    textCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<GetUserProvider>();
    final myUserId = userProvider.userData?.data?.user?.user?.sId;

    return Scaffold(
      appBar: CustomAppBar(
        isLeading: true,
        title: Text(
          "Saved Posts",
          style: AppFontStyle.text_20_400(
            color: AppColors.textClr,
            fontFamily: AppFontFamily.gilroySemiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<GroupController>(
        builder: (context, provider, child) {
          if (provider.isLoadingSaved) {
            return Center(child: CircularProgressIndicator(color: AppColors.buttonClr1));
          }

          final posts = provider.savedPosts;

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppColors.textLightClr.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No saved posts yet",
                    style: AppFontStyle.text_16_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textLightClr,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchSavedPosts();
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                
                return CommunityPostCardWidget(
                  post: post,
                  myUserId: myUserId,
                  isLikedByMe: _isLikedByMe(post, myUserId),
                  isSavedByMe: provider.isPostSavedLocally(post.sId ?? ""),
                  onLikeTap: () {
                    provider.toggleLike(post.sId!, myUserId, isSavedScreen: true);
                  },
                  onCommentTap: () {
                    _openCommentSheet(provider, post, myUserId);
                  },
                  onSaveTap: () {
                    provider.toggleSave(post.sId!, isSavedScreen: true);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
