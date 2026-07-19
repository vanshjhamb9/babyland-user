import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  static const String shopUrl =
      'https://the-babyland-2.myshopify.com/collections';

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Toggle this during staging verification:
  // - true  => strict allowlist (Shopify + common checkout domains)
  // - false => permissive (all http/https)
  static const bool _strictCheckoutDomainFiltering = true;

  // Strict mode allowlist: keep store + checkout/payment flows inside WebView.
  static const Set<String> _allowedExactHosts = {
    'the-babyland-2.myshopify.com',
    'checkout.shopify.com',
    'shop.app',
    'pay.shopify.com',
  };

  static const List<String> _allowedHostSuffixes = [
    '.myshopify.com',
    '.shopify.com',
    '.shop.app',
    '.paypal.com',
    '.stripe.com',
    '.google.com', // for common payment auth redirects
    '.googleapis.com',
    '.gstatic.com',
  ];

  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Keep navigation inside app WebView and block non-web schemes.
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }

            if (!_strictCheckoutDomainFiltering) {
              return NavigationDecision.navigate;
            }

            final host = uri.host.toLowerCase();
            if (_allowedExactHosts.contains(host)) {
              return NavigationDecision.navigate;
            }

            final allowedBySuffix = _allowedHostSuffixes.any(
              (suffix) => host.endsWith(suffix),
            );
            if (allowedBySuffix) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) async {
            await _injectShopifyCleanupCss();
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(ShopScreen.shopUrl));
  }

  Future<void> _injectShopifyCleanupCss() async {
    // Best effort: hide common Shopify header/footer wrappers for a native feel.
    // If selectors are not present, JS safely no-ops.
    const script = '''
      (function() {
        var selectors = [
          'header',
          'footer',
          '.shopify-section-header',
          '.shopify-section-footer',
          '#shopify-section-header',
          '#shopify-section-footer',
          '.announcement-bar',
          '.header-wrapper',
          '.footer'
        ];
        selectors.forEach(function(sel) {
          var nodes = document.querySelectorAll(sel);
          for (var i = 0; i < nodes.length; i++) {
            nodes[i].style.display = 'none';
          }
        });
        document.body.style.paddingTop = '0px';
      })();
    ''';
    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // Ignore JS injection errors and keep page usable.
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.backgroundClr,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.backgroundClr,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'BabyLand Store',
            style: AppFontStyle.text_18_600(
              color: AppColors.textClr,
              fontFamily: AppFontFamily.gilroySemiBold,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.backGroundColor,
              ),
              child: Text(
                'Premium baby products curated for your stage',
                style: AppFontStyle.text_12_400(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_hasError)
                    _ErrorView(
                      onRetry: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _controller.loadRequest(Uri.parse(ShopScreen.shopUrl));
                      },
                    )
                  else
                    WebViewWidget(controller: _controller),
                  if (_isLoading && !_hasError)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_mall_directory_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              'Unable to load store. Please try again.',
              textAlign: TextAlign.center,
              style: AppFontStyle.text_14_400(
                color: AppColors.textClr,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

