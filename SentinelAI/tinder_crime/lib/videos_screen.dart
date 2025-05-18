import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';

class VideoListScreen extends StatelessWidget {
  final List<CrimeVideo> videos;
  final bool isAuthority;
  final Function(String) onCrimeReported;

  const VideoListScreen({
    super.key,
    required this.videos,
    required this.isAuthority,
    required this.onCrimeReported,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          isAuthority: isAuthority,
          onCrimeReported: onCrimeReported,
        );
      },
    );
  }
}

class VideoDetailScreen extends StatefulWidget {
  final CrimeVideo video;
  final bool isAuthority;
  final Function(String) onCrimeReported;

  const VideoDetailScreen({
    super.key,
    required this.video,
    required this.isAuthority,
    required this.onCrimeReported,
  });

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;
  late MapController _mapController;
  bool _isMapExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
    _mapController = MapController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openInMapsApp() async {
    final url =
        'https://www.openstreetmap.org/?mlat=${widget.video.location.latitude}&mlon=${widget.video.location.longitude}#map=16/${widget.video.location.latitude}/${widget.video.location.longitude}';
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CrimeProbabilityIndicator(
                      probability: widget.video.crimeProbability),
                  const SizedBox(height: 16),
                  Text(
                    'Crime Type: ${widget.video.crimeType}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${widget.video.location.latitude.toStringAsFixed(6)}, '
                        '${widget.video.location.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMapExpanded = !_isMapExpanded;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isMapExpanded ? 300 : 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: widget.video.location,
                            zoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.crimedetection',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: widget.video.location,
                                  builder: (ctx) => const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openInMapsApp,
                    child: const Text('Open in Maps App'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.report),
                          label: const Text('Report to Authorities'),
                          onPressed: () {
                            _showReportDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Incident'),
          content: const Text(
              'Are you sure you want to report this incident to local authorities?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ReportedCrimesManager.reportCrime(widget.video);
                widget.onCrimeReported(widget.video.id);
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to main page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incident reported to authorities'),
                  ),
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }
}