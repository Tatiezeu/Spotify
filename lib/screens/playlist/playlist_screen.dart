import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../player/queue_screen.dart';
import '../../core/constants/app_text_styles.dart';

class PlaylistScreen extends StatelessWidget {
  final bool isLikedSongs;
  final String? title;

  const PlaylistScreen({super.key, this.isLikedSongs = false, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
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
                    isLikedSongs ? 'Liked Songs' : (title ?? 'Afrosongs'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text('720 songs', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.arrow_circle_down, color: AppColors.spotifyGreen, size: 28),
                      const SizedBox(width: 24),
                      const Icon(Icons.shuffle, color: AppColors.secondaryText, size: 28),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: AppColors.spotifyGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
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
              (context, index) => _buildSongItem(context, index),
              childCount: 15,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 180)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF2E4472), // Blueish gradient top
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
    final filters = ['Pop', 'Afrobeats', 'Rap', 'Soft', 'Dance', 'Nostalgic'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) => GestureDetector(
          onTap: () {
            // Mock filter action
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(filter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
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

  Widget _buildSongItem(BuildContext context, int index) {
    final titles = ['Bring It On', 'Super-Héros', 'Naughty Girl', 'EYES CLOSED (with ZAYN)', 'ON YOU', 'Mule Makossa'];
    final artists = ['P-Square, Dave Scott', 'Tayc', 'SLOWBURN', 'JISOO, ZAYN', 'Timi Dre', 'Joli'];
    
    final title = titles[index % titles.length];
    final artist = artists[index % artists.length];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network('https://picsum.photos/100?s=$index', width: 52, height: 52, fit: BoxFit.cover),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(artist, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: AppColors.secondaryText),
        onPressed: () => _showSongOptions(context, title),
      ),
    );
  }

  void _showSongOptions(BuildContext context, String songTitle) {
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
                ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network('https://picsum.photos/100', width: 50, height: 50)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(songTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Artist Name • Album Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildOptionItem(Icons.ios_share, 'Share'),
            _buildOptionItem(Icons.add_circle_outline, 'Add to playlist', onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/playlist/create');
            }),
            _buildOptionItem(Icons.remove_circle_outline, 'Hide in this playlist', onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song hidden from this playlist')));
            }),
            _buildOptionItem(Icons.do_not_disturb_on_outlined, 'Exclude track from your taste profile', onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song excluded from profile')));
            }),
            _buildOptionItem(Icons.playlist_add, 'Add to Queue', onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Queue'), backgroundColor: AppColors.spotifyGreen));
            }),
            _buildOptionItem(Icons.list_alt, 'Go to Queue', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => QueueScreen(
                queue: [
                  {'title': songTitle, 'artist': 'Artist Name', 'image': 'https://picsum.photos/100'},
                  {'title': 'Bring It On', 'artist': 'P-Square', 'image': 'https://picsum.photos/200?track=2'},
                  {'title': 'Super-Héros', 'artist': 'Tayc', 'image': 'https://picsum.photos/200?track=3'},
                ],
                onPlay: (index) {},
              )));
            }),
            _buildOptionItem(Icons.group_add_outlined, 'Start a Jam'),
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
