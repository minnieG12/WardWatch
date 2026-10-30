import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'report_view.dart';
import 'report_detail_view.dart';
import '../../widgets/screen_wrapper.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser!.id;

    // Fetch Profile Info
    final profileData = await _supabase.from('profiles').select().eq('id', userId).single();

    // Fetch Reports (Crucial: Added landmark_details to the join query!)
    final reportsData = await _supabase
        .from('reports')
        .select('*, categories(category_name), media(url), locations(latitude, longitude, landmark_details)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _userProfile = profileData;
        _reports = reportsData;
        _isLoading = false;
      });
    }
  }

  // --- Redesigned Profile Update Flow (Bottom Sheet) ---
  void _openProfileEditor() {
    final phoneCtrl = TextEditingController(text: _userProfile?['phone_number'] ?? '');
    final addressCtrl = TextEditingController(text: _userProfile?['address'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows for custom rounded corners
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 32,
          right: 32,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Update Your Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF055391))),
            const SizedBox(height: 8),
            const Text('Ensure your ward details are accurate for municipal correspondence.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),

            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputStyle('Mobile Number', Icons.phone_android),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: addressCtrl,
              maxLines: 2,
              decoration: _inputStyle('Ward Address (Building/Street)', Icons.home_work),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF055391),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: () async {
                  await _supabase.from('profiles').update({
                    'phone_number': phoneCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                  }).eq('id', _supabase.auth.currentUser!.id);
                  Navigator.pop(context);
                  _fetchDashboardData();
                },
                child: const Text('SAVE CHANGES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to keep the input styles consistent
  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF055391)),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF055391), width: 2)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF055391))));
    }

    final totalReports = _reports.length;
    final pendingReports = _reports.where((r) => r['current_status'] == 'Pending').length;
    final resolvedReports = _reports.where((r) => r['current_status'] == 'Resolved').length;

    return ScreenWrapper(
      backgroundPath: 'assets/images/app_bg.png',
      useBlur: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF055391),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Image.asset('assets/images/logo.png', height: 32),
              const SizedBox(width: 12),
              const Text('Resident Portal'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () => _supabase.auth.signOut())
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // --- TOP SECTION: Profile Card ---
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Welcome, ${_userProfile?['full_name'] ?? 'Resident'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                            IconButton(icon: const Icon(Icons.edit, color: Color(0xFFBE1C2E)), onPressed: _openProfileEditor, tooltip: 'Edit Profile'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(_userProfile?['email'] ?? 'No email'),
                            const SizedBox(width: 24),
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(_userProfile?['phone_number'] ?? 'Add phone number', style: TextStyle(color: _userProfile?['phone_number'] == null ? Colors.red : Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.home, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(_userProfile?['address'] ?? 'Add ward address', style: TextStyle(color: _userProfile?['address'] == null ? Colors.red : Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- STATS ROW ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBadge('Total', totalReports.toString(), Colors.blue),
                            _buildStatBadge('Pending', pendingReports.toString(), Colors.orange),
                            _buildStatBadge('Resolved', resolvedReports.toString(), Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- BOTTOM SECTION: Reports List ---
                const Text('My Recent Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                const SizedBox(height: 16),

                if (_reports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
                    child: const Text('No reports submitted yet.\nUse the button below to report an issue.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )
                else
                  ..._reports.map((report) {
                    // Format the date using intl package
                    final DateTime parsedDate = DateTime.parse(report['created_at']);
                    final String formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(parsedDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF055391).withOpacity(0.1),
                          child: const Icon(Icons.report_problem, color: Color(0xFF055391)),
                        ),
                        title: Text(report['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category: ${report['categories']['category_name']}'),
                              const SizedBox(height: 4),
                              Text('Submitted: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: report['current_status'] == 'Pending' ? Colors.orange[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report['current_status'],
                            style: TextStyle(
                              color: report['current_status'] == 'Pending' ? Colors.orange[800] : Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportDetailView(report: report),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 80), // Space so the FAB doesn't hide the last item
              ],
            ),
          ),
        ),

        // Centered Floating Action Button
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportView()),
            ).then((_) => _fetchDashboardData());
          },
          backgroundColor: const Color(0xFFBE1C2E),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, MaterialColor color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color[700])),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }
}