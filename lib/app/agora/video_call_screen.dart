import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_appbar.dart';
import '../widgets/sizedbox.dart';
import 'video_call_controller.dart';
//
// class VideoCallScreen extends StatefulWidget {
//   @override
//   _VideoCallScreenState createState() => _VideoCallScreenState();
// }
//
// class _VideoCallScreenState extends State<VideoCallScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initVideoCall();
//   }
//
//   Future<void> _initVideoCall() async {
//     final videoCallProvider = Provider.of<VideoCallProvider>(context, listen: false);
//     await videoCallProvider.getVideoCallToken(
//       context: context,
//       channelName: "test_channel",
//       uid: "user_123",
//       role: "publisher",
//       sessionId: "session_123",
//       isCaller: true,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final videoCallProvider = Provider.of<VideoCallProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Call - ${videoCallProvider.formattedCallDuration}'),
//       ),
//       body: videoCallProvider.isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           // Local video preview
//           Expanded(
//             child: AgoraVideoView(
//               controller: VideoViewController(
//                 rtcEngine: videoCallProvider.engine,
//                 canvas: const VideoCanvas(uid: 0),
//               ),
//             ),
//           ),
//           // Remote video
//           if (videoCallProvider.remoteUid != null)
//             Expanded(
//               child: AgoraVideoView(
//                 controller: VideoViewController.remote(
//                   rtcEngine: videoCallProvider.engine,
//                   canvas: VideoCanvas(uid: videoCallProvider.remoteUid),
//                   connection: const RtcConnection(channelId: "test_channel"),
//                 ),
//               ),
//             ),
//           // Controls
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: Icon(videoCallProvider.isMicrophoneMuted
//                     ? Icons.mic_off : Icons.mic),
//                 onPressed: videoCallProvider.toggleMicrophone,
//               ),
//               IconButton(
//                 icon: Icon(videoCallProvider.isVideoMuted
//                     ? Icons.videocam_off : Icons.videocam),
//                 onPressed: videoCallProvider.toggleVideo,
//               ),IconButton(
//                 icon: Icon(videoCallProvider.isVideoMuted
//                     ? Icons.videocam_off : Icons.call_end,color: AppColors.red),
//                 onPressed: (){
//                   videoCallProvider.engine.leaveChannel();
//                   videoCallProvider.cleanup();
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     final videoCallProvider = Provider.of<VideoCallProvider>(context, listen: false);
//     videoCallProvider.cleanup();
//     super.dispose();
//   }
// }

class VideoCallScreen extends StatefulWidget {
  final bool isCaller;
  final String? sessionId;

  const VideoCallScreen({
    Key? key,
    this.isCaller = false,
    this.sessionId,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use a small delay to ensure context is available
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeVideoCall();
      }
    });
  }

  Future<void> _initializeVideoCall() async {
    if (!mounted) return;

    final videoCallProvider = context.read<VideoCallProvider>();

    // Get actual user ID from your auth system
    String? userId;
    try {
      // Try to get userId from your auth provider
      userId = await SecureStorage.getUserId(); // Adjust based on your auth structure
    } catch (e) {
      log("❌ Error getting user ID: $e");
    }

    // If no user ID found, use a fallback
    userId ??= "user_${DateTime.now().millisecondsSinceEpoch}";

    log("👤 Using User ID: $userId");

    try {
      await videoCallProvider.getVideoCallToken(
        context: context,
        sessionId: widget.sessionId ?? "session_${DateTime.now().millisecondsSinceEpoch}",
        channelName: "videoCall",
        uid: userId,
        role: "publisher", // Always publisher for video calls
        isCaller: widget.isCaller,
      );
    } catch (e) {
      log("❌ Error initializing video call: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: const Text("Video Call"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final videoCallProvider = context.read<VideoCallProvider>();
            await videoCallProvider.onBackPressed(context);
          },
        ),
      ),
      body: Consumer<VideoCallProvider>(
        builder: (context, videoCallProvider, child) {
          if (!_isInitialized || videoCallProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Initializing video call..."),
                ],
              ),
            );
          }

          if (!videoCallProvider.isJoined) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(videoCallProvider.isCaller ? "Starting call..." : "Joining call..."),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _retryConnection(videoCallProvider),
                    child: const Text("Retry Connection"),
                  ),
                  const SizedBox(height: 16),
                  if (videoCallProvider.error.isNotEmpty)
                    Text(
                      "Error: ${videoCallProvider.error}",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Remote video
              Center(
                child: _buildRemoteVideo(videoCallProvider),
              ),

              // Local video (floating window)
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: _buildLocalVideo(videoCallProvider),
                    ),
                  ),
                ),
              ),

              // Control buttons
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Microphone button
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.primary,
                      onPressed: () => videoCallProvider.toggleMicrophone(),
                      child: Icon(
                        videoCallProvider.isMicrophoneMuted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: Colors.white,
                      ),
                    ),

                    // Video button
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.white,
                      onPressed: () => videoCallProvider.toggleVideo(),
                      child: Icon(
                        videoCallProvider.isVideoMuted
                            ? Icons.videocam_off
                            : Icons.videocam,
                        color: AppColors.primary,
                      ),
                    ),

                    // Switch camera button
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.white,
                      onPressed: () => videoCallProvider.engine.switchCamera(),
                      child: const Icon(Icons.camera_front, color: AppColors.primary),
                    ),

                    // End call button
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.red,
                      onPressed: () => _endCall(videoCallProvider),
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemoteVideo(VideoCallProvider videoCallProvider) {
    if (videoCallProvider.remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: videoCallProvider.engine,
          canvas: VideoCanvas(uid: videoCallProvider.remoteUid),
          connection: const RtcConnection(channelId: 'videoCall'),
          useFlutterTexture: true,
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            videoCallProvider.isCaller
                ? "Waiting for receiver to join..."
                : "Connected! Waiting for video...",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
    }
  }

  Widget _buildLocalVideo(VideoCallProvider videoCallProvider) {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: videoCallProvider.engine,
        canvas: const VideoCanvas(uid: 0),
        useFlutterTexture: true,
      ),
    );
  }

  Future<void> _retryConnection(VideoCallProvider videoCallProvider) async {
    // Get user ID again
    String? userId;
    try {
      userId = await SecureStorage.getUserId();
    } catch (e) {
      userId = "user_${DateTime.now().millisecondsSinceEpoch}";
    }

    await videoCallProvider.getVideoCallToken(
      context: context,
      sessionId: widget.sessionId ?? "session_${DateTime.now().millisecondsSinceEpoch}",
      channelName: "videoCall",
      uid: userId ?? "",
      role: "publisher",
      isCaller: widget.isCaller,
    );
  }

  Future<void> _endCall(VideoCallProvider videoCallProvider) async {
    bool shouldEnd = await _showEndCallConfirmation();
    if (!shouldEnd) return;

    await videoCallProvider.endCall(context, isManual: true);
  }

  Future<bool> _showEndCallConfirmation() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Call"),
        content: const Text("Are you sure you want to end the call?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("End Call", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _leaveCall()  async{
   WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
     final videoCallProvider = context.read<VideoCallProvider>();
     try {
       await videoCallProvider.engine.leaveChannel();
       videoCallProvider.cleanup();
     } catch (e) {
       log("Error leaving call: $e");
     }
   },);
  }

  @override
  void dispose() {
    log("🎬 VideoCallScreen disposing...");

    try {
      final videoCallProvider = context.read<VideoCallProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // Only cleanup if call is active
          if (videoCallProvider.isInCall || videoCallProvider.isJoined) {
            log("🛑 Active call detected, cleaning up...");
            videoCallProvider.endCall(null);
          } else {
            videoCallProvider.cleanup();
          }
        } catch (e) {
          log("Error in dispose cleanup: $e");
        }
      });
    } catch (e) {
      log("Error getting provider in dispose: $e");
    }

    super.dispose();
  }
}