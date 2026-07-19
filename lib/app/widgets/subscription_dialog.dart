import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

/// Shows a subscription dialog when subscription is required.
///
/// This dialog appears when a user tries to access a premium feature
/// without an active subscription.
class SubscriptionDialog extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const SubscriptionDialog({
    super.key,
    this.message,
    this.onDismiss,
  });

  /// Returns true if [message] indicates a subscription/plan restriction from the API.
  static bool isSubscriptionRequiredMessage(String? message) {
    if (message == null || message.isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('subscription') ||
        lower.contains('plan does not include') ||
        lower.contains('your plan') ||
        lower.contains('premium') ||
        lower.contains('not purchased') ||
        lower.contains('requires subscription') ||
        lower.contains('requires an active subscription') ||
        lower.contains('upgrade') ||
        lower.contains('purchase') ||
        lower.contains('no_subscription') ||
        lower.contains('feature_not_included');
  }

  /// If [message] is subscription-related, shows a toast first, then the subscription dialog.
  /// Returns true so caller skips generic toast. Otherwise returns false.
  static Future<bool> showDialogIfSubscriptionRequired(String? message) async {
    if (!isSubscriptionRequiredMessage(message)) return false;
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    final displayMessage = message ?? 'This feature requires an active subscription.';
    AppPopUp.showToast(
      message: displayMessage,
      duration: const Duration(seconds: 2),
    );
    await show(context, message: displayMessage);
    return true;
  }

  /// Shows the subscription dialog and navigates to subscription screen on "Subscribe" tap.
  static Future<void> show(
    BuildContext context, {
    String? message,
    VoidCallback? onDismiss,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionDialog(
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Navigates to the appropriate subscription screen based on user's stage.
  static Future<void> navigateToSubscriptionScreen(BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog
    Navigator.of(context).pushNamed(AppRoutes.subscriptionScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Premium Feature',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Message
            Text(
              message ??
                  'This feature requires an active subscription. Subscribe now to unlock premium features!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Cancel/Dismiss button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Subscribe button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      await navigateToSubscriptionScreen(context);
                      onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Subscribe Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
