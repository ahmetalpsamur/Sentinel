import 'dart:convert';

import 'package:flutter/material.dart';
import 'models.dart';
import 'videos_screen.dart';
import 'widgets.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;


class ReportedCrimesScreen extends StatefulWidget {
  const ReportedCrimesScreen({super.key});

  @override
  _ReportedCrimesScreenState createState() => _ReportedCrimesScreenState();
}

class _ReportedCrimesScreenState extends State<ReportedCrimesScreen> {
  final _searchController = TextEditingController();
  List<ReportedCrime> _displayedCrimes = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadReportedCrimes();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadReportedCrimes() async {
    try {
      await ReportedCrimesManager.fetchReportedCrimes();
      setState(() {
        _displayedCrimes = ReportedCrimesManager.reportedCrimes;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading crimes: $e')),
      );
    }
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
                  onPressed: () async {
                    if (newStatus != null) {
                      final bool officerChanged = selectedOfficer != crime.assignedOfficer;

                      // Yerel durumu güncelle
                      ReportedCrimesManager.updateStatus(
                        crime.crimeVideo.id,
                        newStatus!,
                        notes: notes,
                        officer: selectedOfficer,
                      );

                      try {
                        // API'ye PUT isteği gönder
                        final response = await http.put(
                          Uri.parse('http://shieldir.local:8000/update_report'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'segment_id': crime.crimeVideo.id,
                            'status': newStatus,
                            'notes': notes,
                            'officerName': selectedOfficer,
                          }),
                        );

                        if (response.statusCode == 200) {
                          // Başarılı güncelleme
                          if (officerChanged && selectedOfficer != null) {
                            await _sendAssignmentEmail(crime, selectedOfficer!);
                          }

                          // Verileri yeniden yükle ve sayfayı güncelle
                          await _loadReportedCrimes(); // 👈 Bu satırı ekledik
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          // Hata durumunda yerel değişiklikleri geri al
                          ReportedCrimesManager.updateStatus(
                            crime.crimeVideo.id,
                            crime.status,
                            notes: crime.notes,
                            officer: crime.assignedOfficer,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update crime: ${response.statusCode}')),
                            );
                          }
                        }
                      } catch (e) {
                        // Hata durumunda yerel değişiklikleri geri al
                        ReportedCrimesManager.updateStatus(
                          crime.crimeVideo.id,
                          crime.status,
                          notes: crime.notes,
                          officer: crime.assignedOfficer,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating crime: $e')),
                          );
                        }
                      }
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

  Future<void> _sendAssignmentEmail(ReportedCrime crime, String officerName) async {
    final officerEmail = ReportedCrimesManager.getOfficerEmail(officerName);

    if (officerEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find email for $officerName')),
      );
      return;
    }

    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      port: 587,
      username: 'shieldirnotification@gmail.com',
      password: 'jdok asbd eqpq csba',
      ignoreBadCertificate: false,
      ssl: false,
    );

    final message = Message()
      ..from = const Address('noreply@shieldir.com', 'ShielDir Threat Detection Module')
      ..recipients.add(officerEmail)
      ..subject = 'New Crime Assignment: ${crime.crimeVideo.title}'
      ..html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>New Crime Assignment</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #000;
            color: #fff;
            max-width: 700px;
            margin: 0 auto;
            padding: 20px;
        }
        .container {
            background-color: #1a1a1a;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(255, 0, 0, 0.5);
            padding: 30px;
            margin-top: 20px;
            border: 2px solid #ff0000;
        }
        h2 {
            color: #ff0000;
            border-bottom: 2px solid #ff3333;
            padding-bottom: 10px;
        }
        h3 {
            color: #ffffff;
            margin-top: 25px;
        }
        ul {
            padding-left: 20px;
        }
        li {
            margin-bottom: 8px;
        }
        strong {
            color: #ff3333;
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: bold;
            margin-left: 8px;
            background-color: #ff0000;
            color: #fff;
        }
        .location-link {
            font-family: monospace;
            background-color: #2c2c2c;
            padding: 2px 5px;
            border-radius: 3px;
            color: #ff6666;
            text-decoration: none;
        }
        .location-link:hover {
            text-decoration: underline;
        }
        .action-button {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 20px;
            background-color: #ff0000;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-weight: bold;
        }
        .action-button:hover {
            background-color: #cc0000;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ff3333;
            font-size: 0.9em;
            color: #ccc;
        }
        .logo {
            text-align: center;
            margin-bottom: 20px;
        }
        .logo img {
            max-width: 200px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            <img src="https://storage.googleapis.com/shieldir_videos/ShilDir_only_logo_transparent.png" alt="ShieldDir Logo" style="width: 150px; height: auto;">
        </div>
        <h2>New Crime Assignment</h2>
        <p>You have been assigned to investigate a new case. Please review the details below and take appropriate action.</p>
        
        <h3>Case Details</h3>
        <ul>
            <li><strong>Title:</strong> ${crime.crimeVideo.title}</li>
            <li><strong>Type:</strong> <span class="badge">${crime.crimeVideo.crimeType}</span></li>
            <li><strong>Crime Probability:</strong> ${crime.crimeVideo.crimeProbability.toStringAsFixed(0)}%</li>
            <li><strong>Weapon:</strong> ${crime.crimeVideo.weaponType ?? 'Unknown'}</li>
            <li><strong>Weapon Probability:</strong> ${(crime.crimeVideo.weaponProbability * 100).toStringAsFixed(0)}%</li>
            <li><strong>Location:</strong> 
                <a href="https://www.google.com/maps/search/?api=1&query=${crime.crimeVideo.location.latitude},${crime.crimeVideo.location.longitude}" 
                   class="location-link" 
                   target="_blank">
                   ${crime.crimeVideo.location.latitude}, ${crime.crimeVideo.location.longitude}
                </a>
            </li>
            <li><strong>Date/Time:</strong> ${_formatDateTime(crime.reportedTime)}</li>
            <li><strong>Status:</strong> <span class="badge">${crime.status}</span></li>
            ${crime.notes != null ? '<li><strong>Notes:</strong> ${crime.notes}</li>' : ''}
        </ul>
        
        <div class="footer">
            <p>Thank you,</p>
            <p><strong>ShieldDir Team</strong></p>
            <p style="font-size: 0.8em; margin-top: 15px;">This is an automated notification. Please do not reply to this message.</p>
        </div>
    </div>
</body>
</html>
        ''';

    try {
      final sendReport = await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment notification sent to $officerName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Crimes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportedCrimes,
          ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load crimes'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReportedCrimes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _displayedCrimes.isEmpty
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
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CrimeProbabilityIndicator(
                          probability: reportedCrime.crimeVideo.crimeProbability,
                          type: reportedCrime.crimeVideo.crimeType,
                          weaponType: reportedCrime.crimeVideo.weaponType,
                        ),
                        const SizedBox(width: 8), // Araya boşluk ekledik
                        CrimeProbabilityIndicator(
                          probability: reportedCrime.crimeVideo.weaponProbability,
                          type: 'weapon',
                          weaponType: reportedCrime.crimeVideo.weaponType,
                        ),
                      ],
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