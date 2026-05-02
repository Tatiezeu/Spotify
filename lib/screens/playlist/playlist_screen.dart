import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';

class PlaylistScreen extends StatefulWidget {
  final bool isLikedSongs;
  final String? title;
  final String? playlistId;

  const PlaylistScreen({
    super.key, 
    this.isLikedSongs = false, 
    this.title,
    this.playlistId,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isLoading = true;
  Playlist? _playlist;
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    
    if (widget.isLikedSongs) {
      _songs = await api.getLikedSongs();
    } else if (widget.playlistId != null) {
      _playlist = await api.getPlaylist(widget.playlistId!);
      if (_playlist != null) {
        _songs = _playlist!.tracks;
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          widget.isLikedSongs ? 'Liked Songs' : (_playlist?.name ?? widget.title ?? 'Playlist'),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text('${_songs.length} songs', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.arrow_circle_down, color: AppColors.spotifyGreen, size: 28),
                            const SizedBox(width: 24),
                            const Icon(Icons.shuffle, color: AppColors.secondaryText, size: 28),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                if (_songs.isNotEmpty) {
                                  context.read<PlayerProvider>().playSong(_songs.first);
                                  for (int i = 1; i < _songs.length; i++) {
                                    context.read<PlayerProvider>().addToQueue(_songs[i]);
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(color: AppColors.spotifyGreen, shape: BoxShape.circle),
                                child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildFilterChips(),
                        const SizedBox(height: 24),
                        _buildAddSongsRow(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSongItem(context, _songs[index]),
                    childCount: _songs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 180)),
              ],
            ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: widget.isLikedSongs ? const Color(0xFF2E4472) : const Color(0xFF282828),
      expandedHeight: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      elevation: 0,
    );
  }

  Widget _buildFilterChips() {
    final filters = ['By you', 'Recently added', 'Alphabetical'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(filter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        )).toList(),
      ),
    );
  }

  Widget _buildAddSongsRow() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white70, size: 30),
        ),
        const SizedBox(width: 16),
        const Text('Add songs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildSongItem(BuildContext context, Song song) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(song.coverUrl, width: 52, height: 52, fit: BoxFit.cover),
      ),
      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: AppColors.secondaryText),
        onPressed: () => _showSongOptions(context, song),
      ),
      onTap: () {
        context.read<PlayerProvider>().playSong(song);
      },
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(song.coverUrl, width: 50, height: 50)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${song.artist} • ${song.albumName}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildOptionItem(Icons.playlist_add, 'Add to Queue', onTap: () {
              context.read<PlayerProvider>().addToQueue(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Queue'), backgroundColor: AppColors.spotifyGreen));
            }),
            _buildOptionItem(Icons.favorite_border, 'Add to Liked Songs', onTap: () async {
              final success = await ApiService().toggleLikeSong(song);
              if (mounted) Navigator.pop(context);
              if (success) _fetchData();
            }),
            _buildOptionItem(Icons.share, 'Share'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap ?? () {},
    );
  }
}
