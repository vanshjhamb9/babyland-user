import 'dart:io';

import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Shows a bottom sheet to pick a profile photo from gallery or camera,
/// then uploads it permanently via the profile-update API.
Future<void> showProfilePhotoPicker(
  BuildContext context, {
  bool popOnSuccess = false,
}) async {
  final provider = context.read<GetUserProvider>();
  if (provider.updateProfileData?.status == ApiStatus.LOADING) {
    AppPopUp.showToast(
      message: 'Photo upload already in progress',
      lineColor: AppColors.red,
    );
    return;
  }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Photo',
              style: AppFontStyle.text_16_600(
                fontFamily: AppFontFamily.gilroySemiBold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  if (provider.updateProfileData?.status == ApiStatus.LOADING) {
    AppPopUp.showToast(
      message: 'Photo upload already in progress',
      lineColor: AppColors.red,
    );
    return;
  }

  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 800,
    imageQuality: 75,
  );
  if (picked == null || !context.mounted) return;

  if (provider.updateProfileData?.status == ApiStatus.LOADING) {
    AppPopUp.showToast(
      message: 'Photo upload already in progress',
      lineColor: AppColors.red,
    );
    return;
  }

  await provider.uploadProfilePicture(
    File(picked.path),
    popOnSuccess: popOnSuccess,
  );
}

/// Inline camera-badge overlay for profile avatars.
class ProfilePhotoBadge extends StatelessWidget {
  final double size;

  const ProfilePhotoBadge({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.buttonClr,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.camera_alt, size: size * 0.5, color: Colors.white),
    );
  }
}
