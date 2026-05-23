import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../models/song.dart';
import '../../utils/image_helper.dart';
import '../player/now_playing_screen.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recently played', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          final history = player.history;
          
          if (history.isEmpty) {
            return const Center(
              child: Text('No recently played music.', style: TextStyle(color: AppColors.secondaryText)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final song = history[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ImageHelper.imageWidget(song.coverUrl, width: 56, height: 56, fit: BoxFit.cover),
                ),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist),
                onTap: () {
                  player.playSong(song);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NowPlayingScreen(song: song)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
