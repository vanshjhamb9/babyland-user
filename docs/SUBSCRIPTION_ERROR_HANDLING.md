# Subscription Error Handling

This document explains how subscription errors are handled in the app and how to use the subscription dialog.

## Overview

When a user tries to access a premium feature without an active subscription, the app automatically detects the error and shows a subscription dialog that allows them to navigate to the subscription screen.

## How It Works

1. **Error Detection**: The `ErrorHandler` automatically detects subscription-related errors from API responses (status codes 400 or 403 with subscription-related error codes/messages).

2. **Exception Type**: Subscription errors are converted to `SubscriptionException` which can be caught and handled.

3. **UI Display**: The `SubscriptionDialog` widget shows a user-friendly dialog with options to subscribe or dismiss.

## Usage

### Automatic Handling

The error handler automatically converts subscription errors to `SubscriptionException`. You just need to catch and display them:

```dart
import 'package:babyland/core/utils/error_ui_handler.dart';
import 'package:babyland/core/error/app_exceptions.dart';

try {
  // Your API call that might require subscription
  await somePremiumFeature();
} on SubscriptionException catch (e) {
  // Show subscription dialog
  await ErrorUIHandler.handleError(context, e);
} on AppException catch (e) {
  // Handle other errors
  showError(e.message);
}
```

### Manual Handling

You can also manually show the subscription dialog:

```dart
import 'package:babyland/app/widgets/subscription_dialog.dart';

// Show subscription dialog
await SubscriptionDialog.show(
  context,
  message: 'This feature requires a premium subscription.',
);
```

### In Service Classes

When using the new architecture services, subscription errors are automatically converted:

```dart
try {
  final result = await sl.someService.premiumFeature();
} catch (e) {
  final error = ErrorHandler.handle(e);
  if (error is SubscriptionException) {
    // Show subscription dialog
    await ErrorUIHandler.handleError(context, error);
    return;
  }
  // Handle other errors
}
```

## Error Detection

The error handler detects subscription errors by checking:

- **Status Code**: 400 or 403
- **Error Codes**: Contains "subscription", "premium", "plan", "purchase", "upgrade"
- **Error Messages**: Contains "subscription", "premium", "not purchased", "requires subscription"

## Subscription Dialog

The subscription dialog:
- Shows a premium icon
- Displays a customizable message
- Provides "Maybe Later" and "Subscribe Now" buttons
- Automatically navigates to the correct subscription screen based on user's stage (prepregnancy, pregnancy, postpregnancy)

## Navigation

The dialog automatically navigates to the appropriate subscription screen:
- **Pre-Pregnancy**: `AppRoutes.prePreSubscriptionView`
- **Pregnancy**: `AppRoutes.preSubscriptionView`
- **Post-Pregnancy**: `AppRoutes.postPreSubscriptionView`

## Example: Complete Error Handling

```dart
Future<void> accessPremiumFeature() async {
  try {
    final result = await apiClient.post('/premium-feature');
    // Handle success
  } catch (e) {
    final error = ErrorHandler.handle(e);
    
    if (error is SubscriptionException) {
      // Show subscription dialog
      await ErrorUIHandler.handleError(context, error);
    } else if (error is NetworkException) {
      // Show network error
      showError('No internet connection');
    } else if (error is AuthException) {
      // Redirect to login
      Navigator.pushNamed(context, '/login');
    } else {
      // Show generic error
      showError(error.message);
    }
  }
}
```

## Testing

To test subscription error handling:

1. Make an API call to a premium feature without an active subscription
2. The backend should return a 400/403 error with subscription-related message
3. The app should automatically show the subscription dialog
4. Tapping "Subscribe Now" should navigate to the subscription screen

## Notes

- The subscription dialog is non-dismissible (user must choose an option)
- The dialog automatically determines the correct subscription screen based on user's current stage
- All subscription errors are logged for debugging purposes
