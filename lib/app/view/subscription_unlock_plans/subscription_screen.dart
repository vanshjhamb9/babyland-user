import 'dart:async';

import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/utils/currency_formatter.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/model/subscription_model.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/core/subscription/subscription_payment_coordinator.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  bool _waitingForPhonePe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();
      final coord = context.read<SubscriptionPaymentCoordinator>();
      unawaited(provider.getSubscriptionPlanApi());
      unawaited(provider.getMySubscriptionApi(silent: true));
      coord.resumePollingIfNeeded(
        refreshEntitlements: () => provider.refreshEntitlements(
          reason: 'subscription_screen_resume',
          silent: true,
        ),
        canUsePremiumFeature: () => provider.canUsePremiumFeature,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_waitingForPhonePe) return;
    final provider = context.read<SubscriptionProvider>();
    pt('[SUBSCRIPTION_PAYMENT] App resumed; refreshing subscription status');
    unawaited(_refreshAfterPhonePe(provider));
  }

  Future<void> _refreshAfterPhonePe(SubscriptionProvider provider) async {
    await provider.refreshEntitlements(
      reason: 'subscription_phonepe_resume',
      silent: true,
    );
    if (!mounted) return;
    if (provider.canUsePremiumFeature) {
      _waitingForPhonePe = false;
      AppPopUp.showToast(message: 'Subscription activated.');
      final coord = context.read<SubscriptionPaymentCoordinator>();
      await _leaveAfterSuccess(coord);
    } else {
      AppPopUp.showToast(
        message:
            'Payment is still being verified. Please wait a moment and try again.',
      );
    }
  }

  Future<void> _leaveAfterSuccess(SubscriptionPaymentCoordinator coord) async {
    if (!mounted) return;
    coord.stopPolling();
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true);
      return;
    }
    await nav.pushNamedAndRemoveUntil(
      AppRoutes.splashView,
      (_) => false,
    );
  }

  Future<void> _onUpgrade(SubscriptionProvider provider) async {
    if (provider.addSubscription?.status == ApiStatus.LOADING) return;
    final coord = context.read<SubscriptionPaymentCoordinator>();
    final opened = await provider.startPhonePeSubscriptionCheckout(coord);
    if (!mounted) return;
    if (provider.canUsePremiumFeature) {
      AppPopUp.showToast(message: 'Subscription activated.');
      await _leaveAfterSuccess(coord);
      return;
    }
    if (opened) {
      _waitingForPhonePe = true;
      AppPopUp.showToast(
        message: 'Complete payment in PhonePe. We will refresh when you return.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        actions: kDebugMode
            ? [
                IconButton(
                  icon: const Icon(Icons.bug_report_outlined),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.phase8DebugScreen,
                  ),
                ),
              ]
            : null,
        title: Text(
          'Premium Subscription',
          style: TextStyle(
            color: AppColors.black,
            fontFamily: AppFontFamily.gilroySemiBold,
            fontSize: 20,
          ),
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Consumer2<SubscriptionProvider, SubscriptionPaymentCoordinator>(
          builder: (context, provider, coord, _) {
            if (provider.allSubscription?.status == ApiStatus.LOADING) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.allSubscription?.status == ApiStatus.ERROR) {
              return GeneralExceptionWidget(
                onPress: () => provider.getSubscriptionPlanApi(),
              );
            }

            final plans = provider.paidActivePlans;
            final planIndex = plans.isNotEmpty
                ? provider.selectedPlanIndex.clamp(0, plans.length - 1).toInt()
                : 0;
            final plan = plans.isNotEmpty ? plans[planIndex] : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  if (coord.state ==
                      SubscriptionPaymentState.pendingVerification)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Verifying payment with server…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textLightClr,
                          fontFamily: AppFontFamily.gilroyMedium,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  plan == null
                      ? _buildNoPaidPlanCard(provider)
                      : _buildCard(context, provider, plan, coord),
                  const SizedBox(height: 40),
                  Text(
                    'PhonePe Secure Payment',
                    style: TextStyle(
                      color: AppColors.textLightClr,
                      fontFamily: AppFontFamily.gilroyMedium,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 16, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        '100% Safe & Encrypted',
                        style: TextStyle(
                          color: AppColors.green,
                          fontFamily: AppFontFamily.gilroyMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    SubscriptionProvider provider,
    Plans? plan,
    SubscriptionPaymentCoordinator coord,
  ) {
    final isLoading = provider.addSubscription?.status == ApiStatus.LOADING;
    // Per contract §1.3 the canonical amount is `amountPaise / 100`. The model's
    // `amountRupeesForDisplay` already implements that fallback ladder
    // (paise → rupees, else `price` field). Use it as the pre-checkout hint.
    final planCheckoutHint = plan?.amountRupeesForDisplay ?? 0;
    final serverCheckout = provider.lastSubscriptionCheckoutRupees;
    final displayAmount = (serverCheckout != null && serverCheckout > 0)
        ? serverCheckout
        : (planCheckoutHint > 0 ? planCheckoutHint : 2499);
    // The plan-listing endpoint emits `amountPaise` which is server-computed,
    // tax-inclusive money (the same value the PhonePe order is created from).
    // When we have it, the displayed amount is already the final total.
    final hasInclusivePlanFields =
        plan != null && (plan.amountPaise ?? 0) > 0;
    final title = (plan?.name?.isNotEmpty == true ? plan!.name! : 'Pro Plan')
        .toUpperCase();
    final features = plan?.features
            ?.where((feature) => feature.active != false)
            .map((feature) => feature.name ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        const <String>[];
    final visibleFeatures = features.isNotEmpty
        ? features
        : const <String>[
            'Holistic Wellness Support',
            'Personalized Health Trackers',
            'Expert Consultations',
            'AI-Powered Health Insights',
            'Everyday Essentials Access',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.darkBrown,
                fontFamily: AppFontFamily.gilroyBold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            formatCurrency(displayAmount),
            style: TextStyle(
              color: AppColors.textClr,
              fontFamily: AppFontFamily.gilroyBold,
              fontSize: 48,
            ),
          ),
          Text(
            (serverCheckout != null && serverCheckout > 0) || hasInclusivePlanFields
                ? 'Total due (matches PhonePe)'
                : 'Taxes & fees may apply — PhonePe shows the final total',
            style: TextStyle(
              color: AppColors.textLightClr,
              fontFamily: AppFontFamily.gilroyMedium,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Billed monthly',
            style: TextStyle(
              color: AppColors.lightGrey,
              fontFamily: AppFontFamily.gilroyRegular,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.borderColor),
          const SizedBox(height: 32),
          ...visibleFeatures.map(_buildFeatureRow),
          const SizedBox(height: 40),
          Button(
            onTap: plan == null ||
                    displayAmount <= 0 ||
                    provider.canUsePremiumFeature ||
                    coord.state ==
                        SubscriptionPaymentState.pendingVerification
                ? null
                : () => _onUpgrade(provider),
            height: 56,
            borderRadius: 16,
            gradient: provider.canUsePremiumFeature
                ? LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  )
                : null,
            child: isLoading
                ? customLoading()
                : Text(
                    provider.canUsePremiumFeature
                        ? 'Pro Active'
                        : 'Upgrade to Pro',
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFontFamily.gilroyBold,
                      fontSize: 18,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPaidPlanCard(SubscriptionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: AppColors.buttonClr1, size: 44),
          const SizedBox(height: 16),
          Text(
            'No paid plan available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textClr,
              fontFamily: AppFontFamily.gilroyBold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The backend is returning only free or inactive plans. Add an active paid plan to open PhonePe checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLightClr,
              fontFamily: AppFontFamily.gilroyMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Button(
            onTap: () => provider.getSubscriptionPlanApi(),
            height: 48,
            borderRadius: 12,
            child: Text(
              'Refresh Plans',
              style: TextStyle(
                color: AppColors.white,
                fontFamily: AppFontFamily.gilroyBold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textClr,
                fontFamily: AppFontFamily.gilroyMedium,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
