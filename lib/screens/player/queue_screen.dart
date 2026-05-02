import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/player_provider.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final nowPlaying = player.currentSong;
    final queue = player.queue;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Queue', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Now playing', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
          ),
          if (nowPlaying != null) 
            ListTile(
              leading: Image.network(nowPlaying.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
              title: Text(nowPlaying.title, style: const TextStyle(color: AppColors.spotifyGreen, fontWeight: FontWeight.bold)),
              subtitle: Text(nowPlaying.artist),
            )
          else
            const ListTile(title: Text('Nothing playing')),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text('Next up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          
          Expanded(
            child: queue.isEmpty 
              ? const Center(child: Text('Queue is empty', style: TextStyle(color: AppColors.secondaryText)))
              : ReorderableListView.builder(
                  onReorder: (oldIndex, newIndex) {
                    player.reorderQueue(oldIndex, newIndex);
                  },
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    return ListTile(
                      key: ValueKey('queue_item_${song.id}_$index'),
                      onTap: () {
                        // Play the clicked song next or immediately?
                        // For now, let's just make it the current song.
                        player.playSong(song);
                        player.removeFromQueue(index);
                      },
                      leading: Image.network(song.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white30, size: 20),
                            onPressed: () => player.removeFromQueue(index),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
