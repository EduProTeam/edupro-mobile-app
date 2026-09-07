import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';

class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({
    super.key,
    required this.url,
    this.storagePath,
    this.onRefreshUrl,
  });

  final String url;
  final String? storagePath;
  final Future<String> Function(String path)? onRefreshUrl;

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initialization;
  late String _url = widget.url;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.dispose();
      _url = widget.url;
      _initialize();
    }
  }

  void _initialize() {
    final uri = Uri.tryParse(_url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse('about:blank'));
      _initialization = Future<void>.error('The stored video URL is invalid.');
      return;
    }
    _controller = VideoPlayerController.networkUrl(uri);
    _initialization = _controller.initialize().catchError((error) {
      debugPrint('Lesson video initialization failed: $error');
      throw error;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    _controller.dispose();
    if (widget.storagePath != null && widget.onRefreshUrl != null) {
      try {
        final refreshed = await widget.onRefreshUrl!(widget.storagePath!);
        if (!mounted) return;
        setState(() {
          _url = refreshed;
          _initialize();
        });
        return;
      } catch (error) {
        debugPrint('Lesson video URL refresh failed: $error');
      }
    }
    if (mounted) setState(_initialize);
  }

  Future<void> _openFullscreen() async {
    if (!_controller.value.isInitialized || !mounted) return;
    await _controller.pause();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenLessonVideo(url: _url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _VideoMessage(
            icon: Icons.error_outline,
            message: 'This video could not be loaded.',
            detail: _videoErrorMessage(snapshot.error),
            action: TextButton(onPressed: _retry, child: const Text('Retry')),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                Align(
                  alignment: Alignment.center,
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller,
                    builder: (context, value, child) => DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                        color: Colors.white,
                        iconSize: 34,
                        onPressed: () => value.isPlaying
                            ? _controller.pause()
                            : _controller.play(),
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                    ),
                  ),
                ),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: OnboardingScreenLayout.primaryBlue,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 10,
                  child: IconButton(
                    tooltip: 'Open fullscreen',
                    onPressed: _openFullscreen,
                    color: Colors.white,
                    icon: const Icon(Icons.fullscreen),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _videoErrorMessage(Object? error) {
    final text = '$error';
    if (text.contains('Source error') || text.contains('HttpDataSource')) {
      return 'The video URL expired or the file is not reachable.';
    }
    if (text.contains('Decoder') || text.contains('MediaCodec')) {
      return 'This Android device does not support the video codec.';
    }
    return 'Check the uploaded file and try again.';
  }
}

class _FullscreenLessonVideo extends StatefulWidget {
  const _FullscreenLessonVideo({required this.url});

  final String url;

  @override
  State<_FullscreenLessonVideo> createState() => _FullscreenLessonVideoState();
}

class _FullscreenLessonVideoState extends State<_FullscreenLessonVideo> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialization = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  'Unable to load video',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return SafeArea(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Row(
                    children: [
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) => IconButton(
                          color: Colors.white,
                          icon: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () => value.isPlaying
                              ? _controller.pause()
                              : _controller.play(),
                        ),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: OnboardingScreenLayout.primaryBlue,
                            bufferedColor: Colors.white54,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Exit fullscreen',
                        color: Colors.white,
                        icon: const Icon(Icons.fullscreen_exit),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VideoMessage extends StatelessWidget {
  const _VideoMessage({
    required this.icon,
    required this.message,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F6FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: OnboardingScreenLayout.primaryBlue),
              const SizedBox(height: 6),
              Text(message),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
