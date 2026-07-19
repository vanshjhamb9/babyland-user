import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:flutter/material.dart';

/// Consistent elevated card for postpartum dashboard sections.
class PostpartumDashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const PostpartumDashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
          child: Ink(
            decoration: DashboardTheme.cardDecoration(),
            child: content,
          ),
        ),
      ),
    );
  }
}
