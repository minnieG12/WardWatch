import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/screen_wrapper.dart';

class AdminReportDetail extends StatefulWidget {
  final Map<String, dynamic> report;

  const AdminReportDetail({super.key, required this.report});

  @override
  State<AdminReportDetail> createState() => _AdminReportDetailState();
}

class _AdminReportDetailState extends State<AdminReportDetail> {
  final _supabase = Supabase.instance.client;
  final _commentController = TextEditingController();

  late String _currentStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report['current_status'];
    _commentController.text = widget.report['admin_comments'] ?? '';
  }

  // THE CORE RESEARCH FUNCTION: Status Audit Trail
  Future<void> _updateStatusAndLog() async {
    setState(() => _isSaving = true);
    final reportId = widget.report['id'];
    final oldStatus = widget.report['current_status'];
    final adminId = _supabase.auth.currentUser!.id;

    try {
      // 1. Update the Main Report Table
      await _supabase.from('reports').update({
        'current_status': _currentStatus,
        'admin_comments': _commentController.text.trim(),
        'resolved_at': _currentStatus == 'Resolved' ? DateTime.now().toIso8601String() : null,
      }).eq('id', reportId);

      // 2. Write to the Audit Trail (status_logs)
      if (oldStatus != _currentStatus) {
        await _supabase.from('status_logs').insert({
          'report_id': reportId,
          'changed_by': adminId,
          'status_from': oldStatus,          // Updated to match your DB
          'status_to': _currentStatus,       // Updated to match your DB
          'remarks': _commentController.text.trim(), // Updated to match your DB
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report Updated Successfully!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Go back to Master Queue
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFBE1C2E))
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      backgroundPath: 'assets/images/app_bg.png',
      useBlur: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Resolve Issue', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Issue Overview Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF055391)),
                            SizedBox(width: 8),
                            Text('Resident Report Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                            widget.report['title'],
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.report['description'],
                          style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),

                // LOCATION DETAILS CARD
                FutureBuilder<Map<String, dynamic>?>(
                  // Fetch the location specifically linked to this report's ID
                  future: _supabase
                      .from('locations')
                      .select()
                      .eq('report_id', widget.report['id'])
                      .maybeSingle(),
                  builder: (context, snapshot) {
                    final locationData = snapshot.data;
                    final landmark = locationData?['landmark_details'];
                    final lat = locationData?['latitude'];
                    final lng = locationData?['longitude'];

                    // Smart checks
                    final bool hasValidGps = lat != null && lat != 0.0 && lng != 0.0;
                    final bool hasLandmark = landmark != null && landmark.toString().trim().isNotEmpty;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Location Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 12),

                            // 1. Loading State
                            if (snapshot.connectionState == ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )

                            // 2. No Data State
                            else if (!hasValidGps && !hasLandmark)
                              const Row(
                                children: [
                                  Icon(Icons.location_off, color: Colors.grey, size: 20),
                                  SizedBox(width: 8),
                                  Text('No location data provided', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                ],
                              )

                            // 3. Data Available State
                            else ...[
                                // Landmark Row
                                if (hasLandmark)
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

                                // GPS Row
                                if (hasValidGps)
                                  Row(
                                    children: [
                                      const Icon(Icons.gps_fixed, color: Color(0xFFBE1C2E), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$lat, $lng',
                                        style: const TextStyle(fontFamily: 'monospace', color: Colors.black54, fontSize: 14),
                                      ),
                                    ],
                                  )
                                else if (hasLandmark)
                                  const Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                                      SizedBox(width: 8),
                                      Text('Location pinned via Landmark only', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                    ],
                                  ),
                              ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // THE ADMIN CONTROLS
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // Very light blue to signify action area
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Administrative Action',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBE1C2E))
                      ),
                      const SizedBox(height: 24),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _currentStatus,
                        decoration: InputDecoration(
                          labelText: 'Update Status',
                          labelStyle: const TextStyle(color: Color(0xFF055391)),
                          prefixIcon: const Icon(Icons.flag, color: Color(0xFF055391)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF055391), width: 2)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['Pending', 'In-Progress', 'Resolved']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) => setState(() => _currentStatus = val!),
                      ),
                      const SizedBox(height: 20),

                      // Official Comments Field
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Official Authority Comments',
                          alignLabelWithHint: true,
                          hintText: 'This will be visible to the resident...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF055391), width: 2)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF055391),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSaving ? null : _updateStatusAndLog,
                          icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('UPDATE STATUS & LOG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}