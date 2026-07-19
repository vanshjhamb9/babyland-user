import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import '../../controller/group_controller/group_controller.dart';
import 'group_posts_screen.dart';

class GroupListView extends StatefulWidget {
  const GroupListView({super.key});

  @override
  State<GroupListView> createState() => _GroupListViewState();
}

class _GroupListViewState extends State<GroupListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupController>().fetchMyGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupController>(
      builder: (context, provider, child) {
        if (provider.isLoadingGroups) {
          return Center(child: CircularProgressIndicator(color: AppColors.buttonClr1));
        }
        
        if (provider.groupsError != null) {
          return Center(
            child: Text(
              provider.groupsError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final groups = provider.groups;

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group,
                  size: 64,
                  color: AppColors.textLightClr.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "You're not part of any group yet",
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
            await provider.fetchMyGroups();
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupPostsScreen(
                        groupId: group.sId ?? "",
                        groupName: group.name ?? "Group",
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.buttonClr2.withValues(alpha: 0.15),
                        backgroundImage: group.image != null && group.image!.isNotEmpty
                            ? NetworkImage(group.image!)
                            : null,
                        child: group.image == null || group.image!.isEmpty
                            ? Text(
                                group.name?.isNotEmpty == true ? group.name![0].toUpperCase() : 'G',
                                style: AppFontStyle.text_20_600(
                                  fontFamily: AppFontFamily.gilroySemiBold,
                                  color: AppColors.buttonClr2,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name ?? "Unknown Group",
                              style: AppFontStyle.text_18_500(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: AppColors.textClr,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group.description ?? "No description available.",
                              style: AppFontStyle.text_14_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.textLightClr,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (group.membersCount != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.people, size: 14, color: AppColors.buttonClr1),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.membersCount} members',
                                    style: AppFontStyle.text_12_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textLightClr,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLightClr),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
