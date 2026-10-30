import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/landing_view.dart';
import 'views/resident/resident_dashboard.dart';
import 'views/admin/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Keep your actual URL and Key here)
  await Supabase.initialize(
    url: 'https://snvrndgazqrawaijdoqm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNudnJuZGdhenFyYXdhaWpkb3FtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1ODIwNDYsImV4cCI6MjA5MTE1ODA0Nn0.4wqrf5-0j7pN-EnsKhEkJtVoei38RMdX6FfcqtpcGBM',
  );

  runApp(const WardWatchApp());
}

class WardWatchApp extends StatelessWidget {
  const WardWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WardWatch',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      theme: ThemeData(
        // Injecting your custom color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF055391), // Primary Blue
          primary: const Color(0xFF055391),
          secondary: const Color(0xFFBE1C2E), // Accent Red
        ),
        useMaterial3: true,
      ),
// Clean, single StreamBuilder to handle routing
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, authSnapshot) {
          final session = authSnapshot.data?.session;

          if (session != null) {
            // USER IS LOGGED IN -> Check their role safely!
            return FutureBuilder<Map<String, dynamic>?>(
              future: Supabase.instance.client
                  .from('profiles')
                  .select('role')
                  .eq('id', session.user.id)
                  .maybeSingle(), // 👈 changed to maybeSingle to prevent crashes
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF055391))));
                }

                // If there's an error finding the profile, show it on screen
                if (profileSnapshot.hasError) {
                  return Scaffold(body: Center(child: Text('Profile Error: ${profileSnapshot.error}')));
                }

                final role = profileSnapshot.data?['role'] ?? 'resident';

                if (role == 'admin') {
                  return const AdminDashboard();
                } else {
                  return const ResidentDashboard();
                }
              },
            );
          } else {
            // NOT LOGGED IN -> Send to Landing Page
            return const LandingView();
          }
        },
      ),
    );
  }
}