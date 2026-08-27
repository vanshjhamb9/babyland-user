import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controller/policies/policies_controller.dart';
import '../../../theme/font_style.dart';

class TermOfServicesScreen extends StatefulWidget {
  const TermOfServicesScreen({super.key});

  @override
  State<TermOfServicesScreen> createState() => _TermOfServicesScreenState();
}

class _TermOfServicesScreenState extends State<TermOfServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<PoliciesProvider>().privacyPolicyApi("terms");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: Text("Term And Services",style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroyMedium)),centerTitle: true,),
      body: Consumer<PoliciesProvider>(
        builder: (context, provider, _) {
          final content = provider.policyData?.data?.data?.content ?? "";
          final fixedContent =
          prepareClickableContent(fixSpecialCharacters(content));
          return switch(provider.policyData?.status){
            ApiStatus.LOADING => shimmerBody(),
            ApiStatus.COMPLETED => content.isEmpty ? Center(
              child: Text('No privacy policy content available'),
            ) :  body(fixedContent),
            ApiStatus.ERROR => GeneralExceptionWidget(onPress: () => provider.privacyPolicyApi("terms"),),
            null => GeneralExceptionWidget(onPress: () => provider.privacyPolicyApi("terms"),),
          };
        },
      ),
    );
  }

  SingleChildScrollView body(String fixedContent) {
    return SingleChildScrollView(
      child: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Html(
          data: fixedContent,

          // ---------------- STYLING ----------------
          style: {
            "html": Style(
              fontFamily: AppFontFamily.gilroyMedium,
              padding: HtmlPaddings.all(16),
              backgroundColor: Colors.transparent,
            ),

            "p": Style(
              fontFamily: AppFontFamily.gilroyMedium,
              fontSize: FontSize(14),
              lineHeight: const LineHeight(1.5),
              margin: Margins.only(bottom: 12),
            ),

            // General anchor
            "a": Style(
              textDecoration: TextDecoration.underline,
            ),

            // 👉 Email Link Style
            ".email-link": Style(
              color: Colors.blue, // 🔴 EMAIL COLOR
              fontWeight: FontWeight.w500,
              textDecoration: TextDecoration.none,
            ),

            // 👉 Website Link Style
            ".web-link": Style(
              color: Colors.blue, // 🔵 WEBSITE COLOR
              fontWeight: FontWeight.w600,
              textDecoration: TextDecoration.none,
            ),

            "li": Style(
              fontFamily: AppFontFamily.gilroyMedium,
              fontSize: FontSize(14),
              lineHeight: const LineHeight(1.5),
              margin: Margins.only(bottom: 4),
            ),
          },

          // --------------- CLICK HANDLER ---------------
          onLinkTap: (url, attributes, element) async {
            if (url == null) return;

            if (url.startsWith("mailto:")) {
              await launchUrl(Uri.parse(url));
              return;
            }

            final uri = Uri.parse(
              url.startsWith("http") ? url : "https://$url",
            );

            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ),
    );
  }

  // ---------------- FIX BULLETS ----------------
  String fixSpecialCharacters(String html) {
    // Replace the special bullet char with standard
    html = html.replaceAll('', '•');

    // Ensure bullet always starts on a new line
    html = html.replaceAll("•", "<br><br>• ");

    return html;
  }

  // ---------------- CONVERT EMAILS + URLS INTO CLICKABLE LINKS ----------------
  String prepareClickableContent(String html) {
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)');

    var updated = html;

    // Convert emails
    updated = updated.replaceAllMapped(emailRegex, (match) {
      final email = match[0]!;
      return '<a class="email-link" href="mailto:$email">$email</a>';
    });

    // Convert URLs
    updated = updated.replaceAllMapped(urlRegex, (match) {
      final url = match[0]!;
      final href = url.startsWith("http") ? url : "https://$url";
      return '<a class="web-link" href="$href">$url</a>';
    });

    return updated;
  }


  Widget shimmerBody() {
    return SingleChildScrollView(
      child: AppContainer(
        height: mediaQueryH(context),
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              20,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
