import 'package:babyland/app/widgets/general_exception.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/ai_assistant/ai_assistant_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/text.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final List<String> chatsList = [
    "Hello! I’m your personal AI Heath Assistent.",
    "When is my next period expected?",
    "Why is my cycle late this month?",
    "Is it normal to feel bloated before my period?",
    "Suggest a healthy snack for mood swings.",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp)async {
      await  context.read<AiAssistantProvider>().createChatRoomApi();
      context.read<AiAssistantProvider>().startNewChat();
      // context.read<AiAssistantProvider>().getAllAiChatModel();
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appbar(),
      body: Consumer<AiAssistantProvider>(
        builder: (context, provider, _) {
          ApiStatus? status;

          // Decide which status to use
          if (provider.allAiChatData?.status != null) {
            status = provider.allAiChatData!.status;
          } else {
            status = provider.createCharRoom?.status;
          }

          return switch (status) {
            ApiStatus.LOADING => shimmerBody(context),
            ApiStatus.ERROR => GeneralExceptionWidget(
              onPress: () {
                provider.getAllAiChatModel();
              },
            ),
            ApiStatus.COMPLETED => bodyForNewChat(provider),
            null => Center(child: Text("No data")),
          };
        },

      ),
    );
  }


  Widget bodyForNewChat(AiAssistantProvider provider) {
    return SafeArea(
          child: provider.createCharRoom?.status == ApiStatus.LOADING ? shimmerBody(context) : AppContainer(
            gradient: AppColors.backGroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(provider.chatList.isEmpty)
                prebuildMessages(),
                Expanded(
                  child: Consumer<AiAssistantProvider>(
                    builder: (context,provider,_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Future.delayed(const Duration(milliseconds: 50), () {
                          provider.scrollToBottom(immediate: true);
                        });
                      });
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: provider.scrollController,
                              reverse: false,
                              shrinkWrap: true,
                              itemCount: provider.chatList.length,
                              itemBuilder: (context, index) {
                                final chat = provider.chatList[index];
                                final isAssistant = chat.aiMessage != null;
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(isAssistant ? 50 : 20, 8, 14, 8),
                                  child: Align(
                                    alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                                    child: IntrinsicWidth(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          AppContainer(
                                            borderColor: isAssistant ? AppColors.borderColor : AppColors.transparent,
                                            radius: 8,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                            gradient: isAssistant
                                                ? AppColors.whiteGradientClr
                                                : AppColors.backGroundColor,
                                            // child: Text(
                                            //   isAssistant ? chat.aiMessage ?? "" : chat.userMessage ?? "",
                                            //   maxLines: 100,
                                            //   style: AppFontStyle.text_14_400(
                                            //       fontFamily: AppFontFamily.gilroyMedium),
                                            // ),
                                            child: SafeMarkdownFormatter.format(
                                              isAssistant ? chat.aiMessage ?? "" : chat.userMessage ?? "",
                                              // isAssistant,
                                            ),
                                          ),
                                          if (isAssistant)
                                            Positioned(
                                                left: -32,
                                                child: CustomImage(path: ImageConstants.starSvg))
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14,0,15,18),
                            child: provider.isVoiceChat ?
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: AlignmentGeometry.center,
                                children: [
                                  // VoiceAssistantButton(
                                  //   color: AppColors.buttonClr2,
                                  //   messageController: provider.messageController,
                                  //   onStop: () {
                                  //     provider.setVoiceChat(false);
                                  //     // provider.setMicOn(false);
                                  //   },
                                  // ),
                                  VoiceAssistantButton(
                                    color: Colors.blue,
                                    provider: provider,
                                  ),
                                  Positioned(
                                    top: -45,
                                    child: AppContainer(
                                      padding: EdgeInsets.symmetric(horizontal: 15,vertical: 4),
                                      isBordered: true,
                                      radius: 100,
                                      color: AppColors.white,
                                      borderColor: AppColors.buttonClr2.withAlpha(120),
                                      child: Text("Listening.....",
                                        style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textLightClr),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                              : provider.isVoiceChat ? Center(
                              child: InkWell(
                                splashColor: AppColors.transparent,
                                highlightColor: AppColors.transparent,
                                onTap: () {

                                  provider.setVoiceChat(true);
                                  // provider.setMicOn(false);
                                },
                                child: AppContainer(
                                  radius: 100,
                                  padding: const EdgeInsets.all(18),
                                  color: AppColors.white,
                                  child: CustomImage(path: ImageConstants.micIcon),
                                ),
                              ),
                            ) : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomTextFormField(
                                  borderRadius: BorderRadius.circular(100),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16,horizontal: 16),
                                  borderColor: AppColors.borderColor,
                                  width: mediaQueryW(context) * 0.76,
                                  filled: true,
                                  fillColor: AppColors.white,
                                  hintText: "Type your Message..",
                                  controller: provider.messageController,
                                  prefix: Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: CustomImage(path: ImageConstants.attachIcon),
                                  ),
                                  suffix: InkWell(
                                    splashColor: AppColors.transparent,
                                    highlightColor: AppColors.transparent,
                                    onTap: (){
                                      provider.setVoiceChat(true);
                                      // provider.setMicOn(true);
                                    },
                                    child: SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: Padding(
                                          padding: const EdgeInsets.all(13.0),
                                          child: CustomImage(path: ImageConstants.micIcon),
                                        )),
                                  ),
                                ),
                                Spacer(),
                                InkWell(
                                  onTap: () {
                                    if(provider.messageController.text.isEmpty){
                                      AppPopUp.showToast(message: "Please enter your message",lineColor: AppColors.red);
                                    }else {
                                      if( provider.createAiChatData?.status != ApiStatus.LOADING) {
                                        provider.createChatMessages();
                                      }
                                    }
                                  },
                                  child: AppContainer(
                                    gradient: AppColors.buttonClr,
                                    radius: 100,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    child: provider.createAiChatData?.status == ApiStatus.LOADING ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.white
                                      ),
                                    ) : CustomImage(path: ImageConstants.sendIcon),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Expanded prebuildMessages() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<GetUserProvider>(
              builder: (context,provider,_) {
                return GradientText(
                  "Hello ${provider.userData?.data?.user?.user?.name ?? ""},",
                  gradient: AppColors.buttonClr,
                  style: AppFontStyle.text_26_400(fontFamily: AppFontFamily.gilroyBold),
                );
              }
            ),
            Text("Ask me anything.......",
              style: AppFontStyle.text_26_400(fontFamily: AppFontFamily.gilroyMedium),
            ),
            SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              itemCount:chatsList.length,
                itemBuilder: (context, index) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Consumer<AiAssistantProvider>(
                      builder: (context,provider,_) {
                        return InkWell(
                          onTap: () {
                            provider.messageController.text = chatsList[index];
                            provider.createChatMessages();
                          },
                          child: AppContainer(
                            radius: 8,
                            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 8),
                            color: AppColors.white,
                            isBordered: true,
                            child:  Text(chatsList[index],
                              style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textClr),
                            ),
                          ),
                        );
                      }
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(height: 8),
              ),
          ],
        ),
      ),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      toolbarHeight: 100,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Ask Health AI",
            style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroyMedium),
          ),
          const SizedBox(width: 6),
          CustomImage(path: ImageConstants.starSvg),
        ],
      ),
      actions: [
        IconButton(onPressed: (){
          context.read<AiAssistantProvider>().getAllAiChatModel();
        }, icon: Icon(Icons.history)),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppContainer(
              gradient: AppColors.buttonClr,
              radius: 100,
              padding: const EdgeInsets.all(1),
              child: CustomImage(
                h: 40,
                w: 40,
                borderRadius: BorderRadius.circular(100),
                path: "https://i.pravatar.cc/300",
              ),
            ),
            Consumer<GetUserProvider>(
                builder: (context,provider,_) {
                return Positioned(
                  bottom: -10,
                  child: AppContainer(
                    color: AppColors.white,
                    borderColor: AppColors.buttonClr1,
                    radius: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Text(
                      "${provider.userData?.data?.user?.profileCompletion ?? "0"}%",
                      style: AppFontStyle.text_10_400(
                          fontFamily: AppFontFamily.gilroyMedium),
                    ),
                  ),
                );
              }
            ),
          ],
        ),
        const SizedBox(width: 14),
      ],
    );
  }


  Widget shimmerBody(BuildContext context) {
    return AppContainer(
      gradient: AppColors.backGroundColor,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemCount: 15,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: index % 2 == 0
                      ? MediaQuery.of(context).size.width * 0.7
                      : MediaQuery.of(context).size.width * 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Loading...",
                    style: TextStyle(color: Colors.transparent),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
class VoiceAssistantButton extends StatefulWidget {
  final Color color;
  final AiAssistantProvider provider;

  const VoiceAssistantButton({
    super.key,
    required this.color,
    required this.provider,
  });

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceAssistantButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start/stop animation based on listening state
    if (widget.provider.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            if (!widget.provider.isListening) {
              // Start voice chat
              await widget.provider.setVoiceChat(true);
            } else {
              // Stop voice chat if already listening
              await widget.provider.setVoiceChat(false);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withAlpha(5),
                width: 3,
              ),
              boxShadow: widget.provider.isListening
                  ? [
                BoxShadow(
                  color: widget.color.withAlpha(
                    (_opacityAnimation.value * 0.5 * 255).toInt(),
                  ),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ]
                  : null,
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.provider.isListening ? Colors.blue[100] : Colors.white,
              ),
              padding: const EdgeInsets.all(18),
              child: Icon(
                widget.provider.isListening ? Icons.mic : Icons.mic_none,
                color: widget.provider.isListening ? Colors.blue : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SafeMarkdownFormatter {

  static Widget format(String text, {bool isAssistant = false}) {
    try {
      // Check if text is null or empty
      if (text.isEmpty) {
        return const SizedBox.shrink();
      }

      // Clean text - remove duplicate disclaimers if they exist at end
      String cleanedText = _removeDuplicateDisclaimer(text);

      // Safe parsing
      final widgets = _safeParse(cleanedText);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      );
    } catch (e, stackTrace) {
      // If any error occurs, return plain text
      debugPrint('Markdown parsing error: $e\n$stackTrace');
      return Text(
        text,
        maxLines: 1000,
        style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
      );
    }
  }

  // Remove duplicate disclaimer from the end of text
  static String _removeDuplicateDisclaimer(String text) {
    final disclaimerText = '*Disclaimer: I am an AI assistant. This information is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or another qualified health provider with any questions you may have regarding a medical condition.*';

    // Check if text ends with disclaimer
    if (text.trim().endsWith(disclaimerText.trim())) {
      // Find the last occurrence of disclaimer
      final lastIndex = text.lastIndexOf(disclaimerText);
      if (lastIndex > 0) {
        // Check if there's another disclaimer before this
        final beforeLast = text.substring(0, lastIndex);
        if (beforeLast.contains(disclaimerText)) {
          // Keep only one disclaimer
          return beforeLast + disclaimerText;
        }
      }
    }
    return text;
  }

  static List<Widget> _safeParse(String text) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      try {
        final line = lines[i];

        // Skip empty lines
        if (line.trim().isEmpty) {
          if (i < lines.length - 1 && lines[i + 1].trim().isNotEmpty) {
            widgets.add(const SizedBox(height: 4));
          }
          continue;
        }

        // Handle headers
        if (line.startsWith('# ')) {
          widgets.add(_parseHeader(line, 1));
          continue;
        } else if (line.startsWith('## ')) {
          widgets.add(_parseHeader(line, 2));
          continue;
        } else if (line.startsWith('### ')) {
          widgets.add(_parseHeader(line, 3));
          continue;
        }

        // Handle horizontal rule
        if (line.trim() == '---') {
          widgets.add(const Divider(height: 20, thickness: 1));
          continue;
        }

        // Handle bullet points
        if (line.trim().startsWith('- ') ||
            line.trim().startsWith('* ') ||
            line.trim().startsWith('+ ')) {
          widgets.add(_parseListItem(line));
          continue;
        }

        // Handle numbered list
        if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
          widgets.add(_parseNumberedItem(line));
          continue;
        }

        // Handle disclaimer line
        if (line.contains('Disclaimer:')) {
          widgets.add(_parseDisclaimer(line));
          continue;
        }

        // Parse line with inline formatting
        widgets.add(_parseLineWithFormatting(line));
      } catch (e) {
        // If line parsing fails, add as plain text
        debugPrint('Error parsing line: $e');
        widgets.add(Text(
          lines[i],
          maxLines: 1000,
          style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
        ));
      }
    }

    return widgets;
  }

  static Widget _parseHeader(String line, int level) {
    String headerText = line.substring(level).trim();
    double fontSize;
    FontWeight fontWeight;

    switch (level) {
      case 1:
        fontSize = 18;
        fontWeight = FontWeight.bold;
        break;
      case 2:
        fontSize = 16;
        fontWeight = FontWeight.w600;
        break;
      case 3:
        fontSize = 15;
        fontWeight = FontWeight.w600;
        break;
      default:
        fontSize = 14;
        fontWeight = FontWeight.w500;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        headerText,
        maxLines: 1000,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: AppFontFamily.gilroySemiBold,
          color: Colors.black87,
        ),
      ),
    );
  }

  static Widget _parseListItem(String line) {
    String content = line.trim();

    // Remove bullet marker
    if (content.startsWith('- ')) {
      content = content.substring(2);
    } else if (content.startsWith('* ')) {
      content = content.substring(2);
    } else if (content.startsWith('+ ')) {
      content = content.substring(2);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',        maxLines: 1000, style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Expanded(
            child: _parseLineWithFormatting(content),
          ),
        ],
      ),
    );
  }

  static Widget _parseNumberedItem(String line) {
    final match = RegExp(r'^(\d+)\.\s').firstMatch(line.trim());
    String number = '1.';
    String content = line.trim();

    if (match != null && match.group(1) != null) {
      try {
        number = '${match.group(1)}.';
        content = content.substring(match.end);
      } catch (e) {
        // Keep original if error
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number ',         maxLines: 1000,style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Expanded(
            child: _parseLineWithFormatting(content),
          ),
        ],
      ),
    );
  }

  static Widget _parseLineWithFormatting(String line) {
    // Check for bold text
    if (line.contains('**')) {
      return _parseBoldText(line);
    }

    // Check for italic text (single asterisks not at start of line)
    if (line.contains('*') && !line.trim().startsWith('* ')) {
      final italicMatch = RegExp(r'[^*]\*[^*]').firstMatch(line);
      if (italicMatch != null) {
        return _parseItalicText(line);
      }
    }

    // Plain text
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        line,
        maxLines: 1000,
        style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
      ),
    );
  }

  static Widget _parseBoldText(String text) {
    try {
      final parts = text.split('**');
      final spans = <InlineSpan>[];

      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 0) {
          // Normal text
          spans.add(TextSpan(
            text: parts[i],
            style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
          ));
        } else {
          // Bold text
          spans.add(TextSpan(
            text: parts[i],
            style: AppFontStyle.text_14_600(fontFamily: AppFontFamily.gilroySemiBold),
          ));
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(children: spans),
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text.replaceAll('**', ''),
          maxLines: 1000,
          style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
        ),
      );
    }
  }

  static Widget _parseItalicText(String text) {
    try {
      final parts = text.split('*');
      final spans = <InlineSpan>[];

      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 0) {
          // Normal text
          spans.add(TextSpan(
            text: parts[i],
            style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
          ));
        } else {
          // Italic text
          spans.add(TextSpan(
            text: parts[i],
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ));
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(children: spans),
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text.replaceAll('*', ''),
          maxLines: 1000,
          style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),
        ),
      );
    }
  }

  static Widget _parseDisclaimer(String line) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        line,
        maxLines: 1000,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade700,
          fontFamily: AppFontFamily.gilroyMedium,
        ),
      ),
    );
  }
}