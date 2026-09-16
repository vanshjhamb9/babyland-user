import 'dart:async';
import 'dart:io';

import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// StoreKit product id — must match App Store Connect exactly.
const String kAppleProMonthlyProductId = 'babyland_pro_monthly';

/// Thin StoreKit wrapper for iOS Pro monthly subscription.
///
/// Completes purchases only after the caller verifies with the backend.
class AppleIapService {
  AppleIapService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  bool _available = false;
  bool _loadingProducts = false;
  String? _lastError;
  bool _purchaseInFlight = false;

  ProductDetails? get product => _product;
  bool get isAvailable => _available;
  bool get isLoadingProducts => _loadingProducts;
  String? get lastError => _lastError;
  bool get purchaseInFlight => _purchaseInFlight;
  String? get storePriceLabel => _product?.price;

  Future<void> init({
    required Future<bool> Function(PurchaseDetails purchase) onPurchaseVerified,
    void Function(String message)? onError,
    void Function()? onPurchaseUiSettled,
  }) async {
    if (!Platform.isIOS) return;
    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _onPurchases(
        purchases,
        onPurchaseVerified: onPurchaseVerified,
        onError: onError,
        onPurchaseUiSettled: onPurchaseUiSettled,
      ),
      onError: (Object e) {
        pt('[APPLE_IAP] purchaseStream error: $e');
        _lastError = e.toString();
        _purchaseInFlight = false;
        onError?.call('Purchase failed. Please try again.');
        onPurchaseUiSettled?.call();
      },
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!Platform.isIOS) return;
    _loadingProducts = true;
    _lastError = null;
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        _lastError = 'In-App Purchases are not available on this device.';
        pt('[APPLE_IAP] StoreKit unavailable');
        return;
      }
      final response = await _iap.queryProductDetails({kAppleProMonthlyProductId});
      if (response.error != null) {
        _lastError = response.error!.message;
        pt('[APPLE_IAP] queryProductDetails error: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        pt('[APPLE_IAP] products not found: ${response.notFoundIDs}');
        _lastError ??=
            'Subscription product not found. Ensure $kAppleProMonthlyProductId is submitted in App Store Connect.';
      }
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        pt(
          '[APPLE_IAP] loaded product id=${_product!.id} '
          'price=${_product!.price}',
        );
      }
    } catch (e, st) {
      _lastError = e.toString();
      pt('[APPLE_IAP] loadProducts failed: $e\n$st');
    } finally {
      _loadingProducts = false;
    }
  }

  /// Opens the native App Store purchase sheet.
  Future<bool> buyProMonthly() async {
    if (!Platform.isIOS) return false;
    if (_purchaseInFlight) return false;
    _lastError = null;

    if (_product == null) {
      await loadProducts();
    }
    final product = _product;
    if (product == null) {
      _lastError = _lastError ??
          'Unable to load App Store subscription. Try again shortly.';
      return false;
    }

    _purchaseInFlight = true;
    final param = PurchaseParam(productDetails: product);
    try {
      // Auto-renewable subscriptions use the same buy API as non-consumables.
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _purchaseInFlight = false;
        _lastError = 'Could not start App Store purchase.';
      }
      return started;
    } catch (e, st) {
      _purchaseInFlight = false;
      _lastError = e.toString();
      pt('[APPLE_IAP] buyProMonthly failed: $e\n$st');
      return false;
    }
  }

  Future<void> _onPurchases(
    List<PurchaseDetails> purchases, {
    required Future<bool> Function(PurchaseDetails purchase) onPurchaseVerified,
    void Function(String message)? onError,
    void Function()? onPurchaseUiSettled,
  }) async {
    for (final purchase in purchases) {
      pt(
        '[APPLE_IAP] purchase status=${purchase.status} '
        'product=${purchase.productID} pendingComplete=${purchase.pendingCompletePurchase}',
      );

      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _purchaseInFlight = false;
        final msg = purchase.error?.message ?? 'Purchase failed.';
        _lastError = msg;
        onError?.call(msg);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        onPurchaseUiSettled?.call();
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        _purchaseInFlight = false;
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        onPurchaseUiSettled?.call();
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final ok = await onPurchaseVerified(purchase);
          if (ok && purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          } else if (!ok) {
            onError?.call(
              'Purchase could not be verified. Please contact support if charged.',
            );
          }
        } catch (e, st) {
          pt('[APPLE_IAP] verify failed: $e\n$st');
          onError?.call('Purchase verification failed. Please try again.');
        } finally {
          _purchaseInFlight = false;
          onPurchaseUiSettled?.call();
        }
      }
    }
  }

  Future<void> restorePurchases() async {
    if (!Platform.isIOS || !_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      pt('[APPLE_IAP] restorePurchases failed: $e\n$st');
      _lastError = e.toString();
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @visibleForTesting
  void debugSetProduct(ProductDetails? product) => _product = product;
}
