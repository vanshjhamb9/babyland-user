import 'package:flutter/material.dart';

/// Single global navigator for [MaterialApp] and session invalidation (401)
/// without importing `main.dart` (avoids circular imports).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
