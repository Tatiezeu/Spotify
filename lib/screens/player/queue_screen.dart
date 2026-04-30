import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QueueScreen extends StatelessWidget {
  final List<Map<String, String>> queue;
  final Function(int) onPlay;

  const QueueScreen({super.key, required this.queue, required this.onPlay});

  @override
  Widget build(BuildContext context) {
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
          if (queue.isNotEmpty) 
            ListTile(
              leading: Image.network(queue[0]['image']!, width: 48, height: 48, fit: BoxFit.cover),
              title: Text(queue[0]['title']!, style: const TextStyle(color: AppColors.spotifyGreen, fontWeight: FontWeight.bold)),
              subtitle: Text(queue[0]['artist']!),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text('Next from: Your playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: queue.length - 1,
              itemBuilder: (context, index) {
                final track = queue[index + 1];
                return ListTile(
                  onTap: () => onPlay(index + 1),
                  leading: Image.network(track['image']!, width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(track['title']!),
                  subtitle: Text(track['artist']!),
                  trailing: const Icon(Icons.drag_handle, color: AppColors.secondaryText),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
