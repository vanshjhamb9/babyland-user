// ignore_for_file: public_member_api_docs

/// Fires after access tokens are rotated so UI/runtime layers can reconcile without
/// importing [Provider] from the networking stack.
class TokenRefreshReconcileHook {
  TokenRefreshReconcileHook._();
  static final TokenRefreshReconcileHook instance = TokenRefreshReconcileHook._();

  void Function()? onAccessTokenRefreshed;

  void notifyAccessTokenRefreshed() => onAccessTokenRefreshed?.call();

  void clear() => onAccessTokenRefreshed = null;
}
