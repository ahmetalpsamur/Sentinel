import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'models.dart';
import 'videos_screen.dart';

class VideoCard extends StatefulWidget {
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
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _openDetailScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(
          video: widget.video,
          isAuthority: widget.isAuthority,
          onCrimeReported: widget.onCrimeReported,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final hasWeaponInfo = widget.video.weaponType != null &&
        widget.video.weaponProbability != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player Section with Play/Pause
          GestureDetector(
            onTap: _togglePlayPause,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _isInitialized
                        ? VideoPlayer(_controller)
                        : Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient Overlay
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Indicators Row
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      CrimeProbabilityIndicator(
                        probability: widget.video.crimeProbability,
                        type: 'crime',
                      ),
                      if (hasWeaponInfo)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: CrimeProbabilityIndicator(
                            probability: widget.video.weaponProbability!,
                            type: 'weapon',
                            weaponType: widget.video.weaponType,
                          ),
                        ),
                    ],
                  ),
                ),

                // Play/Pause Button
                if (_isInitialized)
                  Positioned.fill(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Iconsax.pause : Iconsax.play,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video Details Section - Tappable for details
          InkWell(
            onTap: () => _openDetailScreen(context),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCrimeTypeColor(widget.video.crimeType),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.video.crimeType,
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description and Weapon Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.description,
                        style: GoogleFonts.rajdhani(
                          color: Colors.grey[400],
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasWeaponInfo)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.danger,
                                size: 14,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.video.weaponType} (${(widget.video.weaponProbability! * 100).toStringAsFixed(0)}%)',
                                style: GoogleFonts.rajdhani(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Location and Time
                  Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.video.location.latitude.toStringAsFixed(4)}, '
                              '${widget.video.location.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.rajdhani(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Iconsax.clock,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(widget.video.timestamp),
                        style: GoogleFonts.rajdhani(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
}

class CrimeProbabilityIndicator extends StatelessWidget {
  final double probability;
  final String type; // 'crime' or 'weapon'
  final String? weaponType;

  const CrimeProbabilityIndicator({
    super.key,
    required this.probability,
    required this.type,
    this.weaponType,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (probability > 0.8) return Colors.red[700]!;
      if (probability > 0.6) return Colors.orange[700]!;
      return Colors.yellow[700]!;
    }

    IconData getIcon() {
      return type == 'weapon' ? Iconsax.danger : Iconsax.warning_2;
    }

    String getText() {
      if (type == 'weapon' && weaponType != null) {
        return '${(probability * 100).toStringAsFixed(0)}%';
      }
      return '${(probability * 100).toStringAsFixed(0)}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: getColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getIcon(),
            color: getColor(),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            getText(),
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}