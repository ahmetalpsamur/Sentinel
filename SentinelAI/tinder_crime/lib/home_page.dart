import 'package:flutter/material.dart';
import 'models.dart';
import 'videos_screen.dart';
import 'reports_screen.dart';
import 'analytics_screen.dart';
import 'package:latlong2/latlong.dart';

class CrimeDetectionHomePage extends StatefulWidget {
  final bool isAuthority;

  final List<CrimeVideo> initialCrimeVideos = [
    CrimeVideo(
      id: '1',
      title: 'Suspicious Activity in Parking Lot',
      description: 'Possible car break-in detected at 3:15 AM',
      videoUrl: 'https://storage.googleapis.com/shieldir_videos/berkayTest.mp4',
      crimeProbability: 0.10,
      location: const LatLng(38.374564, 27.039499),
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      crimeType: 'Theft',
    ),
    CrimeVideo(
      id: '2',
      title: 'Altercation Near ATM',
      description: 'Two individuals in physical confrontation',
      videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
      crimeProbability: 0.92,
      location: const LatLng(38.361564, 27.539499),
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      crimeType: 'Assault',
    ),
    CrimeVideo(
      id: '3',
      title: 'Vandalism in Subway Station',
      description: 'Individual spray painting on walls',
      videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
      crimeProbability: 0.78,
      location: const LatLng(38.304064, 27.009099),
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      crimeType: 'Vandalism',
    ),
    CrimeVideo(
      id: '4',
      title: 'Package Theft from Porch',
      description: 'Person taking package from residential porch',
      videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-15s.mp4',
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
          : AnalyticsScreen(
        videos: widget.initialCrimeVideos,
        isAuthority: widget.isAuthority,
      ),
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