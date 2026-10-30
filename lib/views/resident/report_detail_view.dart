import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/screen_wrapper.dart';

class ReportDetailView extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    // Extracting Core Data
    final title = report['title'] ?? 'Unknown Issue';
    final description = report['description'] ?? 'No description provided.';
    final category = report['categories']['category_name'] ?? 'Unknown Category';
    final status = report['current_status'] ?? 'Pending';

    // Formatting Dates
    final submittedDate = DateFormat('MMMM d, yyyy - h:mm a').format(DateTime.parse(report['created_at']));
    final resolvedDate = report['resolved_at'] != null
        ? DateFormat('MMMM d, yyyy - h:mm a').format(DateTime.parse(report['resolved_at']))
        : null;

    // Extracting Admin Comments
    final adminComments = report['admin_comments'];

    // Extracting Media and Locations safely
    final mediaUrl = (report['media'] != null && report['media'].isNotEmpty)
        ? report['media'][0]['url']
        : null;

    final locationData = report['locations'] is List
        ? (report['locations'].isNotEmpty ? report['locations'][0] : null)
        : report['locations'];

    final latitude = locationData != null ? locationData['latitude'] : null;
    final longitude = locationData != null ? locationData['longitude'] : null;
    final landmark = locationData != null ? locationData['landmark_details'] : '';

    // Smart check to see if we actually have real GPS coordinates
    final bool hasGps = latitude != null && latitude != 0.0;

    return ScreenWrapper(
      backgroundPath: 'assets/images/app_bg.png',
      useBlur: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Report Details', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF055391),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // STATUS BADGE
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: status == 'Pending' ? Colors.orange[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: status == 'Pending' ? Colors.orange : Colors.green, width: 2),
                    ),
                    child: Text(
                      'STATUS: ${status.toUpperCase()}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: status == 'Pending' ? Colors.orange[800] : Colors.green[800]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // EVIDENCE PHOTO
                if (mediaUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      mediaUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('No evidence photo provided.', style: TextStyle(color: Colors.grey))),
                  ),
                const SizedBox(height: 24),

                // OFFICIAL ADMIN COMMENTS CARD (Shows up if Admin has replied)
                if (adminComments != null && adminComments.toString().trim().isNotEmpty)
                  Card(
                    color: Colors.blue[50],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.admin_panel_settings, color: Color(0xFF055391)),
                              SizedBox(width: 8),
                              Text('Official Authority Response', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                            ],
                          ),
                          const Divider(),
                          Text(adminComments, style: const TextStyle(fontSize: 15, height: 1.4)),
                          if (resolvedDate != null) ...[
                            const SizedBox(height: 12),
                            Text('Resolved on: $resolvedDate', style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    ),
                  ),

                if (adminComments != null && adminComments.toString().trim().isNotEmpty)
                  const SizedBox(height: 24),

                // CORE DETAILS CARD
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(label: Text(category), backgroundColor: const Color(0xFF055391).withOpacity(0.1), labelStyle: const TextStyle(color: Color(0xFF055391))),
                            Text('Reported: $submittedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                        const Divider(height: 32),

                        // LOCATION DATA
                        const Text('Location Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),

                        // Landmark
                        if (landmark != null && landmark.toString().trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.storefront, color: Color(0xFF055391), size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Landmark: $landmark', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),

                        // GPS Coordinates (Smart Check)
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, color: Color(0xFFBE1C2E), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              hasGps ? '$latitude, $longitude' : 'Location pinned via Landmark',
                              style: TextStyle(
                                  fontFamily: hasGps ? 'monospace' : null,
                                  color: Colors.black54,
                                  fontStyle: hasGps ? FontStyle.normal : FontStyle.italic
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}