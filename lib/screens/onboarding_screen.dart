import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:camera/camera.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hotspot_hosts/widget/background.dart';
import 'package:hotspot_hosts/widget/app_bar.dart';
import 'package:hotspot_hosts/models/recording_model.dart';

class OnboardingSelectionScreen extends ConsumerStatefulWidget {
  const OnboardingSelectionScreen({super.key});

  @override
  ConsumerState<OnboardingSelectionScreen> createState() =>
      _ExperienceRecordingScreenState();
}

class _ExperienceRecordingScreenState
    extends ConsumerState<OnboardingSelectionScreen>
    with WidgetsBindingObserver {
  final record = AudioRecorder();
  CameraController? _cameraController;

  bool isRecordingAudio = false;
  bool hasAudio = false;
  bool hasVideo = false;
  bool isKeyboardVisible = false;
  bool isVideoRecording = false;

  String? audioPath;
  String? videoPath;

  Duration audioDuration = Duration.zero;
  Timer? timer;
  RecorderController? waveformController;
  late Box recordingsBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initHive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    timer?.cancel();
    waveformController?.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final keyboardVisible =
        WidgetsBinding.instance.window.viewInsets.bottom > 0;
    setState(() => isKeyboardVisible = keyboardVisible);
  }

  Future<void> initHive() async {
    recordingsBox = Hive.box('recordings');
    if (recordingsBox.containsKey('audio')) {
      hasAudio = true;
      audioPath = recordingsBox.get('audio').filePath;
    }
    if (recordingsBox.containsKey('video')) {
      hasVideo = true;
      videoPath = recordingsBox.get('video').filePath;
    }
    setState(() {});
  }

Future<void> startAudioRecording() async {
  if (isRecordingAudio) return;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    waveformController = RecorderController();
    await waveformController!.record(path: path);

    setState(() {
      isRecordingAudio = true;
      audioPath = path;
      audioDuration = Duration.zero;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => audioDuration += const Duration(seconds: 1));
    });
  } catch (e) {
    debugPrint("Error starting audio recording: $e");
  }
}

Future<void> stopAudioRecording() async {
  try {
    await waveformController?.stop();
    waveformController?.dispose(); 
    waveformController = null;

    timer?.cancel();

    if (audioPath != null) {
      recordingsBox.put('audio', Recording(type: 'audio', filePath: audioPath!));
      setState(() {
        isRecordingAudio = false;
        hasAudio = true;
      });
    }
  } catch (e) {
    debugPrint("Error stopping audio recording: $e");
  }
}

Widget _buildRecordedAudioUI() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.play_circle_fill,
              color: Colors.blueAccent, size: 30),
          onPressed: () async {
            try {
              if (audioPath == null || !File(audioPath!).existsSync()) {
                debugPrint("No audio file found to play.");
                return;
              }
              final player = AudioPlayer();
              await player.play(DeviceFileSource(audioPath!));
            } catch (e) {
              debugPrint("Error playing audio: $e");
            }
          },
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            "Audio Recorded",
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white70),
          onPressed: deleteAudio,
        ),
      ],
    ),
  );
}

Future<void> deleteAudio() async {
  try {
    await recordingsBox.delete('audio');
    if (audioPath != null && File(audioPath!).existsSync()) {
      await File(audioPath!).delete();
    }

    setState(() {
      hasAudio = false;
      audioPath = null;
    });
  } catch (e) {
    debugPrint("Error deleting audio: $e");
  }
}

  Future<void> startVideoRecording() async {
    if (isVideoRecording) return;
    setState(() => isVideoRecording = true);

    try {
      final cameras = await availableCameras().timeout(
  const Duration(seconds: 3),
  onTimeout: () {
    throw Exception("Camera not available or taking too long");
  },
);

      final camera = cameras.first;
  if (!mounted) return;

      _cameraController = CameraController(camera, ResolutionPreset.medium);
      await _cameraController!.initialize();

      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) {
              bool isRecording = false;
              bool isSaved = false;

              Future<void> startRecording() async {
                if (isRecording || isSaved) return;
                try {
                  await _cameraController!.startVideoRecording();
                  setModalState(() => isRecording = true);
                } catch (e) {
                  debugPrint('Error starting video: $e');
                }
              }

              Future<void> stopRecording() async {
                if (!_cameraController!.value.isRecordingVideo) return;
                try {
                  final dir = await getApplicationDocumentsDirectory();
                  final vidPath =
                      '${dir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
                  final file = await _cameraController!.stopVideoRecording();
                  await file.saveTo(vidPath);
                  videoPath = vidPath;

                  recordingsBox.put(
                      'video', Recording(type: 'video', filePath: vidPath));
                  hasVideo = true;
                  isSaved = true;

                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                } catch (e) {
                  debugPrint('Error stopping video: $e');
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }

              Future<void> closeCamera() async {
                try {
                  if (_cameraController != null &&
                      _cameraController!.value.isRecordingVideo) {
                    await _cameraController!.stopVideoRecording();
                  }
                } catch (e) {
                  debugPrint('Error closing camera: $e');
                }
                if (_cameraController != null) {
                  await _cameraController!.dispose();
                  _cameraController = null;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }

              return Scaffold(
                backgroundColor: Colors.black,
                body: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                      CameraPreview(_cameraController!),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 32),
                        onPressed: closeCamera,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isRecording
                            ? ElevatedButton(
                                key: const ValueKey('stop'),
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.all(24),
                                ),
                                onPressed: stopRecording,
                                child: const Icon(Icons.stop,
                                    color: Colors.white, size: 36),
                              )
                            : ElevatedButton(
                                key: const ValueKey('record'),
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(24),
                                ),
                                onPressed: startRecording,
                                child: const Icon(Icons.fiber_manual_record,
                                    color: Colors.white, size: 36),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      setState(() => isVideoRecording = false);
    }
  }

  Future<void> deleteVideo() async {
    await recordingsBox.delete('video');
    if (videoPath != null && File(videoPath!).existsSync()) {
      File(videoPath!).deleteSync();
    }
    setState(() {
      hasVideo = false;
      videoPath = null;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color.fromRGBO(145, 150, 255, 1);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: DiagonalWavyBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    EdgeInsets.only(bottom: viewInsets > 0 ? viewInsets : 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const CustomAppBar(
                            progressPercent: 0.6, useGradient: true),
                        const SizedBox(height: 120),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("02",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: 6),
                              Text("Why do you want to host with us?",
                                  style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text(
                                "Tell us about your intent and what motivates you to create experiences.",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Focus(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 139),
                              child: TextField(
                                maxLines: null,
                                textAlignVertical: TextAlignVertical.top,
                                expands: true,
                                maxLength: 600,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(600),
                                ],
                                buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    required maxLength}) {
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "/ Start typing here",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.3,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color.fromRGBO(145, 150, 255, 1),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 16),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Builder(builder: (_) {
                            if (isRecordingAudio) {
                              return _buildAudioRecordingUI(accent);
                            } else if (hasAudio && audioPath != null) {
                              return _buildRecordedAudioUI();
                            } else if (hasVideo && videoPath != null) {
                              return _buildRecordedVideoUI();
                            } else {
                              return const SizedBox.shrink();
                            }
                          }),
                        ),

                        const Spacer(),
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

    Widget _buildBottomButtons() {
  final showBoth = !hasAudio && !hasVideo;
  bool isHovering = false;

  return AnimatedPadding(
    duration: const Duration(milliseconds: 300),
    padding: EdgeInsets.only(
        bottom: isKeyboardVisible ? 10 : 30, left: 16, right: 16),
    child: StatefulBuilder(
      builder: (context, localSetState) {
        return Row(
          mainAxisAlignment:
              showBoth ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: showBoth ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: showBoth
                  ? Row(
                      children: [
                        _buildCircleButton(
                            icon: Icons.mic,
                            label: "Audio",
                            onTap: startAudioRecording),
                        const SizedBox(width: 16),
                        _buildCircleButton(
                            icon: Icons.videocam,
                            label: "Video",
                            onTap: startVideoRecording),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: showBoth ? 200 : MediaQuery.of(context).size.width - 50,
              height: 56,
              child: MouseRegion(
                onEnter: (_) => localSetState(() => isHovering = true),
                onExit: (_) => localSetState(() => isHovering = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHovering
                          ? [
                              Colors.black.withOpacity(0.8),
                              Colors.white.withOpacity(0.9),
                              Colors.black.withOpacity(0.8),
                            ]
                          : [
                              Colors.black.withOpacity(0.6),
                              Colors.white.withOpacity(0.4),
                              Colors.black.withOpacity(0.6),
                            ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                    boxShadow: isHovering
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: (hasAudio || hasVideo)
                        ? () => debugPrint("Next pressed")
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Next",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white70, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildAudioRecordingUI(Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () async {
              timer?.cancel();
              await waveformController?.stop();
              setState(() => isRecordingAudio = false);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: AudioWaveforms(
                enableGesture: false,
                size: Size(MediaQuery.of(context).size.width * 0.6, 40),
                recorderController: waveformController!,
                waveStyle: WaveStyle(
                  waveColor: accent,
                  extendWaveform: true,
                  showMiddleLine: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(_formatDuration(audioDuration),
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            onPressed: stopAudioRecording,
          ),
        ],
      ),
    );
  }

  // Widget _buildRecordedAudioUI() {
  //   return Container(
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[900],
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Row(
  //       children: [
  //         IconButton(
  //           icon: const Icon(Icons.play_circle_fill,
  //               color: Colors.blueAccent, size: 30),
  //           onPressed: () async {
  //             final player = AudioPlayer();
  //             await player.play(DeviceFileSource(audioPath!));
  //           },
  //         ),
  //         const SizedBox(width: 8),
  //         const Expanded(
  //           child: Text("Audio Recorded",
  //               style: TextStyle(color: Colors.white70)),
  //         ),
  //         IconButton(
  //             icon: const Icon(Icons.delete_outline, color: Colors.white70),
  //             onPressed: deleteAudio),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRecordedVideoUI() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Colors.purpleAccent, size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child:
                Text("Video Recorded", style: TextStyle(color: Colors.white70)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: deleteVideo,
          ),
        ],
      ),
    );
  }
}
