import 'package:flutter/material.dart';
import '../widgets/screen_wrapper.dart';
import 'login_view.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      backgroundPath: 'assets/images/landing_bg.png',
      useBlur: false, // Keep the artwork crisp and vibrant
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- TOP SECTION: Big Logo & Bold Typography ---
                Column(
                  children: [
                    const SizedBox(height: 40),

                    // Big, Aesthetic Squircle Logo
                    Container(
                      width: 160, // Significantly increased size
                      height: 160,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40), // Premium iOS-style curve
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF055391).withOpacity(0.2), // Subtle blue glow
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 32),

                    // Massive, Bold Title
                    Text(
                      'WardWatch',
                      style: TextStyle(
                        fontSize: 56, // Much bigger font
                        fontWeight: FontWeight.w900, // Maximum boldness
                        color: const Color(0xFF055391),
                        letterSpacing: -1.5, // Tighter kerning for a modern logotype feel
                        shadows: [
                          // Double text shadow ensures readability against the illustrated sky
                          Shadow(color: Colors.white.withOpacity(0.95), blurRadius: 20),
                          Shadow(color: Colors.white.withOpacity(0.95), blurRadius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Empowering Citizens.\nTransforming Cities.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF055391).withOpacity(0.9),
                        height: 1.3,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 15),
                        ],
                      ),
                    ),
                  ],
                ),

                // --- MIDDLE SECTION: Invisible Spacer ---
                // This pushes the button to the bottom and lets your background artwork shine!
                const Spacer(),

                // --- BOTTOM SECTION: Call to Action & Footer ---
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64, // Taller, premium button size
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBE1C2E), // Accent Red
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0xFFBE1C2E).withOpacity(0.5), // Colored drop shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 20, // Bigger button text
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer attribution
                    const Text(
                      'Built by Asmita Guha (Reg No.: 230911112) for Advanced Technology Lab 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 24), // Safe area bottom padding
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}