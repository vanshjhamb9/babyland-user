import 'dart:async';
import 'dart:io';

import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  Future<bool> Function(PurchaseDetails purchase)? _onPurchaseVerified;
  void Function(String message)? _onError;
  void Function()? _onPurchaseUiSettled;

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
    _onPurchaseVerified = onPurchaseVerified;
    _onError = onError;
    _onPurchaseUiSettled = onPurchaseUiSettled;

    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _onPurchases(purchases),
      onError: (Object e, StackTrace st) {
        pt('[APPLE_IAP] purchaseStream error: $e\n$st');
        _lastError = _userFacingStoreKitError(e);
        _purchaseInFlight = false;
        _onError?.call(_lastError!);
        _onPurchaseUiSettled?.call();
      },
    );
    // Unfinished StoreKit transactions are re-delivered on this subscription;
    // we re-verify before completePurchase (never grant Pro without backend).
    pt('[APPLE_IAP] purchaseStream listening for unfinished transactions');
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
      final response =
          await _iap.queryProductDetails({kAppleProMonthlyProductId});
      if (response.error != null) {
        final err = response.error!;
        pt(
          '[APPLE_IAP] queryProductDetails error '
          'source=${err.source} code=${err.code} message=${err.message} '
          'details=${err.details}',
        );
        _lastError = _userFacingStoreKitMessage(
          err.message,
          code: err.code,
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        pt('[APPLE_IAP] products not found: ${response.notFoundIDs}');
        _lastError ??=
            'Subscription product not found in the App Store. '
            'Confirm $kAppleProMonthlyProductId is Ready under bundle '
            'com.thebabyland, then try again.';
      }
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        pt(
          '[APPLE_IAP] loaded product id=${_product!.id} '
          'price=${_product!.price}',
        );
      } else if (_lastError == null) {
        _lastError =
            'Unable to load App Store subscription. Try again shortly.';
      }
    } catch (e, st) {
      _lastError = _userFacingStoreKitError(e);
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
      pt('[APPLE_IAP] buyProMonthly aborted: product missing ($_lastError)');
      return false;
    }

    _purchaseInFlight = true;
    final param = PurchaseParam(productDetails: product);
    try {
      // Auto-renewable subscriptions use the same buy API as non-consumables.
      pt(
        '[APPLE_IAP] buyNonConsumable start id=${product.id} '
        'price=${product.price}',
      );
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      pt('[APPLE_IAP] buyNonConsumable returned started=$started');
      if (!started) {
        _purchaseInFlight = false;
        _lastError =
            'Could not start App Store purchase. '
            'If you were charged before, tap Restore Purchases.';
      }
      return started;
    } on PlatformException catch (e, st) {
      _purchaseInFlight = false;
      pt(
        '[APPLE_IAP] buyProMonthly PlatformException '
        'code=${e.code} message=${e.message} details=${e.details}\n$st',
      );
      _lastError = _userFacingStoreKitMessage(
        e.message ?? e.code,
        code: e.code,
        details: e.details,
      );
      return false;
    } catch (e, st) {
      _purchaseInFlight = false;
      pt('[APPLE_IAP] buyProMonthly failed: $e\n$st');
      _lastError = _userFacingStoreKitError(e);
      return false;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final onPurchaseVerified = _onPurchaseVerified;
    if (onPurchaseVerified == null) return;

    for (final purchase in purchases) {
      final unfinished = purchase.pendingCompletePurchase &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored);
      pt(
        '[APPLE_IAP] purchase status=${purchase.status} '
        'product=${purchase.productID} '
        'pendingComplete=${purchase.pendingCompletePurchase}'
        '${unfinished ? ' (unfinished — re-verifying)' : ''}',
      );

      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _purchaseInFlight = false;
        final raw = purchase.error?.message ?? 'Purchase failed.';
        pt(
          '[APPLE_IAP] purchase error code=${purchase.error?.code} '
          'message=$raw details=${purchase.error?.details}',
        );
        _lastError = _userFacingStoreKitMessage(
          raw,
          code: purchase.error?.code,
          details: purchase.error?.details,
        );
        _onError?.call(_lastError!);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _onPurchaseUiSettled?.call();
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        _purchaseInFlight = false;
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _onPurchaseUiSettled?.call();
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final ok = await onPurchaseVerified(purchase);
          if (ok && purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
            pt('[APPLE_IAP] completePurchase after successful verify');
          } else if (!ok) {
            // Leave StoreKit transaction open so a later launch / Restore
            // can re-deliver and retry verify — never grant Pro locally.
            pt(
              '[APPLE_IAP] verify failed; leaving pendingComplete='
              '${purchase.pendingCompletePurchase} for retry',
            );
            _onError?.call(
              'Purchase could not be verified. Tap Restore Purchases '
              'if you were charged, or try again shortly.',
            );
          }
        } catch (e, st) {
          pt('[APPLE_IAP] verify failed: $e\n$st');
          _onError?.call(
            'Purchase verification failed. Tap Restore Purchases if charged.',
          );
        } finally {
          _purchaseInFlight = false;
          _onPurchaseUiSettled?.call();
        }
      }
    }
  }

  Future<void> restorePurchases() async {
    if (!Platform.isIOS || !_available) return;
    try {
      pt('[APPLE_IAP] restorePurchases');
      await _iap.restorePurchases();
    } on PlatformException catch (e, st) {
      pt(
        '[APPLE_IAP] restorePurchases PlatformException '
        'code=${e.code} message=${e.message} details=${e.details}\n$st',
      );
      _lastError = _userFacingStoreKitMessage(
        e.message ?? e.code,
        code: e.code,
        details: e.details,
      );
    } catch (e, st) {
      pt('[APPLE_IAP] restorePurchases failed: $e\n$st');
      _lastError = _userFacingStoreKitError(e);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _onPurchaseVerified = null;
    _onError = null;
    _onPurchaseUiSettled = null;
  }

  /// Maps raw StoreKit / plugin failures to actionable user copy.
  static String _userFacingStoreKitError(Object e) {
    if (e is PlatformException) {
      return _userFacingStoreKitMessage(
        e.message ?? e.code,
        code: e.code,
        details: e.details,
      );
    }
    return _userFacingStoreKitMessage(e.toString());
  }

  static String _userFacingStoreKitMessage(
    String? message, {
    String? code,
    Object? details,
  }) {
    final raw = (message ?? '').trim();
    final lower = raw.toLowerCase();
    final codeLower = (code ?? '').toLowerCase();

    if (lower.contains('failed to get response from platform') ||
        lower.contains('storekit_duplicate_product_object') ||
        codeLower.contains('storekit')) {
      return 'App Store did not respond. Use a physical device with a '
          'Sandbox Apple ID (Settings → App Store), confirm Paid Applications '
          'is active, then try again. If you were charged, tap Restore Purchases.';
    }
    if (lower.contains('not available') ||
        lower.contains('storekit unavailable')) {
      return 'In-App Purchases are not available on this device.';
    }
    if (lower.contains('not found') || lower.contains('product')) {
      if (lower.contains('not found') || lower.contains('invalid')) {
        return 'Subscription product not found in the App Store. '
            'Confirm $kAppleProMonthlyProductId is Ready under bundle '
            'com.thebabyland, then try again.';
      }
    }
    if (raw.isEmpty) {
      return 'Could not start App Store purchase. Please try again.';
    }
    // Keep plugin message when already clear; append restore hint for platform noise.
    if (details != null) {
      pt('[APPLE_IAP] error details=$details');
    }
    return raw;
  }

  @visibleForTesting
  void debugSetProduct(ProductDetails? product) => _product = product;

  @visibleForTesting
  static String debugUserFacingMessage(
    String? message, {
    String? code,
    Object? details,
  }) =>
      _userFacingStoreKitMessage(message, code: code, details: details);
}
