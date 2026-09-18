import 'dart:async';
import 'dart:io';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/core/entitlement/subscription_entitlement.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:babyland/core/subscription/apple_iap_service.dart';
import 'package:babyland/core/subscription/subscription_payment_coordinator.dart';
import 'package:babyland/core/subscription/subscription_payment_parse.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/app_popup.dart';
import '../../../widgets/print.dart';
import 'model/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider() {
    setSelectedPlanIndex(0);
    touchActivity();
    onForeground();
    if (Platform.isIOS) {
      unawaited(_initAppleIap());
    }
  }

  final AppleIapService appleIap = AppleIapService();
  bool _appleIapBusy = false;
  bool get appleIapBusy => _appleIapBusy || appleIap.purchaseInFlight;
  String? get appleStorePriceLabel => appleIap.storePriceLabel;

  Future<void> _initAppleIap() async {
    await appleIap.init(
      onPurchaseVerified: _verifyApplePurchase,
      onError: (message) {
        AppPopUp.showToast(message: message);
        _appleIapBusy = false;
        notifyListeners();
      },
      onPurchaseUiSettled: () {
        _appleIapBusy = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<bool> _verifyApplePurchase(PurchaseDetails purchase) async {
    final receipt = purchase.verificationData.serverVerificationData;
    final local = purchase.verificationData.localVerificationData;
    final payload = <String, dynamic>{
      'platform': 'ios',
      'productId': purchase.productID,
      'transactionId': purchase.purchaseID,
      'receiptData': receipt.isNotEmpty ? receipt : local,
      'localVerificationData': local,
      'source': purchase.verificationData.source,
    };
    pt('[APPLE_IAP] verifying with backend product=${purchase.productID}');
    final result = await repository.verifyAppleSubscription(payload);
    if (result.success != true) {
      AppPopUp.showToast(
        message: result.message ?? 'Could not activate subscription.',
      );
      return false;
    }
    await refreshEntitlements(reason: 'apple_iap_verified', silent: true);
    if (canUsePremiumFeature) {
      AppPopUp.showToast(message: 'Subscription activated.');
    }
    return canUsePremiumFeature || result.success == true;
  }

  /// iOS: native StoreKit sheet. Android: PhonePe checkout.
  Future<bool> startUpgradeCheckout(
    SubscriptionPaymentCoordinator coordinator,
  ) async {
    if (Platform.isIOS) {
      return startAppleIapCheckout();
    }
    return startPhonePeSubscriptionCheckout(coordinator);
  }

  Future<bool> startAppleIapCheckout() async {
    if (!Platform.isIOS) return false;
    if (canUsePremiumFeature) return true;
    _appleIapBusy = true;
    notifyListeners();
    final started = await appleIap.buyProMonthly();
    if (!started) {
      _appleIapBusy = false;
      notifyListeners();
      // lastError is already mapped (product missing vs StoreKit platform vs start).
      AppPopUp.showToast(
        message: appleIap.lastError ??
            'Could not start App Store purchase. Please try again.',
      );
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> restoreApplePurchases() async {
    if (!Platform.isIOS) return;
    _appleIapBusy = true;
    notifyListeners();
    await appleIap.restorePurchases();
    await refreshEntitlements(reason: 'apple_iap_restore', silent: true);
    _appleIapBusy = false;
    notifyListeners();
    if (canUsePremiumFeature) {
      AppPopUp.showToast(message: 'Subscription restored.');
    } else {
      AppPopUp.showToast(message: 'No active subscription to restore.');
    }
  }

  DateTime? get subscriptionExpiresAtUtc =>
      _mySubscription?.data?.expiresAtUtc;

  /// Healthcare-grade: premium gates use [canUsePremiumFeature], not raw API alone.
  static const Duration entitlementStaleAfter = Duration(minutes: 3);
  static const Duration inactivityForcedRefreshAfter = Duration(minutes: 30);

  DateTime? _lastEntitlementSuccessUtc;
  DateTime? _lastForegroundUtc;
  DateTime? _lastUserInteractionUtc;
  bool _entitlementRefreshFailed = false;

  DateTime? get lastEntitlementVerifiedAtUtc => _lastEntitlementSuccessUtc;

  bool get isEntitlementSnapshotStale {
    final t = _lastEntitlementSuccessUtc;
    if (t == null) return true;
    return DateTime.now().toUtc().difference(t) > entitlementStaleAfter;
  }

  /// Server-verified subscription within TTL — use for premium content gates.
  bool get canUsePremiumFeature {
    if (_entitlementRefreshFailed) return false;
    final data = _mySubscription?.data;
    if (data == null) return false;
    if (isEntitlementSnapshotStale) return false;
    final tier = data.resolvedEntitlement;
    return tier == SubscriptionEntitlement.active ||
        tier == SubscriptionEntitlement.gracePeriod;
  }

  void touchActivity() {
    _lastUserInteractionUtc = DateTime.now().toUtc();
  }

  void onForeground() {
    _lastForegroundUtc = DateTime.now().toUtc();
  }

  bool shouldForceRefreshAfterLongInactivity() {
    final t = _lastUserInteractionUtc ?? _lastForegroundUtc;
    if (t == null) return true;
    return DateTime.now().toUtc().difference(t) >
        inactivityForcedRefreshAfter;
  }

  int selectedPlanIndex = 0;
  String selectedPlanID = "";
  String _planName = "";
  String get planName => _planName;

  /// Parsed from last successful `subscriptions/add` response (rupees).
  num? _lastSubscriptionCheckoutRupees;
  num? get lastSubscriptionCheckoutRupees => _lastSubscriptionCheckoutRupees;

  SubscriptionAddResponse? _lastSubscriptionAddResponse;
  SubscriptionAddResponse? get lastSubscriptionAddResponse =>
      _lastSubscriptionAddResponse;
  setPLanName(String name) {
    _planName = name;
    notifyListeners();
  }

  setSelectedPlanIndex(int index) {
    selectedPlanIndex = index;
    notifyListeners();
  }

  ApiResponse<GetAllPlansModel>? _allSubscription = ApiResponse.completed(null);
  ApiResponse<GetAllPlansModel>? get allSubscription => _allSubscription;

  List<Plans> get paidActivePlans {
    final plans = allSubscription?.data?.plans ?? <Plans>[];
    return plans.where((plan) {
      final price = plan.price ?? 0;
      return plan.isActive != false &&
          price > 0 &&
          (plan.sId?.isNotEmpty ?? false);
    }).toList();
  }

  void setAllSubscription(ApiResponse<GetAllPlansModel> response) {
    _allSubscription = response;
    notifyListeners();
  }

  Future<void> getSubscriptionPlanApi() async {
    notifyListeners();
    setAllSubscription(ApiResponse.loading());
    notifyListeners();

    await repository.getSubscriptionPlan().then((value) async {
      if (value.success == true) {
        setAllSubscription(ApiResponse.completed(value));
        final paidPlans = paidActivePlans;
        if (selectedPlanID.isEmpty && paidPlans.isNotEmpty) {
          selectedPlanID = paidPlans.first.sId ?? "";
          _planName = paidPlans.first.name ?? "";
        }
      }
      if (value.success == false) {
        AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setAllSubscription(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    });
  }

  ApiResponse<Subscription_Data_Model>? _mySubscription =
      ApiResponse.completed(null);
  ApiResponse<Subscription_Data_Model>? get mySubscription => _mySubscription;

  bool get hasActiveSubscription =>
      _mySubscription?.data?.hasActiveSubscription == true;

  void setMySubscription(ApiResponse<Subscription_Data_Model> response) {
    _mySubscription = response;
    notifyListeners();
  }

  Future<void> refreshEntitlements({
    String reason = 'unknown',
    bool silent = false,
  }) async {
    final token = await SecureStorage.getToken() ?? '';
    if (token.isEmpty) {
      AppAuditLog.instance.log(
        'entitlement_refresh_completed',
        component: 'SubscriptionProvider',
        reason: '${reason}_skipped_no_session',
        outcome: 'skipped',
      );
      return;
    }

    final sw = Stopwatch()..start();
    AppAuditLog.instance.log(
      'entitlement_refresh_started',
      component: 'SubscriptionProvider',
      reason: reason,
    );
    try {
      if (!silent) setMySubscription(ApiResponse.loading());
      final value = await repository.getMySubscription();
      setMySubscription(ApiResponse.completed(value));
      _lastEntitlementSuccessUtc = DateTime.now().toUtc();
      _entitlementRefreshFailed = false;
      AppAuditLog.instance.log(
        'entitlement_refresh_completed',
        component: 'SubscriptionProvider',
        reason: reason,
        durationMs: sw.elapsedMilliseconds,
        outcome: 'ok',
      );
    } catch (error, stackTrace) {
      pt("Error in refreshEntitlements: $error\n$stackTrace");
      _entitlementRefreshFailed = true;
      AppAuditLog.instance.log(
        'entitlement_refresh_completed',
        component: 'SubscriptionProvider',
        reason: reason,
        durationMs: sw.elapsedMilliseconds,
        outcome: 'error',
      );
      if (!silent) {
        setMySubscription(ApiResponse.error(error.toString()));
      }
    }
    notifyListeners();
  }

  Future<void> maybeRefreshIfStaleForPremiumNavigation({
    String reason = 'premium_nav',
  }) async {
    if (isEntitlementSnapshotStale) {
      await refreshEntitlements(reason: reason, silent: false);
    }
  }

  Future<void> tickForegroundTtlIfNeeded() async {
    if (isEntitlementSnapshotStale) {
      await refreshEntitlements(reason: 'ttl_foreground', silent: true);
    }
  }

  Future<void> refreshAfterLongInactivityIfNeeded() async {
    if (shouldForceRefreshAfterLongInactivity()) {
      await refreshEntitlements(reason: 'inactivity', silent: true);
      touchActivity();
    }
  }

  Future<void> getMySubscriptionApi({bool silent = false}) =>
      refreshEntitlements(reason: 'legacy_get_my_subscription', silent: silent);

  ApiResponse<CommonResponseModel>? _addSubscription =
      ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get addSubscription => _addSubscription;

  void setAddSubscription(ApiResponse<CommonResponseModel> response) {
    _addSubscription = response;
    notifyListeners();
  }

  String get selectedOrFirstPlanId {
    if (selectedPlanID.isNotEmpty) return selectedPlanID;
    if (paidActivePlans.isNotEmpty) {
      return paidActivePlans.first.sId ?? "";
    }
    return "";
  }

  Future<CommonResponseModel?> addSubscriptionPlanApi({
    String? planId,
    String? paymentMethod,
  }) async {
    notifyListeners();
    setAddSubscription(ApiResponse.loading());
    notifyListeners();
    final effectivePlanId =
        planId?.isNotEmpty == true ? planId! : selectedOrFirstPlanId;
    if (effectivePlanId.isEmpty) {
      const message = "Please select a subscription plan.";
      setAddSubscription(ApiResponse.error(message));
      AppPopUp.showToast(message: message);
      return null;
    }

    Map<String, dynamic> data = {
      "planId": effectivePlanId,
      "paymentMethod": paymentMethod ?? "PhonePe",
    };

    try {
      pt('[SUBSCRIPTION_PAYMENT] Creating subscription payment $data');
      final value = await repository.addSubscriptionPlan(data);
      if (value.success == true) {
        setAddSubscription(ApiResponse.completed(value));
      }
      if (value.success == false) {
        setAddSubscription(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
      return value;
    } catch (error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setAddSubscription(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
      return null;
    }
  }

  Future<bool> startPhonePeSubscriptionCheckout(
    SubscriptionPaymentCoordinator coordinator,
  ) async {
    coordinator.beginCheckout();
    _lastSubscriptionCheckoutRupees = null;
    _lastSubscriptionAddResponse = null;
    notifyListeners();
    final value = await addSubscriptionPlanApi(paymentMethod: "PhonePe");
    if (value == null || value.success != true) {
      await coordinator.resetToIdle();
      return false;
    }

    final typed = SubscriptionAddResponse.fromCommonResponse(value);
    _lastSubscriptionAddResponse = typed;
    final parsedCheckout = typed.amountRupees;
    if (parsedCheckout != null && parsedCheckout > 0) {
      _lastSubscriptionCheckoutRupees = parsedCheckout;
    }
    notifyListeners();

    if (typed.idempotentReplay) {
      pt(
        '[SUBSCRIPTION_PAYMENT] idempotentReplay=true '
        'dedupeReason=${typed.dedupeReason ?? "(none)"} — '
        'reusing existing PhonePe redirect',
      );
    }

    final launchUrlValue =
        typed.effectiveRedirectUrl ?? _extractPaymentUrl(value);
    final merchant = typed.merchantTransactionId;
    if (launchUrlValue == null || launchUrlValue.isEmpty) {
      await refreshEntitlements(
        reason: 'subscription_no_redirect',
        silent: true,
      );
      await coordinator.syncAfterRefresh(
        canUsePremiumFeature: () => canUsePremiumFeature,
      );
      AppPopUp.showToast(
        message: value.message ?? "Subscription request submitted.",
      );
      return canUsePremiumFeature;
    }

    coordinator.markRedirecting(
      merchantId: merchant,
      planId: selectedOrFirstPlanId,
    );

    final uri = Uri.tryParse(launchUrlValue);
    if (uri == null) {
      AppPopUp.showToast(message: "Invalid PhonePe payment URL.");
      await coordinator.resetToIdle();
      return false;
    }

    pt('[SUBSCRIPTION_PAYMENT] Launching PhonePe URL externally');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      AppPopUp.showToast(message: "Could not open PhonePe.");
      await coordinator.resetToIdle();
      return false;
    }

    if (merchant != null && merchant.isNotEmpty) {
      await coordinator.markPendingAfterPhonePeLaunched(
        merchantTransactionId: merchant,
        planId: selectedOrFirstPlanId,
      );
      coordinator.startVerificationPolling(
        refreshEntitlements: () => refreshEntitlements(
          reason: 'subscription_payment_poll',
          silent: true,
        ),
        canUsePremiumFeature: () => canUsePremiumFeature,
      );
    }
    return opened;
  }

  String? _extractPaymentUrl(CommonResponseModel value) {
    final roots = <dynamic>[value.data];
    if (value.data is Map) {
      final map = value.data as Map;
      roots.add(map['payment']);
      roots.add(map['phonePe']);
      roots.add(map['phonepe']);
      roots.add(map['instrumentResponse']);
    }

    for (final root in roots) {
      final url = _extractPaymentUrlFromDynamic(root);
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  String? _extractPaymentUrlFromDynamic(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    for (final key in const [
      'paymentUrl',
      'payment_url',
      'redirectUrl',
      'redirect_url',
      'checkoutUrl',
      'checkout_url',
      'url',
      'targetUrl',
    ]) {
      final raw = map[key];
      if (raw != null && raw.toString().isNotEmpty) return raw.toString();
    }

    final redirectInfo = map['redirectInfo'] ?? map['redirect_info'];
    final nested = _extractPaymentUrlFromDynamic(redirectInfo);
    if (nested != null) return nested;

    final instrument = map['instrumentResponse'] ?? map['instrument_response'];
    return _extractPaymentUrlFromDynamic(instrument);
  }

  @override
  void dispose() {
    unawaited(appleIap.dispose());
    super.dispose();
  }
}
