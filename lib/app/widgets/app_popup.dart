import 'package:babyland/main.dart';
import 'package:flutter/material.dart';

class AppPopUp{
  static void showToast({
        required String message,
        Color bgColor = Colors.black,
        Color lineColor = Colors.green,
        Duration duration = const Duration(seconds: 2),
      }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    OverlayState? overlay;
    try {
      overlay = Navigator.of(context, rootNavigator: true).overlay;
    } catch (_) {
      return;
    }
    if (overlay == null) return;

    late final OverlayEntry overlayEntry;
    var removed = false;

    void safeRemove() {
      if (removed) return;
      removed = true;
      try {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      } catch (_) {}
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 15,
          left: 14,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: AnimatedSlide(
              duration: const Duration(seconds: 2),
              offset: const Offset(0, -0.1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      overlay.insert(overlayEntry);
    } catch (_) {
      return;
    }

    Future.delayed(duration, safeRemove);
  }

}
