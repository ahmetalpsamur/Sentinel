import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

      weaponProbability: 0.10,
      weaponType: "Gun",

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

      weaponProbability: 0.60,
      weaponType: "Knife",

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

      weaponProbability: 0.10,
      weaponType: "Gun",

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

      weaponProbability: 0.10,
      weaponType: "Gun",

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Crime report submitted',
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SHIELDIR',
          style: GoogleFonts.orbitron(
            color: Colors.red[700],
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Iconsax.notification, color: Colors.grey[400]),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Colors.grey[850]!,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: _selectedIndex == 0
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Colors.grey[800]!.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 0 ? Iconsax.video : Iconsax.video,
                  color: _selectedIndex == 0 ? Colors.red[700] : Colors.grey[500],
                ),
                label: 'Videos',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1 ? Iconsax.warning_2 : Iconsax.warning_2,
                  color: _selectedIndex == 1 ? Colors.red[700] : Colors.grey[500],
                ),
                label: 'Reports',
              ),
              if (widget.isAuthority)
                BottomNavigationBarItem(
                  icon: Icon(
                    _selectedIndex == 2 ? Iconsax.chart : Iconsax.chart_2,
                    color: _selectedIndex == 2 ? Colors.red[700] : Colors.grey[500],
                  ),
                  label: 'Analytics',
                ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.red[700],
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}