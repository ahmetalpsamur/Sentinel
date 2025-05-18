import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models.dart';
import 'widgets.dart';

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
                series: <CartesianSeries>[
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
                series: <CartesianSeries>[
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