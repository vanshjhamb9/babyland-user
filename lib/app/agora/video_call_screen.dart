import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_appbar.dart';
import 'video_call_controller.dart';

/// Live video call screen.
///
/// All Agora credentials ([AgoraRtcSessionDto]) must come from the backend
/// via `POST /agoras/rtc` before this screen opens — never hardcoded locally.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.backendSession,
  });

  final AgoraRtcSessionDto backendSession;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isInitialized = false;
  bool _isRetrying = false;
  AgoraRtcSessionDto? _session;

  @override
  void initState() {
    super.initState();
    _session = widget.backendSession;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _initializeVideoCall();
    });
  }

  Future<void> _initializeVideoCall({AgoraRtcSessionDto? session}) async {
    if (!mounted) return;
    final dto = session ?? _session ?? widget.backendSession;
    final videoCallProvider = context.read<VideoCallProvider>();
    try {
      await videoCallProvider.joinConsultationWithBackendRtc(
        context: context,
        dto: dto,
      );
    } catch (e) {
      log('Error initializing video call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: const Text('Video Call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await context.read<VideoCallProvider>().onBackPressed(context);
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
                  Text('Connecting to your consultation…'),
                ],
              ),
            );
          }

          if (!videoCallProvider.isJoined) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRetrying || videoCallProvider.isLoading)
                    const CircularProgressIndicator()
                  else
                    Icon(Icons.videocam_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _isRetrying || videoCallProvider.isLoading
                        ? 'Joining call…'
                        : 'Could not connect to the video channel',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_isRetrying || videoCallProvider.isLoading)
                        ? null
                        : () => _retryConnection(videoCallProvider),
                    child: Text(_isRetrying ? 'Retrying…' : 'Retry Connection'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go back'),
                  ),
                  const SizedBox(height: 16),
                  if (videoCallProvider.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        videoCallProvider.error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              Center(child: _buildRemoteVideo(videoCallProvider)),
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
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.primary,
                      onPressed: videoCallProvider.toggleMicrophone,
                      child: Icon(
                        videoCallProvider.isMicrophoneMuted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.white,
                      onPressed: videoCallProvider.toggleVideo,
                      child: Icon(
                        videoCallProvider.isVideoMuted
                            ? Icons.videocam_off
                            : Icons.videocam,
                        color: AppColors.primary,
                      ),
                    ),
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.white,
                      onPressed: () => videoCallProvider.engine.switchCamera(),
                      child: const Icon(Icons.camera_front, color: AppColors.primary),
                    ),
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
    final channel =
        videoCallProvider.activeBackendSession?.channelName ??
        _session?.channelName ??
        widget.backendSession.channelName;
    if (videoCallProvider.remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: videoCallProvider.engine,
          canvas: VideoCanvas(uid: videoCallProvider.remoteUid),
          connection: RtcConnection(channelId: channel),
          useFlutterTexture: true,
        ),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Waiting for the doctor to join…'),
      ],
    );
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
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      final session = _session ?? widget.backendSession;
      AgoraRtcSessionDto fresh;
      try {
        fresh = await videoCallProvider.refreshBackendSession();
      } catch (_) {
        fresh = session;
      }
      _session = fresh;
      await _initializeVideoCall(session: fresh);
    } catch (e) {
      log('Retry connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  Future<void> _endCall(VideoCallProvider videoCallProvider) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end the call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldEnd != true) return;
    await videoCallProvider.endCall(context, isManual: true);
  }

  @override
  void dispose() {
    log('VideoCallScreen disposing…');
    try {
      final videoCallProvider = context.read<VideoCallProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (videoCallProvider.isInCall || videoCallProvider.isJoined) {
          videoCallProvider.endCall(null);
        } else {
          videoCallProvider.cleanup();
        }
      });
    } catch (e) {
      log('Error in dispose cleanup: $e');
    }
    super.dispose();
  }
}
