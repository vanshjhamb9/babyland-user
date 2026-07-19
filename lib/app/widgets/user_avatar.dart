import 'package:babyland/app/data/network/end_points.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? stage;
  final double size;

  const UserAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.name,
    this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(imageUrl);
    final initial = _initialFromName(name);
    final backgroundColor = _backgroundColor(name: name, stage: stage);

    if (resolvedUrl != null) {
      return ClipOval(
        child: CustomImage(
          h: size,
          w: size,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(1000),
          path: resolvedUrl,
          errorWidget: (_, __, ___) => _initialAvatar(initial, backgroundColor),
        ),
      );
    }

    return ClipOval(child: _initialAvatar(initial, backgroundColor));
  }

  Widget _initialAvatar(String initial, Color backgroundColor) {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppFontStyle.text_16_600(
          color: AppColors.white,
          fontFamily: AppFontFamily.gilroySemiBold,
        ).copyWith(fontSize: size * 0.44),
      ),
    );
  }

  String _initialFromName(String? value) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) return '?';
    return clean[0].toUpperCase();
  }

  String? _resolveImageUrl(String? value) {
    final image = (value ?? '').trim();
    if (image.isEmpty) return null;
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    final uri = Uri.parse(EndPoints.baseUrl);
    final rootUrl = '${uri.scheme}://${uri.host}';
    String cleanPath = image.replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    return '$rootUrl/$cleanPath';
  }

  Color _backgroundColor({String? name, String? stage}) {
    final seed = '${name ?? ''}|${stage ?? ''}';
    final hash = seed.hashCode.abs();
    const palette = [
      Color(0xFFE38B8B),
      Color(0xFF8BA9E3),
      Color(0xFF8BCFA7),
      Color(0xFFE3B98B),
      Color(0xFFAA8BE3),
      Color(0xFF8BD9E3),
    ];
    return palette[hash % palette.length];
  }
}
