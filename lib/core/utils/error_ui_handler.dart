import 'package:babyland/app/widgets/subscription_dialog.dart';
import 'package:babyland/core/error/app_exceptions.dart';
import 'package:flutter/material.dart';

/// Utility class for handling errors in the UI.
/// 
/// Provides methods to show appropriate UI feedback for different error types,
/// including automatic subscription dialog display for subscription errors.
class ErrorUIHandler {
  ErrorUIHandler._();

  /// Handles an error and shows appropriate UI feedback.
  /// 
  /// - For [SubscriptionException]: Shows subscription dialog
  /// - For other errors: Can be extended to show other dialogs/toasts
  static Future<void> handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onDismiss,
  }) async {
    if (error is SubscriptionException) {
      await SubscriptionDialog.show(
        context,
        message: error.message,
        onDismiss: onDismiss,
      );
      return;
    }

    // For other error types, you can add additional handling here
    // For example, show a generic error dialog or toast
  }

  /// Checks if an error is a subscription error and handles it.
  /// 
  /// Returns true if the error was handled (subscription error),
  /// false otherwise.
  static Future<bool> handleIfSubscriptionError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onDismiss,
  }) async {
    if (error is SubscriptionException) {
      await SubscriptionDialog.show(
        context,
        message: error.message,
        onDismiss: onDismiss,
      );
      return true;
    }
    return false;
  }

  /// One-off snackbar for API / unexpected failures (avoids duplicate dialogs).
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade800 : Colors.black87,
      ),
    );
  }
}
