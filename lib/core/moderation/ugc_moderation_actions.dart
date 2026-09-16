import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/core/moderation/blocked_users_store.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';

const _reportReasons = <String>[
  'Spam',
  'Harassment',
  'Hate speech',
  'Sexual content',
  'Misinformation',
  'Other',
];

Future<void> showReportContentSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) async {
  String selected = _reportReasons.first;
  final notesController = TextEditingController();
  var submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Report content',
                  style: AppFontStyle.text_18_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reports are reviewed by our team. Misuse may lead to account action.',
                  style: AppFontStyle.text_14_400(
                    color: AppColors.textLightClr,
                    fontFamily: AppFontFamily.gilroyRegular,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reportReasons.map((reason) {
                    final selectedChip = selected == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: selectedChip,
                      onSelected: (_) => setModalState(() => selected = reason),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Optional details',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Button(
                  onTap: submitting
                      ? null
                      : () async {
                          setModalState(() => submitting = true);
                          try {
                            final res = await repository.reportContent({
                              'targetType': targetType,
                              'targetId': targetId,
                              'reason': selected.toLowerCase(),
                              if (notesController.text.trim().isNotEmpty)
                                'notes': notesController.text.trim(),
                            });
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            AppPopUp.showToast(
                              message: res.success == true
                                  ? 'Thanks. We received your report.'
                                  : (res.message ??
                                      'Could not submit report. Try again.'),
                            );
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setModalState(() => submitting = false);
                            AppPopUp.showToast(
                              message:
                                  'Could not submit report. Please try again.',
                            );
                          }
                        },
                  child: Text(
                    submitting ? 'Submitting…' : 'Submit report',
                    style: AppFontStyle.text_16_400(
                      color: AppColors.white,
                      fontFamily: AppFontFamily.gilroyBold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  notesController.dispose();
}

Future<bool> confirmAndBlockUser(
  BuildContext context, {
  required String userId,
  String? userName,
}) async {
  final name = (userName != null && userName.trim().isNotEmpty)
      ? userName.trim()
      : 'this user';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Block user?'),
      content: Text(
        'Block $name? Their posts will be removed from your feed immediately. '
        'Our team is also notified.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  // Instant local removal even if the API is temporarily unavailable.
  await BlockedUsersStore.addLocal(userId);
  try {
    final res = await repository.blockUser(userId);
    if (res.success == false) {
      AppPopUp.showToast(
        message: res.message ??
            'Blocked locally. Server sync may retry later.',
      );
    } else {
      AppPopUp.showToast(message: 'User blocked.');
    }
  } catch (_) {
    AppPopUp.showToast(
      message: 'Blocked locally. We will sync when online.',
    );
  }
  return true;
}
