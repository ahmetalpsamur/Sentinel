import 'package:latlong2/latlong.dart';

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