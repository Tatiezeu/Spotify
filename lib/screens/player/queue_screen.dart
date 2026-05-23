import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../utils/image_helper.dart';

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
        centerTitle: true,
        title: const Text(
          'Play Queue', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Now Playing Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Now playing', 
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 15)
            ),
          ),
          if (nowPlaying != null) 
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ImageHelper.imageWidget(nowPlaying.coverUrl, width: 56, height: 56, fit: BoxFit.cover),
                ),
                title: Text(
                  nowPlaying.title, 
                  style: const TextStyle(color: AppColors.spotifyGreen, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  nowPlaying.artist, 
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.volume_up, color: AppColors.spotifyGreen, size: 22),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Nothing playing currently', style: TextStyle(color: Colors.white30, fontSize: 14)),
            ),
          
          const SizedBox(height: 24),
          
          // 2. Next Up Section Header (with dynamic "Clear Queue" action)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Next up', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)
                ),
                if (queue.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      player.clearQueue();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Queue cleared successfully'),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Text(
                        'Clear queue', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 3. Reorderable Next Up Upcoming Tracks List
          Expanded(
            child: queue.isEmpty 
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue_music, size: 64, color: Colors.white12),
                      SizedBox(height: 12),
                      Text(
                        'Queue is empty.\nAdd tracks from playlists or search.', 
                        style: TextStyle(color: Colors.white30, fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onReorder: (oldIndex, newIndex) {
                    player.reorderQueue(oldIndex, newIndex);
                  },
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    return Container(
                      key: ValueKey('queue_item_${song.id}_$index'),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 12, right: 16, top: 4, bottom: 4),
                        onTap: () {
                          // Play the enqueued song immediately and remove it from the list
                          player.playSong(song);
                          player.removeFromQueue(index);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ImageHelper.imageWidget(song.coverUrl, width: 44, height: 44, fit: BoxFit.cover),
                        ),
                        title: Text(
                          song.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        subtitle: Text(
                          song.artist, 
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Quick "Remove from queue" action
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 20),
                              onPressed: () {
                                player.removeFromQueue(index);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed "${song.title}" from queue'),
                                    duration: const Duration(milliseconds: 700),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            // Standard Reorder drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, color: Colors.white30, size: 24),
                            ),
                          ],
                        ),
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
