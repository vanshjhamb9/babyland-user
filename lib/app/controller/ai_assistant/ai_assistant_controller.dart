import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/subscription_dialog.dart';
import 'package:flutter/cupertino.dart';
import '../../../main.dart';
import 'model/ai_chat_model.dart';
import 'model/chat_room_create_model.dart' hide Chat;
import 'model/create_ai_chat_model.dart';

class AiAssistantProvider extends ChangeNotifier {
  TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool showHistory = false;
  bool userStartedChatting = false;

  bool _isVoiceChat = false;
  bool get isVoiceChat => _isVoiceChat;

  // Speech recognition
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool get isListening => _isListening;

  // Track speech initialization status
  bool _speechInitialized = false;

  // Cleanup flag to prevent multiple initializations
  bool _isDisposed = false;

  Future<void> setVoiceChat(bool isVoiceChat) async {
    if (_isDisposed) return;

    _isVoiceChat = isVoiceChat;
    pt("_isVoiceChat $_isVoiceChat");

    if (isVoiceChat) {
      await _startListening();
    } else {
      _stopListening();
    }

    notifyListeners();
  }

  // Initialize speech recognition
  Future<bool> _initializeSpeech() async {
    if (_speechInitialized || _isDisposed) return _speechInitialized;

    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          pt("SpeechToText Status: $status");
          if (!_isListening) return;

          // Handle specific status changes
          if (status == "notListening" || status == "done") {
            if (_isVoiceChat) {
              // Only stop if voice chat is still active
              Future.microtask(() {
                _stopListening();
                _isVoiceChat = false;
                notifyListeners();
              });
            }
          }
        },
        onError: (error) {
          pt("SpeechToText Error: $error");
          if (_isListening) {
            Future.microtask(() {
              _stopListening();
              _isVoiceChat = false;
              notifyListeners();
            });
          }
          AppPopUp.showToast(message: "Speech recognition error: ${error.errorMsg}");
        },
      );

      if (!_speechInitialized) {
        pt("Speech recognition not available");
        AppPopUp.showToast(message: "Speech recognition not available on this device");
      }

      return _speechInitialized;
    } catch (e) {
      pt("Speech initialization error: $e");
      _speechInitialized = false;
      return false;
    }
  }

  Future<void> _startListening() async {
    if (_isDisposed) return;

    // Initialize if not already done
    if (!_speechInitialized) {
      final initialized = await _initializeSpeech();
      if (!initialized) {
        _isVoiceChat = false;
        notifyListeners();
        return;
      }
    }

    // Check if already listening
    if (_isListening || _speech.isListening) {
      pt("Already listening, stopping first...");
      await _stopListening();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          if (_isDisposed) return;

          if (result.finalResult) {
            final recognizedText = result.recognizedWords.trim();
            pt("Final speech result: $recognizedText");

            if (recognizedText.isNotEmpty) {
              messageController.text = recognizedText;
              notifyListeners();

              // Stop listening and send message
              Future.microtask(() async {
                await _stopListening();
                _isVoiceChat = false;
                notifyListeners();

                // Send the message after a short delay
                if (recognizedText.isNotEmpty) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  createChatMessages();
                }
              });
            } else {
              // Empty result, just stop
              Future.microtask(() async {
                await _stopListening();
                _isVoiceChat = false;
                notifyListeners();
              });
            }
          } else {
            // Update text in real-time for partial results
            final partialText = result.recognizedWords.trim();
            if (partialText.isNotEmpty) {
              messageController.text = partialText;
              notifyListeners();
            }
          }
        },
        listenFor: const Duration(seconds: 30), // Max listening time
        pauseFor: const Duration(seconds: 3), // Auto-stop if user pauses
        localeId: "en_US",
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      pt("Error starting speech recognition: $e");
      _isListening = false;
      _isVoiceChat = false;
      notifyListeners();
      AppPopUp.showToast(message: "Failed to start speech recognition");
    }
  }

  Future<void> _stopListening() async {
    if (_isDisposed) return;

    try {
      if (_isListening || _speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      pt("Error stopping speech recognition: $e");
    } finally {
      _isListening = false;
      notifyListeners();
    }
  }

  ///----------------------------------------------------------------------------------------
  ApiResponse<CreateAiChatRoomModel>? _createCharRoom = ApiResponse.completed(null);
  ApiResponse<CreateAiChatRoomModel>? get createCharRoom => _createCharRoom;

  void setCrateRoomData(ApiResponse<CreateAiChatRoomModel> response) {
    _createCharRoom = response;
    notifyListeners();
  }

  Future<void> createChatRoomApi() async {
    setCrateRoomData(ApiResponse.loading());
    notifyListeners();

    await repository.createChatRoom().then((value) async {
      if (value.success == true) {
        setCrateRoomData(ApiResponse.completed(value));
        pt(name: "response id conversaction", "${value.chat?.sId}");
        await SecureStorage.saveConversationId(value.chat?.sId ?? "");
        pt(name: "response", "${value.message}");
      }
      if (value.success == false) {
        setCrateRoomData(ApiResponse.error(value.message ?? "Something went wrong!"));
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setCrateRoomData(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    });
  }

  ////---------------------------------Get all ai chat

  ApiResponse<GetAiChatModel>? _allAiChatData = ApiResponse.completed(null);
  ApiResponse<GetAiChatModel>? get allAiChatData => _allAiChatData;

  void setAllAIChat(ApiResponse<GetAiChatModel> response) {
    _allAiChatData = response;
    notifyListeners();
  }

  Future<void> getAllAiChatModel() async {
    showHistory = true;
    notifyListeners();
    setAllAIChat(ApiResponse.loading());
    notifyListeners();

    await repository.getAllAiChat().then((value) async {
      if (value.success == true) {
        setAllAIChat(ApiResponse.completed(value));
        chatList = value.chats?.map((chat) {
          if (chat.role == "assistant") {
            return Chat(aiMessage: chat.content);
          } else {
            return Chat(userMessage: chat.content);
          }
        }).toList() ?? [];
        Future.delayed(const Duration(milliseconds: 50), () {
          scrollToBottom(immediate: true);
        });
      }
      if (value.success == false) {
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setAllAIChat(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    });
  }

  void startNewChat() {
    showHistory = false;
    chatList.clear();
    notifyListeners();
  }

  ///----------------------------
  ///

  ApiResponse<CreateAiChatModel>? _createAiChatData = ApiResponse.completed(null);
  ApiResponse<CreateAiChatModel>? get createAiChatData => _createAiChatData;

  void setCreateAIChat(ApiResponse<CreateAiChatModel> response) {
    _createAiChatData = response;
    notifyListeners();
  }

  List<Chat> chatList = [];

  void addUserMessage(String message) {
    chatList.add(Chat(userMessage: message));
    notifyListeners();
  }

  // Add AI message to the list
  void addAIMessage(Chat chat) {
    chatList.add(Chat(aiMessage: chat.aiMessage));
    notifyListeners();
  }

  Future<void> createChatMessages() async {
    if (messageController.text.isEmpty) {
      return AppPopUp.showToast(message: "Please enter your message", lineColor: AppColors.red);
    }

    final userMessage = messageController.text;

    setCreateAIChat(ApiResponse.loading());
    notifyListeners();
    addUserMessage(userMessage);

    Map<String, dynamic> data = {
      "conversationId": createCharRoom?.data?.chat?.sId ?? await SecureStorage.getConversationId(),
      "chatInput": userMessage,
      "message": userMessage,
    };

    // Clear message immediately
    messageController.clear();
    notifyListeners();

    await repository.createAiChat(data).then((value) async {
      if (value.success == true) {
        setCreateAIChat(ApiResponse.completed(value));
        if (value.chat != null) {
          addAIMessage(value.chat!);
        }
        Future.delayed(const Duration(milliseconds: 50), () {
          scrollToBottom(immediate: true);
        });      }
      if (value.success == false) {
        setCreateAIChat(ApiResponse.error(value.message));
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in createChatMessages: $error\n$stackTrace");
      setCreateAIChat(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    });
  }

  // void scrollToBottom() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (scrollController.hasClients) {
  //       if (scrollController.position.maxScrollExtent > 0) {
  //         scrollController.animateTo(
  //           scrollController.position.maxScrollExtent,
  //           duration: const Duration(milliseconds: 300),
  //           curve: Curves.easeOut,
  //         );
  //       }
  //     }
  //   });
  // }
  void scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        try {
          final maxExtent = scrollController.position.maxScrollExtent;
          final currentOffset = scrollController.offset;

          pt("Attempting to scroll - Current: $currentOffset, Max: $maxExtent");

          if (maxExtent > currentOffset) {
            if (immediate) {
              // Jump immediately
              scrollController.jumpTo(maxExtent);
              pt("Jumped to bottom");
            } else {
              // Animate smoothly
              scrollController.animateTo(
                maxExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ).then((_) {
                pt("Animated to bottom");
              }).catchError((error) {
                pt("Animation error: $error");
                // Try jumping as fallback
                try {
                  scrollController.jumpTo(maxExtent);
                  pt("Jumped after animation error");
                } catch (e) {
                  pt("Jump also failed: $e");
                }
              });
            }
          } else {
            pt("Already at bottom or no content to scroll");
          }
        } catch (e) {
          pt("Scroll error in callback: $e");
        }
      } else {
        pt("ScrollController has no clients, retrying...");
        // Try again after a delay if no clients
        Future.delayed(const Duration(milliseconds: 100), () {
          if (scrollController.hasClients) {
            scrollToBottom(immediate: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopListening();
    _speech.cancel();
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }
}