import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/router.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const String _decorativeSvg = '''
<svg viewBox="0 0 300 260" xmlns="http://www.w3.org/2000/svg">
  <circle cx="150" cy="100" r="90" fill="#38BDF8" fill-opacity="0.12"/>
  <circle cx="90" cy="140" r="60" fill="#0EA5E9" fill-opacity="0.10"/>
  <circle cx="210" cy="140" r="60" fill="#06B6D4" fill-opacity="0.10"/>
  <circle cx="150" cy="100" r="55" fill="#38BDF8" fill-opacity="0.15"/>
  <polygon points="150,30 180,90 120,90" fill="#38BDF8" fill-opacity="0.25"/>
  <rect x="120" y="88" width="60" height="8" rx="4" fill="#38BDF8" fill-opacity="0.30"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.06),

                // Decorative SVG shape
                SvgPicture.string(
                  _decorativeSvg,
                  width: 220,
                  height: 190,
                ),

                const SizedBox(height: 24),

                // App title
                Text(
                  'Prep Royale',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 12),

                // Accent underline bar
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // Tagline
                Text(
                  'Master the test.\nWin the battle.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: screenHeight * 0.08),

                // Get Started button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(Routes.signup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Sign In button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.go(Routes.login),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Legal disclaimer
                Text(
                  'Not affiliated with College Board, SAT, ACT, Inc., or any official testing organization.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
