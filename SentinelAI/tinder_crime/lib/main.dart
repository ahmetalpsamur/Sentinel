import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const CrimeDetectionApp());
}

class CrimeDetectionApp extends StatelessWidget {
  const CrimeDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crime Swiper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Authentication Screen
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAuthority = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate authentication
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CrimeDetectionHomePage(
          isAuthority: _isAuthority,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crime Swiper Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _isAuthority,
                    onChanged: (value) {
                      setState(() {
                        _isAuthority = value ?? false;
                      });
                    },
                  ),
                  const Text('I am a law enforcement authority'),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Crime Video Model
class CrimeVideo {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final double crimeProbability;
  final LatLng location;
  final DateTime timestamp;
  final String crimeType;

  const CrimeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.crimeProbability,
    required this.location,
    required this.timestamp,
    required this.crimeType,
  });
}

// Reported Crime Model
class ReportedCrime {
  final CrimeVideo crimeVideo;
  final DateTime reportedTime;
  String status;
  String? notes;
  String? assignedOfficer;

  ReportedCrime({
    required this.crimeVideo,
    required this.reportedTime,
    this.status = 'Pending',
    this.notes,
    this.assignedOfficer,
  });
}

// Crime Report Manager
class ReportedCrimesManager {
  static final List<ReportedCrime> _reportedCrimes = [];
  static final List<String> _officers = [
    'Officer Smith',
    'Detective Johnson',
    'Sergeant Williams',
    'Lieutenant Brown'
  ];

  static void reportCrime(CrimeVideo crime) {
    _reportedCrimes.add(ReportedCrime(
      crimeVideo: crime,
      reportedTime: DateTime.now(),
    ));
  }

  static List<ReportedCrime> get reportedCrimes => _reportedCrimes;
  static List<String> get officers => _officers;

  static void updateStatus(String crimeId, String newStatus, {String? notes, String? officer}) {
    final crime = _reportedCrimes.firstWhere((c) => c.crimeVideo.id == crimeId);
    crime.status = newStatus;
    if (notes != null) crime.notes = notes;
    if (officer != null) crime.assignedOfficer = officer;
  }

  static List<ReportedCrime> searchCrimes(String query) {
    if (query.isEmpty) return _reportedCrimes;
    return _reportedCrimes.where((crime) {
      return crime.crimeVideo.title.toLowerCase().contains(query.toLowerCase()) ||
          crime.crimeVideo.crimeType.toLowerCase().contains(query.toLowerCase()) ||
          crime.status.toLowerCase().contains(query.toLowerCase()) ||
          (crime.assignedOfficer?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }
}

// Main Home Page
class CrimeDetectionHomePage extends StatefulWidget {
  final bool isAuthority;
  final List<CrimeVideo> initialCrimeVideos = [
    CrimeVideo(
      id: '1',
      title: 'Suspicious Activity in Parking Lot',
      description: 'Possible car break-in detected at 3:15 AM',
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      crimeProbability: 0.10,
      location: const LatLng(38.374564, 27.039499),
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      crimeType: 'Theft',
    ),
    CrimeVideo(
      id: '2',
      title: 'Altercation Near ATM',
      description: 'Two individuals in physical confrontation',
      videoUrl: 'https://example.com/videos/atm_altercation.mp4',
      crimeProbability: 0.92,
      location: const LatLng(38.361564, 27.539499),
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      crimeType: 'Assault',
    ),
    CrimeVideo(
      id: '3',
      title: 'Vandalism in Subway Station',
      description: 'Individual spray painting on walls',
      videoUrl: 'https://example.com/videos/vandalism.mp4',
      crimeProbability: 0.78,
      location: const LatLng(38.304064, 27.009099),
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      crimeType: 'Vandalism',
    ),
    CrimeVideo(
      id: '4',
      title: 'Package Theft from Porch',
      description: 'Person taking package from residential porch',
      videoUrl: 'https://example.com/videos/package_theft.mp4',
      crimeProbability: 0.85,
      location: const LatLng(38.304564, 26.039409),
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      crimeType: 'Theft',
    ),
  ];

  CrimeDetectionHomePage({super.key, required this.isAuthority});

  @override
  _CrimeDetectionHomePageState createState() => _CrimeDetectionHomePageState();
}

class _CrimeDetectionHomePageState extends State<CrimeDetectionHomePage> {
  int _selectedIndex = 0;
  late List<CrimeVideo> _crimeVideos;

  @override
  void initState() {
    super.initState();
    _crimeVideos = List.from(widget.initialCrimeVideos);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _removeReportedCrime(String crimeId) {
    setState(() {
      _crimeVideos.removeWhere((crime) => crime.id == crimeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Swiper'),
      ),
      body: _selectedIndex == 0
          ? VideoListScreen(
        videos: _crimeVideos,
        isAuthority: widget.isAuthority,
        onCrimeReported: _removeReportedCrime,
      )
          : _selectedIndex == 1
          ? const ReportedCrimesScreen()
          : AnalyticsScreen(videos: widget.initialCrimeVideos, isAuthority: widget.isAuthority),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          if (widget.isAuthority)
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

// Video List Screen
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

// Video Card Widget
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

// Video Thumbnail Widget
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

// Crime Probability Indicator Widget
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

// Video Detail Screen
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

// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  final List<CrimeVideo> videos;
  final bool isAuthority;

  const AnalyticsScreen({super.key, required this.videos, required this.isAuthority});

  @override
  Widget build(BuildContext context) {
    // Prepare data for charts
    final crimeTypeCount = _countCrimeTypes(videos);
    final hourlyDistribution = _calculateHourlyDistribution(videos);
    final severityDistribution = _calculateSeverityDistribution(videos);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crime Statistics Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._buildSummaryCards(videos),
            const SizedBox(height: 20),
            const Text(
              'Crime Type Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  ColumnSeries<MapEntry<String, int>, String>(
                    dataSource: crimeTypeCount.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.blue,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hourly Crime Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(interval: 2),
                series: <ChartSeries>[
                  LineSeries<MapEntry<int, int>, int>(
                    dataSource: hourlyDistribution.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.red,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Crime Severity Levels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<MapEntry<String, int>, String>(
                    dataSource: severityDistribution.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Crime Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  center: const LatLng(38.874564, 35.039499),
                  zoom: 5.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.crimedetection',
                  ),
                  MarkerLayer(
                    markers: videos.map((video) => Marker(
                      point: video.location,
                      builder: (ctx) => Icon(
                        Icons.location_pin,
                        color: _getSeverityColor(video.crimeProbability),
                        size: 30,
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(double probability) {
    if (probability > 0.8) return Colors.red;
    if (probability > 0.6) return Colors.orange;
    return Colors.yellow;
  }

  List<Widget> _buildSummaryCards(List<CrimeVideo> videos) {
    final totalCrimes = videos.length;
    final highRiskCrimes = videos.where((v) => v.crimeProbability > 0.8).length;
    final avgProbability = videos.isEmpty
        ? 0
        : videos.map((v) => v.crimeProbability).reduce((a, b) => a + b) /
        videos.length;

    return [
      _buildSummaryCard(
        title: 'Total Incidents',
        value: totalCrimes.toString(),
        icon: Icons.warning,
        color: Colors.blue,
      ),
      _buildSummaryCard(
        title: 'High Risk Incidents',
        value: highRiskCrimes.toString(),
        icon: Icons.dangerous,
        color: Colors.red,
      ),
      _buildSummaryCard(
        title: 'Avg. Probability',
        value: '${(avgProbability * 100).toStringAsFixed(1)}%',
        icon: Icons.assessment,
        color: Colors.orange,
      ),
    ];
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _countCrimeTypes(List<CrimeVideo> videos) {
    final counts = <String, int>{};
    for (var video in videos) {
      counts[video.crimeType] = (counts[video.crimeType] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, int> _calculateHourlyDistribution(List<CrimeVideo> videos) {
    final counts = <int, int>{};
    for (var i = 0; i < 24; i++) {
      counts[i] = 0;
    }
    for (var video in videos) {
      final hour = video.timestamp.hour;
      counts[hour] = (counts[hour] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _calculateSeverityDistribution(List<CrimeVideo> videos) {
    int high = 0, medium = 0, low = 0;
    for (var video in videos) {
      if (video.crimeProbability > 0.8) {
        high++;
      } else if (video.crimeProbability > 0.6) {
        medium++;
      } else {
        low++;
      }
    }
    return {
      'High Risk (>80%)': high,
      'Medium Risk (60-80%)': medium,
      'Low Risk (<60%)': low,
    };
  }
}

// Reported Crimes Screen
class ReportedCrimesScreen extends StatefulWidget {
  const ReportedCrimesScreen({super.key});

  @override
  _ReportedCrimesScreenState createState() => _ReportedCrimesScreenState();
}

class _ReportedCrimesScreenState extends State<ReportedCrimesScreen> {
  final _searchController = TextEditingController();
  List<ReportedCrime> _displayedCrimes = [];

  @override
  void initState() {
    super.initState();
    _displayedCrimes = ReportedCrimesManager.reportedCrimes;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _displayedCrimes = ReportedCrimesManager.searchCrimes(_searchController.text);
    });
  }

  void _updateCrimeStatus(ReportedCrime crime) {
    showDialog(
      context: context,
      builder: (context) {
        String? newStatus = crime.status;
        String? notes = crime.notes;
        String? selectedOfficer = crime.assignedOfficer;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Crime Status'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: newStatus,
                      items: ['Pending', 'Investigating', 'Resolved']
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          newStatus = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedOfficer,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ...ReportedCrimesManager.officers
                            .map((officer) => DropdownMenuItem(
                          value: officer,
                          child: Text(officer),
                        ))
                            .toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedOfficer = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Assigned Officer'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Notes'),
                      onChanged: (value) {
                        notes = value;
                      },
                      controller: TextEditingController(text: notes),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (newStatus != null) {
                      ReportedCrimesManager.updateStatus(
                        crime.crimeVideo.id,
                        newStatus!,
                        notes: notes,
                        officer: selectedOfficer,
                      );
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Crimes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search reported crimes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _displayedCrimes.isEmpty
                ? const Center(
              child: Text('No crimes have been reported yet.'),
            )
                : ListView.builder(
              itemCount: _displayedCrimes.length,
              itemBuilder: (context, index) {
                final reportedCrime = _displayedCrimes[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(reportedCrime.crimeVideo.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reportedCrime.crimeVideo.crimeType),
                        Text(
                          'Reported: ${_formatDateTime(reportedCrime.reportedTime)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Status: ${reportedCrime.status}',
                          style: TextStyle(
                            color: _getStatusColor(reportedCrime.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reportedCrime.assignedOfficer != null)
                          Text(
                            'Officer: ${reportedCrime.assignedOfficer}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        if (reportedCrime.notes != null)
                          Text(
                            'Notes: ${reportedCrime.notes}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    leading: CrimeProbabilityIndicator(
                      probability: reportedCrime.crimeVideo.crimeProbability,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _updateCrimeStatus(reportedCrime),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoDetailScreen(
                            video: reportedCrime.crimeVideo,
                            isAuthority: true,
                            onCrimeReported: (_) {},
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}