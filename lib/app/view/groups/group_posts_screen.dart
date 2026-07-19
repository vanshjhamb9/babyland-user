import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import '../../controller/group_controller/group_controller.dart';
import '../../common_profile_header/get_user_controller.dart';
import '../../widgets/community_post_card_widget.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_textform_field.dart';

class GroupPostsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupPostsScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupPostsScreen> createState() => _GroupPostsScreenState();
}

class _GroupPostsScreenState extends State<GroupPostsScreen> {
  late Set<String> _savedPostIds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupController>().fetchGroupPosts(widget.groupId);
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
                  await provider.addComment(postId, msg, myUserId, groupId: widget.groupId);
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

  void _showPostMessageDialog(BuildContext context, GroupController provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              AppContainer(
                radius: 30,
                padding: const EdgeInsets.all(12),
                gradient: AppColors.buttonClr,
                child: Icon(Icons.message, color: AppColors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                "Post Message",
                style: AppFontStyle.text_18_600(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Share in ${widget.groupName}",
                style: AppFontStyle.text_14_400(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: provider.createPostController,
                height: 150,
                maxLines: 5,
                minLines: 5,
                borderColor: AppColors.borderColor,
                hintText: "Type your message here...",
                textInputType: TextInputType.multiline,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.createPostController.clear();
                Navigator.pop(dialogContext);
              },
              child: Text(
                "Cancel",
                style: AppFontStyle.text_16_500(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            ),
            AppContainer(
              radius: 8,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              gradient: AppColors.buttonClr,
              child: InkWell(
                onTap: () {
                  final message = provider.createPostController.text.trim();
                  if (message.isNotEmpty) {
                    provider.createPostController.clear();
                    provider.createGroupPost(widget.groupId, message);
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  "Post",
                  style: AppFontStyle.text_16_600(
                    color: AppColors.white,
                    fontFamily: AppFontFamily.gilroySemiBold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<GetUserProvider>();
    final myUserId = userProvider.userData?.data?.user?.user?.sId;

    return Scaffold(
      appBar: CustomAppBar(
        isLeading: true,
        title: Text(
          widget.groupName,
          style: AppFontStyle.text_20_400(
            color: AppColors.textClr,
            fontFamily: AppFontFamily.gilroySemiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<GroupController>(
        builder: (context, provider, child) {
          if (provider.isLoadingPosts) {
            return Center(child: CircularProgressIndicator(color: AppColors.buttonClr1));
          }

          if (provider.postsError != null) {
            return Center(
              child: Text(
                provider.postsError!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final posts = provider.groupPosts;

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 64,
                    color: AppColors.textLightClr.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No posts yet in this group",
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
              await provider.fetchGroupPosts(widget.groupId);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                
                // Currently, save state is typically kept locally as a set in CommunityView.
                // But user wants to save to backend /posts/:id/save.
                // I'll call toggleSave API for "isSavedByMe". But for UI sync, we might not have a saved boolean in post models.
                // Assuming backend /posts/saved handles it, and we might fetch it or just use backend's saveGroupPost endpoint.
                
                return CommunityPostCardWidget(
                  post: post,
                  myUserId: myUserId,
                  isLikedByMe: _isLikedByMe(post, myUserId),
                  isSavedByMe: provider.isPostSavedLocally(post.sId ?? ""),
                  onLikeTap: () {
                    provider.toggleLike(post.sId!, myUserId, groupId: widget.groupId);
                  },
                  onCommentTap: () {
                    _openCommentSheet(provider, post, myUserId);
                  },
                  onSaveTap: () {
                    provider.toggleSave(post.sId!, groupId: widget.groupId);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: InkWell(
        onTap: () {
          _showPostMessageDialog(context, context.read<GroupController>());
        },
        child: AppContainer(
          gradient: AppColors.buttonClr,
          radius: 100,
          height: 54,
          width: 54,
          child: Center(
            child: Icon(
              Icons.add,
              color: AppColors.white,
              size: 26,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
