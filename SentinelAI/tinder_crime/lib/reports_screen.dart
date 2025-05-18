import 'package:flutter/material.dart';
import 'models.dart';
import 'videos_screen.dart';
import 'widgets.dart';

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
                      type: reportedCrime.crimeVideo.crimeType,
                      weaponType: reportedCrime.crimeVideo.weaponType,
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