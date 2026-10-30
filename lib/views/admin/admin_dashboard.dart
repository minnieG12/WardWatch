import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'admin_report_detail.dart';
import '../../widgets/screen_wrapper.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ScreenWrapper(
        backgroundPath: 'assets/images/app_bg.png',
        useBlur: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFF055391),
            foregroundColor: Colors.white,
            title: const Text('Admin Command Center', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _supabase.auth.signOut(),
                tooltip: 'Log Out',
              )
            ],
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Color(0xFFBE1C2E),
              indicatorWeight: 4,
              tabs: [
                Tab(icon: Icon(Icons.list_alt), text: 'Master Queue'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildMasterQueue(),
              _buildAnalyticsDashboard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: REAL-TIME MASTER QUEUE ---
  Widget _buildMasterQueue() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.95),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('All')),
              ButtonSegment(value: 'Pending', label: Text('Pending')),
              ButtonSegment(value: 'In-Progress', label: Text('In-Progress')),
              ButtonSegment(value: 'Resolved', label: Text('Resolved')),
            ],
            selected: {_statusFilter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _statusFilter = newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) return const Color(0xFF055391);
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return const Color(0xFF055391);
              }),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('reports').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF055391)));
              }

              var reports = snapshot.data ?? [];

              if (_statusFilter != 'All') {
                reports = reports.where((r) => r['current_status'] == _statusFilter).toList();
              }

              if (reports.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                    child: const Text('No reports match this filter.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final date = DateFormat('MMM d, yyyy').format(DateTime.parse(report['created_at']));

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: report['current_status'] == 'Resolved' ? Colors.green[100] : Colors.orange[100],
                        child: Icon(
                          report['current_status'] == 'Resolved' ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: report['current_status'] == 'Resolved' ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                      title: Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Reported: $date\nStatus: ${report['current_status']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminReportDetail(report: report)),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: RESEARCH ANALYTICS ---
  Widget _buildAnalyticsDashboard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('reports').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final reports = snapshot.data!;
        int pending = reports.where((r) => r['current_status'] == 'Pending').length;
        int active = reports.where((r) => r['current_status'] == 'In-Progress').length;
        int resolved = reports.where((r) => r['current_status'] == 'Resolved').length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 1. STATS SUMMARY ROW (New!)
            Row(
              children: [
                _buildStatCard('Pending', pending.toString(), Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Active', active.toString(), Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Fixed', resolved.toString(), Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // 2. CHART CARD
            Container(
              height: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  const Text("Resolution Distribution", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 40),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        maxY: (reports.length + 2).toDouble(),
                        barGroups: [
                          _makeGroupData(0, pending.toDouble(), Colors.orange),
                          _makeGroupData(1, active.toDouble(), Colors.blue),
                          _makeGroupData(2, resolved.toDouble(), Colors.green),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
                                switch (val.toInt()) {
                                  case 0: return const Text('PENDING', style: style);
                                  case 1: return const Text('ACTIVE', style: style);
                                  case 2: return const Text('RESOLVED', style: style);
                                  default: return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

// Helper for Stat Cards
  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

// Helper for Chart Bars
  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: Colors.grey.withOpacity(0.1)),
        ),
      ],
    );
  }
}