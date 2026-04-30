import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CreateMenuBottomSheet extends StatelessWidget {
  const CreateMenuBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreateMenuBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF282828),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          _buildCreateMenuItem(context, Icons.music_note_outlined, 'Playlist', 'Create a playlist with songs or episodes'),
          _buildCreateMenuItem(context, Icons.people_outline, 'Collaborative playlist', 'Create a playlist together with friends'),
          _buildCreateMenuItem(context, Icons.tune, 'Mixed Playlist', 'Mix songs with smooth transitions', isBeta: true),
          _buildCreateMenuItem(context, Icons.bubble_chart_outlined, 'Blend', 'Combine your friends\' tastes into a playlist'),
          _buildCreateMenuItem(context, Icons.group_work_outlined, 'Jam', 'Listen together from anywhere'),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMenuItem(BuildContext context, IconData icon, String title, String subtitle, {bool isBeta = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          if (isBeta) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.spotifyGreen, borderRadius: BorderRadius.circular(4)),
              child: const Text('Beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      onTap: () {
        Navigator.pop(context);
        if (title == 'Playlist') Navigator.pushNamed(context, '/playlist/create');
      },
    );
  }
}
