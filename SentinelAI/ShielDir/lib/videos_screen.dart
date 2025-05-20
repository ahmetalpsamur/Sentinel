import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _videoController;
  late MapController _mapController;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _isMapExpanded = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _mapController = MapController();
  }

  Future<void> _initializePlayer() async {
    try {
      MediaKit.ensureInitialized();
      _player = Player();
      _videoController = VideoController(_player);

      // Player event listeners
      _player.stream.error.listen((error) {
        debugPrint('Video error: $error');
      });

      _player.stream.playing.listen((playing) {
        if (_isDisposed) return;
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      // Open media but don't auto-play
      await _player.open(Media(widget.video.videoUrl), play: true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Player initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video yüklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Uygulama arka plana geçtiğinde videoyu durdur
      _player.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar açıldığında kontrolleri güncelle
      if (mounted) {
        setState(() {
          _isPlaying = _player.state.playing;
        });
      }
    }
  }

  Future<void> _openInMapsApp() async {
    final url =
        'https://www.openstreetmap.org/?mlat=${widget.video.location.latitude}&mlon=${widget.video.location.longitude}#map=16/${widget.video.location.latitude}/${widget.video.location.longitude}';
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harita uygulaması açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _toggleControls() {
    if (_isDisposed) return;
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isDisposed && mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
        backgroundColor: Colors.grey[900],
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.more),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Player Section
              GestureDetector(
                onTap: _toggleControls,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _isInitialized
                          ? Video(
                        controller: _videoController,
                        controls: null,
                      )
                          : Container(
                        color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ),

                    // Video Controls
                    if (_isInitialized)
                      AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                _isPlaying ? Iconsax.pause : Iconsax.play,
                                size: 48,
                                color: Colors.white,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Video Details Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Title and Crime Type
                Row(
                children: [
                Expanded(
                child: Text(
                  widget.video.title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getCrimeTypeColor(widget.video.crimeType),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.video.crimeType,
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Crime Probability and Timestamp
          Row(
            children: [
              CrimeProbabilityIndicator(
                probability: widget.video.crimeProbability,
                type: widget.video.crimeType,
                weaponType: widget.video.weaponType,
              ),
              const SizedBox(width: 16),
              Icon(
                Iconsax.clock,
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(widget.video.timestamp),
                style: GoogleFonts.rajdhani(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            widget.video.description,
            style: GoogleFonts.rajdhani(
              color: Colors.grey[300],
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Location Header
          Row(
            children: [
              Icon(
                Iconsax.location,
                color: Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Incident Location',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Coordinates
          Text(
            '${widget.video.location.latitude.toStringAsFixed(6)}, '
                '${widget.video.location.longitude.toStringAsFixed(6)}',
            style: GoogleFonts.rajdhani(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Map
          GestureDetector(
            onTap: () {
              setState(() {
                _isMapExpanded = !_isMapExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isMapExpanded ? 300 : 180,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                        width: 60,
                        height: 60,
                        point: widget.video.location,
                        builder: (ctx) => Icon(
                          Iconsax.location,
                          color: Colors.red[700],
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

        const SizedBox(height: 16),

        // Map Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Iconsax.map),
                label: const Text('Open in Maps'),
                onPressed: _openInMapsApp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Iconsax.gps),
              onPressed: () {
                _mapController.move(
                  widget.video.location,
                  _mapController.zoom,
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Report Button
        if (!widget.isAuthority)
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Iconsax.warning_2),
        label: const Text('Report to Authorities'),
        onPressed: () => _showReportDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
  }

  Color _getCrimeTypeColor(String crimeType) {
    switch (crimeType.toLowerCase()) {
      case 'assault':
        return Colors.red[800]!;
      case 'theft':
        return Colors.orange[800]!;
      case 'vandalism':
        return Colors.yellow[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.warning_2,
                  color: Colors.red[700],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Report Incident',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to report this incident to local authorities?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                    color: Colors.grey[300],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ReportedCrimesManager.reportCrime(widget.video);
                          widget.onCrimeReported(widget.video.id);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Incident reported to authorities',
                                style: GoogleFonts.rajdhani(),
                              ),
                              backgroundColor: Colors.red[800],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}