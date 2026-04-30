import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ListeningStatsScreen extends StatelessWidget {
  const ListeningStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Listening stats',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          _buildStatsSection(
            'This week',
            'Apr 27 – May 3',
            'Play music to get stats here',
            'Listen to some tunes, then check back later for your stats.',
            hasInfoIcon: true,
          ),
          const SizedBox(height: 32),
          _buildStatsSection(
            'Last week',
            'Apr 20 – 26',
            'This was a music-less week',
            'Don\'t worry, it happens.',
          ),
          const SizedBox(height: 32),
          _buildStatsSection(
            'Apr 13 – 19',
            '',
            'This was a music-less week',
            'Don\'t worry, it happens.',
          ),
          const SizedBox(height: 32),
          _buildStatsSectionHeader('Apr 6 – 12'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatsCard('Top artist', 'Tayc'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatsCard('Top song', 'Super-Héros'),
              ),
            ],
          ),
          const SizedBox(height: 120), // Space for mini player
        ],
      ),
    );
  }

  Widget _buildStatsSectionHeader(String title, {String? date, bool hasInfoIcon = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (hasInfoIcon) ...[
              const SizedBox(width: 8),
              const Icon(Icons.help_outline, color: AppColors.secondaryText, size: 20),
            ],
            const Spacer(),
            if (title.contains('Apr 6'))
              const Icon(Icons.ios_share, color: Colors.white, size: 24),
          ],
        ),
        if (date != null && date.isNotEmpty)
          Text(
            date,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
          ),
      ],
    );
  }

  Widget _buildStatsSection(
    String title,
    String date,
    String cardTitle,
    String cardSubtitle, {
    bool hasInfoIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsSectionHeader(title, date: date, hasInfoIcon: hasInfoIcon),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                cardTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                cardSubtitle,
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatsCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
