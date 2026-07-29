import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Spiller av en instruksjonsvideo fra bonusvarsel/info i Cloudinary.
///
/// Bruk:  InfoVideo(name: 'trumf-bruk-bonus-overforing')
/// Viser forhåndsbilde med play-knapp; videoen lastes først når brukeren
/// trykker (sparer data). Trykk pauser/fortsetter. Feil gir en diskret
/// boks - aldri krasj.
class InfoVideo extends StatefulWidget {
  const InfoVideo({
    super.key,
    required this.name,
    this.maxHeight = 340,
    this.borderRadius = 12,
  });

  /// Filnavnet i bonusvarsel/info, uten sti og uten filendelse
  final String name;
  final double maxHeight;
  final double borderRadius;

  @override
  State<InfoVideo> createState() => _InfoVideoState();
}

class _InfoVideoState extends State<InfoVideo> {
  static const String _base =
      'https://res.cloudinary.com/ds3xrvivm/video/upload';

  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  String get _videoUrl =>
      '$_base/f_auto:video,q_auto,w_608/bonusvarsel/info/${widget.name}.mp4';

  String get _posterUrl =>
      '$_base/so_0,w_608,f_jpg/bonusvarsel/info/${widget.name}.jpg';

  Future<void> _startPlayback() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(_videoUrl));
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      controller.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _togglePause() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Video ikke tilgjengelig',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }

    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: controller == null ? _poster() : _player(controller),
      ),
    );
  }

  Widget _poster() {
    return GestureDetector(
      onTap: _startPlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            _posterUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              width: double.infinity,
              color: Colors.black26,
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow,
                    color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _player(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _togglePause,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 36),
              ),
          ],
        ),
      ),
    );
  }
}
