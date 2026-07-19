import 'package:flutter/material.dart';
import '../../../app/constants/images.dart';

/// A circular avatar for the IRA bot.
class IraAvatar extends StatelessWidget {
  final double size;

  const IraAvatar({
    super.key,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(ImageConstants.iraAvatar),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
