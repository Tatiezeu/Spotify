import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/sportify_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // Background Image (Optional, using black for now as per Spotify)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.black,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.music_note,
                    size: 80,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Millions of Songs.\nFree on Spotify.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayLarge,
                  ),
                  const Spacer(),
                  SpotifyButton(
                    text: 'Sign up free',
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup/email');
                    },
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  SpotifyButton(
                    text: 'Continue with Google',
                    onPressed: () {},
                    isPrimary: false,
                    icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  SpotifyButton(
                    text: 'Continue with Facebook',
                    onPressed: () {},
                    isPrimary: false,
                    icon: const Icon(Icons.facebook, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  SpotifyButton(
                    text: 'Continue with Apple',
                    onPressed: () {},
                    isPrimary: false,
                    icon: const Icon(Icons.apple, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  SpotifyButton(
                    text: 'Log in',
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    isPrimary: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
