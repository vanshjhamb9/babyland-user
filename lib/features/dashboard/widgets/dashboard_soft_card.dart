import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:flutter/material.dart';

class DashboardSoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const DashboardSoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DashboardTheme.cardPadding),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: double.infinity,
      padding: padding,
      decoration: DashboardTheme.cardDecoration(color: color),
      child: child,
    );
    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
        child: inner,
      ),
    );
  }
}
