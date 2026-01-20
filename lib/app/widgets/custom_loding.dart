import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final bool showBackground;

  const CustomLoader({
    Key? key,
    this.size = 150,
    this.backgroundColor,
    this.showBackground = true,
  }) : super(key: key);

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.showBackground
          ? (widget.backgroundColor ?? Colors.white.withOpacity(0.9))
          : Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: CustomImage(path:
              ImageConstants.loadingBabyDear,
              w: widget.size,
              h: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}
