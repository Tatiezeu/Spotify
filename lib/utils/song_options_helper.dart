import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/player_provider.dart';
import '../services/api_service.dart';
import '../core/constants/app_colors.dart';

class SongOptionsHelper {
  static void showSongOptions(BuildContext context, Song song, {String? playlistId, VoidCallback? onRemove}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white70),
              title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.read<PlayerProvider>().addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to Queue'), duration: Duration(seconds: 1)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music, color: Colors.white70),
              title: const Text('Play Next', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.read<PlayerProvider>().playNext(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Will play next'), duration: Duration(seconds: 1)),
                );
              },
            ),
            if (playlistId != null)
              ListTile(
                leading: const Icon(Icons.playlist_remove, color: Colors.redAccent),
                title: const Text('Remove from this Playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  final success = await ApiService().removeTrackFromPlaylist(playlistId, song.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      if (onRemove != null) onRemove();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from playlist'), duration: Duration(seconds: 1)),
                      );
                    }
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.add_box_outlined, color: Colors.white70),
                title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  showPlaylistPicker(context, song);
                },
              ),
            Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final isLiked = player.isLiked(song.id);
                return ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppColors.spotifyGreen : Colors.white70,
                  ),
                  title: Text(isLiked ? 'In Liked Songs' : 'Add to Liked Songs', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    player.toggleLike(song);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  static void showPlaylistPicker(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PlaylistPickerSheet(song: song),
    );
  }
}

class _PlaylistPickerSheet extends StatefulWidget {
  final Song song;
  const _PlaylistPickerSheet({required this.song});

  @override
  State<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<_PlaylistPickerSheet> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    final playlists = await ApiService().getPlaylists();
    if (mounted) {
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
          else if (_playlists.isEmpty)
            const Center(child: Text('No playlists created yet.'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    leading: const Icon(Icons.playlist_play),
                    title: Text(playlist.name),
                    onTap: () async {
                      final success = await ApiService().addTrackToPlaylist(playlist.id, widget.song);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Added to ${playlist.name}' : 'Already in playlist')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
