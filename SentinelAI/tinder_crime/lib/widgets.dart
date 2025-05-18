import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'videos_screen.dart';

class VideoCard extends StatelessWidget {
  final CrimeVideo video;
  final bool isAuthority;
  final Function(String) onCrimeReported;

  const VideoCard({
    super.key,
    required this.video,
    required this.isAuthority,
    required this.onCrimeReported,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailScreen(
                video: video,
                isAuthority: isAuthority,
                onCrimeReported: onCrimeReported,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                VideoThumbnail(videoUrl: video.videoUrl),
                CrimeProbabilityIndicator(probability: video.crimeProbability),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${video.location.latitude.toStringAsFixed(4)}, '
                            '${video.location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        _formatDateTime(video.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class VideoThumbnail extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnail({super.key, required this.videoUrl});

  @override
  _VideoThumbnailState createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isInitialized)
            const Center(child: CircularProgressIndicator()),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _isPlaying ? _controller.play() : _controller.pause();
              });
            },
          ),
        ],
      ),
    );
  }
}

class CrimeProbabilityIndicator extends StatelessWidget {
  final double probability;

  const CrimeProbabilityIndicator({super.key, required this.probability});

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (probability > 0.8) return Colors.red;
      if (probability > 0.6) return Colors.orange;
      return Colors.yellow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(
        '${(probability * 100).toStringAsFixed(0)}% Crime',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}