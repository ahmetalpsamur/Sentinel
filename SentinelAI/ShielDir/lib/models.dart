import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'models.dart';


class CrimeVideo {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final double crimeProbability;
  final String weaponType;
  final double weaponProbability;
  final LatLng location;
  final DateTime timestamp;
  final String crimeType;

  const CrimeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.crimeProbability,
    required this.weaponType,
    required this.weaponProbability,
    required this.location,
    required this.timestamp,
    required this.crimeType,
  });

  factory CrimeVideo.fromJson(Map<String, dynamic> json) {
    return CrimeVideo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      crimeProbability: (json['crimeProbability'] as num).toDouble(),
      weaponType: json['weaponType'] ?? 'Unknown',
      weaponProbability: (json['weaponProbability'] as num).toDouble(),
      location: LatLng(
        (json['location']['latitude'] as num).toDouble(),
        (json['location']['longitude'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(json['timestamp']),
      crimeType: json['crimeType'],
    );
  }
}

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

  factory ReportedCrime.fromJson(Map<String, dynamic> json) {
    return ReportedCrime(
      crimeVideo: CrimeVideo.fromJson(json),
      reportedTime: DateTime.parse(json['reportedAt']),
      status: json['status'] ?? 'Pending',
      notes: json['notes'],
      assignedOfficer: json['officerName'],
    );
  }

}
class ReportedCrimesManager {
  static final List<ReportedCrime> _reportedCrimes = [];
  static final Map<String, String> _officers = {
    'Officer Marifoğlu': 'officer.smith@police.gov',
    'Officer Arda': 'officer.smith@police.gov',
    'Detective Bulut': 'fikribarcabulut@gmail.com',
    'Sergeant Samur': 'ahmetalpsamur@gmail.com',
    'Lieutenant Uzunbayır': 'lieutenant.brown@police.gov',
    'Custom User': 'example@gmail.com'
  };

  static Future<void> fetchReportedCrimes() async {
    try {
      final response = await http.get(
        Uri.parse('http://shieldir.local:8000/reported_segments/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> videos = data['videos'];

        _reportedCrimes.clear();
        for (var video in videos) {
          _reportedCrimes.add(ReportedCrime.fromJson(video));
        }
      } else {
        throw Exception('Failed to load reported crimes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reported crimes: $e');
    }
  }

  static void reportCrime(CrimeVideo crime) {
    _reportedCrimes.add(ReportedCrime(
      crimeVideo: crime,
      reportedTime: DateTime.now(),
    ));
  }

  static List<ReportedCrime> get reportedCrimes => _reportedCrimes;
  static List<String> get officers => _officers.keys.toList();
  static String? getOfficerEmail(String officerName) => _officers[officerName];

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
          (crime.assignedOfficer?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (crime.notes?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }
}