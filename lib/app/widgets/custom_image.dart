import 'dart:io';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';


class CustomImage extends StatelessWidget {
  final String path;
  final double? w;
  final double? h;
  final Color? color;
  final Color? errorPlaceholderClr;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double scale;
  final Widget? shimmerChild;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  const CustomImage({
    super.key,
    required this.path,
    this.w,
    this.h,
    this.color,
    this.errorPlaceholderClr,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.scale = 1.0,
    this.errorWidget,
    this.shimmerChild,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: _getImageWidget(),
    );
  }

  Widget _getImageWidget() {
    if (_isNetworkImage(path)) {
      return _loadNetworkImage(path);
    } else if (_isAssetImage(path)) {
      return _loadAssetImage(path);
    } else if (_isFileImage(path)) {
      return _loadFileImage(path);
    } else {
      return _errorPlaceholder();
    }
  }

  Widget _loadNetworkImage(String url) {
    return _isSvg(url)
        ? SvgPicture.network(
      url,
      width: w,
      height: h,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      placeholderBuilder: (context) => _loading(),
    )
        : CachedNetworkImage(
      imageUrl: url,
      width: w,
      height: h,
      fit: fit,
      scale: scale,
      errorWidget: errorWidget ?? (context, url, error) => _errorPlaceholder(),
      placeholder: (context, url) => _loading(),
    );
  }

  Widget _loadAssetImage(String path) {
    return _isSvg(path)
        ? SvgPicture.asset(
      path,
      width: w,
      height: h,
      fit: BoxFit.contain,
      color: color,
      // colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      placeholderBuilder: (context) => _loading(),
    )
        : Image.asset(
      path,
      width: w,
      height: h,
      fit: fit,
      scale: scale,
      errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
    );
  }

  Widget _loadFileImage(String path) {
    return _isSvg(path)
        ? SvgPicture.file(
      File(path),
      width: w,
      height: h,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => _loading(),
    )
        : Image.file(
      File(path),
      width: w,
      height: h,
      fit: fit,
      scale: scale,
      errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
    );
  }

  bool _isNetworkImage(String path) {
    return path.startsWith("http") || path.startsWith("https");
  }

  bool _isAssetImage(String path) {
    return path.startsWith("assets/");
  }

  bool _isFileImage(String path) {
    return File(path).existsSync();
  }

  bool _isSvg(String path) {
    return path.toLowerCase().endsWith(".svg");
  }

  Widget _errorPlaceholder() {
    return Container(
      width: w,
      height: h,
      color: errorPlaceholderClr ?? AppColors.greyLight.withOpacity(0.06),
      child: Icon(Icons.broken_image, color: AppColors.buttonClr2
          .withOpacity(0.5)),
    );
  }


  Widget _loading(){
    return Shimmer.fromColors(
        baseColor: AppColors.buttonClr2.withAlpha(100),
        highlightColor: AppColors.buttonClr2.withAlpha(100),
        child: shimmerChild ??  Container(color: AppColors.buttonClr2.withAlpha(100),));
  }


}
