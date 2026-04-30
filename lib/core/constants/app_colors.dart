import 'package:flutter/material.dart';

class AppColors {
  // Primary Background
  static const Color primaryBackground = Color(0xFF121212);

  // Card/Panel Backgrounds
  static const Color cardBackground = Color(0xFF181818);
  static const Color panelBackground = Color(0xFF282828);

  // Brand Accent
  static const Color spotifyGreen = Color(0xFF1DB954);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB3B3B3);

  // Destructive/Alert
  static const Color destructive = Color(0xFFE22134);

  // Other
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Gradients
  static const LinearGradient likedSongsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF450AF5), Color(0xFF8E2DE2), Color(0xFFC33764)],
  );
}
