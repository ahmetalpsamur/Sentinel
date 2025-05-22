import 'dart:convert';
import 'package:http/http.dart' as http;
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

  CrimeDetectionHomePage({super.key, required this.isAuthority});

  @override
  _CrimeDetectionHomePageState createState() => _CrimeDetectionHomePageState();
}

class _CrimeDetectionHomePageState extends State<CrimeDetectionHomePage> {
  int _selectedIndex = 0;
  List<CrimeVideo> _crimeVideos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Key _refreshKey = UniqueKey(); // 👈 Sayfa yeniden oluşturmak için key

  @override
  void initState() {
    super.initState();
    _fetchCrimeVideos();
  }

  Future<void> _fetchCrimeVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse('http://localhost/furkanData.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> videosJson = jsonData['videos'];

        setState(() {
          _crimeVideos = videosJson.map((videoJson) {
            return CrimeVideo(
              id: videoJson['id'] ?? '',
              title: videoJson['title'] ?? 'No Title',
              description: videoJson['description'] ?? 'No Description',
              videoUrl: videoJson['videoUrl'] ?? '',
              crimeProbability:
              (videoJson['crimeProbability'] ?? 0.0).toDouble(),
              weaponProbability:
              (videoJson['weaponProbability'] ?? 0.0).toDouble(),
              weaponType: videoJson['weaponType'] ?? 'Unknown',
              location: const LatLng(0.0, 0.0),
              timestamp: DateTime.parse(
                  videoJson['timestamp'] ?? DateTime.now().toString()),
              crimeType: videoJson['crimeType'] ?? 'Unknown',
            );
          }).toList();
          _refreshKey = UniqueKey(); // 👈 Sayfayı komple yenile
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load crime videos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading videos: ${e.toString()}';
      });

      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    setState(() {
      _crimeVideos = [
        CrimeVideo(
          id: '1',
          title: 'Suspicious Activity in Parking Lot',
          description: 'Possible car break-in detected at 3:15 AM',
          videoUrl:
          'https://storage.googleapis.com/shieldir_videos/berkayTest.mp4',
          crimeProbability: 0.10,
          weaponProbability: 0.10,
          weaponType: "Gun",
          location: const LatLng(38.374564, 27.039499),
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          crimeType: 'Theft',
        ),
      ];
    });
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _errorMessage.isNotEmpty
            ? Center(
          child: Text(
            _errorMessage,
            style: GoogleFonts.rajdhani(color: Colors.white),
          ),
        )
            : RefreshIndicator(
          color: Colors.red[700],
          backgroundColor: Colors.grey[900],
          onRefresh: _fetchCrimeVideos,
          child: _selectedIndex == 0
              ? VideoListScreen(
            key: _refreshKey, // 👈 Sayfayı sıfırdan başlatır
            videos: _crimeVideos,
            isAuthority: widget.isAuthority,
            onCrimeReported: _removeReportedCrime,
          )
              : _selectedIndex == 1
              ? const ReportedCrimesScreen()
              : AnalyticsScreen(
            videos: _crimeVideos,
            isAuthority: widget.isAuthority,
          ),
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
                  color:
                  _selectedIndex == 0 ? Colors.red[700] : Colors.grey[500],
                ),
                label: 'Videos',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1 ? Iconsax.warning_2 : Iconsax.warning_2,
                  color:
                  _selectedIndex == 1 ? Colors.red[700] : Colors.grey[500],
                ),
                label: 'Reports',
              ),
              if (widget.isAuthority)
                BottomNavigationBarItem(
                  icon: Icon(
                    _selectedIndex == 2 ? Iconsax.chart : Iconsax.chart_2,
                    color: _selectedIndex == 2
                        ? Colors.red[700]
                        : Colors.grey[500],
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
