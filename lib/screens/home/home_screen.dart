import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../playlist/playlist_screen.dart';
import 'recently_played_screen.dart';
import '../../services/api_service.dart';
import '../../models/playlist.dart';
import '../../widgets/profile_avatar.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../player/now_playing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/image_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Music', 'Following', 'Podcasts'];
  
  List<Playlist> _userPlaylists = [];
  bool _isLoadingPlaylists = true;
  StreamSubscription? _playlistSub;
  String? _likedSongsCoverPath;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _loadLikedSongsCover();
    _playlistSub = ApiService().onPlaylistsChanged.listen((_) {
      _loadPlaylists();
    });
  }

  Future<void> _loadLikedSongsCover() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _likedSongsCoverPath = prefs.getString('liked_songs_cover_path');
      });
    }
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await ApiService().getPlaylists();
    if (mounted) {
      setState(() {
        _userPlaylists = playlists;
        _isLoadingPlaylists = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primaryBackground,
            floating: true,
            leading: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const ProfileAvatar(),
                ),
              ),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.download_for_offline_outlined, color: AppColors.secondaryText, size: 24)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined, color: AppColors.secondaryText, size: 24)),
              const SizedBox(width: 8),
            ],
            title: _buildFilterBar(),
            titleSpacing: 0,
          ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(_getGreeting(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFilter == 'Podcasts')
                    _buildPodcastsContent()
                  else
                    _buildMusicContent(),
                  const SizedBox(height: 180),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.spotifyGreen : AppColors.panelBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.black : AppColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMusicContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentGrid(),
        const SizedBox(height: 32),
        _buildSectionTitle('Recommended Stations'),
        _buildStationCarousel(),
        const SizedBox(height: 32),
        _buildSectionTitle('Popular radio'),
        _buildPopularRadioCarousel(),
        const SizedBox(height: 32),
        _buildSectionTitle('Recents', showAll: true),
        _buildHorizontalRecents(),
        const SizedBox(height: 32),
        _buildSectionTitle('Recommended for today'),
        _buildSquareCarousel('recommended'),
        const SizedBox(height: 32),
        _buildSectionTitle('Albums featuring songs you like'),
        _buildSquareCarousel('albums_featured'),
        const SizedBox(height: 32),
        _buildSectionTitle('Popular albums and singles'),
        _buildSquareCarousel('popular_albums'),
        const SizedBox(height: 32),
        _buildSectionTitle('Your playlists'),
        _buildSquareCarousel('your_playlists'),
        const SizedBox(height: 32),
        _buildArtistSection('More like', 'Tayc', 'https://picsum.photos/200?artist_tayc'),
        _buildPlaylistCarousel('more_like_tayc'),
        const SizedBox(height: 32),
        _buildArtistSection('Discover more from', 'Tayc', 'https://picsum.photos/200?artist_tayc'),
        _buildPlaylistCarousel('discover_tayc'),
        const SizedBox(height: 32),
        _buildSectionTitle('Your top mixes'),
        _buildMixesCarousel(),
        const SizedBox(height: 32),
        _buildSectionTitle('Made for you'),
        _buildMadeForYouCard('Chill Mix', 'Spotify', '50 songs • Billie Eilish, Imagine Dragons...', 'https://picsum.photos/200?mfy1'),
        const SizedBox(height: 16),
        _buildMadeForYouCard('K-Pop Mix', 'Spotify', '50 songs • Jung Kook, JVKE, JENNIE and more', 'https://picsum.photos/200?mfy2', color: const Color(0xFF4A1B2A)),
        const SizedBox(height: 16),
        _buildMadeForYouCard('Alec Benjamin Radio', 'Spotify', '50 songs • Dean Lewis, Alec Benjamin, Em Beihold...', 'https://picsum.photos/200?mfy3', color: const Color(0xFF1B3B2B), isRadio: true),
        const SizedBox(height: 16),
        _buildMadeForYouCard('Elvis Kemayo Mix', 'Spotify', '50 songs • Martin Lambo, Prince Eyango...', 'https://picsum.photos/200?mfy4', color: const Color(0xFF2A1B3B)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool showAll = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (showAll)
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentlyPlayedScreen()));
              },
              child: const Text('Show all', style: TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistSection(String prefix, String artistName, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: _getImageProvider(imageUrl)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prefix, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(artistName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGrid() {
    if (_isLoadingPlaylists) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen)),
      );
    }

    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final displayItems = [
          {
            'title': 'Liked Songs',
            'subtitle': 'Playlist • ${player.likedSongIds.length} songs',
            'image': _likedSongsCoverPath ?? 'liked',
            'isLiked': true
          },
          ..._userPlaylists.take(5).map((p) => {
            'title': p.name,
            'subtitle': 'Playlist • ${p.trackCount} songs',
            'image': (p.coverUrl != null && p.coverUrl!.isNotEmpty) ? p.coverUrl : 'https://picsum.photos/100?random=${p.id}',
            'id': p.id,
          }),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return _buildRecentCard(
                item['title'] as String,
                item['subtitle'] as String,
                item['image'] as String,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistScreen(
                        playlistId: item['id'] as String?,
                        title: item['title'] as String,
                        isLikedSongs: item['isLiked'] == true,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStationCarousel() {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          final titles = ['Tems', 'Nicki Minaj', 'Cysoul', 'Tayc', 'Wizkid', 'Davido', 'Burna Boy', 'Rema', 'Ayra Starr', 'Tems'];
          final colors = [Colors.amber, Colors.purpleAccent, Colors.deepPurple, Colors.blueGrey, Colors.orange, Colors.red, Colors.green, Colors.teal, Colors.pink, Colors.blue];
          return _buildStationCard(
            titles[index],
            'Artist description and similar listeners for ${titles[index]}',
            colors[index],
            'https://picsum.photos/400/400?st=$index',
          );
        },
      ),
    );
  }

  Widget _buildStationCard(String title, String artists, Color color, String imageUrl) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Stack(
                children: [
                  Positioned(top: 8, left: 8, child: Row(children: const [Icon(Icons.album, color: Colors.black, size: 14), SizedBox(width: 4), Text('RADIO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))])),
                  Center(child: ClipRRect(borderRadius: BorderRadius.circular(100), child: ImageHelper.imageWidget(imageUrl, width: 140, height: 140, fit: BoxFit.cover))),
                  Positioned(bottom: 12, left: 12, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.black))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(artists, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRadioCarousel() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          final titles = ['Joé Dwèt Filé', 'King Luca', 'Rema', 'Tiakola', 'Dadju', 'Gazo', 'Hamza', 'Tayc', 'Ayra Starr', 'Tems'];
          final colors = [Colors.pinkAccent, Colors.orange, Colors.teal, Colors.blue, Colors.purple, Colors.red, Colors.green, Colors.blueGrey, Colors.amber, Colors.deepPurple];
          return _buildRadioCard(
            titles[index],
            'Sample artist list for ${titles[index]} radio...',
            colors[index],
            'https://picsum.photos/400/400?pr=$index',
          );
        },
      ),
    );
  }

  Widget _buildRadioCard(String title, String artists, Color color, String imageUrl) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Stack(
                children: [
                  Positioned(top: 8, right: 8, child: const Icon(Icons.album, color: Colors.black, size: 14)),
                  const Positioned(top: 8, left: 8, child: Text('RADIO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
                  Center(child: CircleAvatar(radius: 60, backgroundImage: _getImageProvider(imageUrl))),
                  Positioned(bottom: 8, left: 8, child: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(artists, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalRecents() {
    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSquareItem('${ApiService().firstname}\'s vibes', 'Playlist • ${ApiService().firstname}', 'https://picsum.photos/200?r1'),
          _buildSquareItem('Your Episodes', '1 episode...', 'https://picsum.photos/200?r2', isEpisode: true),
          _buildSquareItem('Afrosongs', 'Playlist • ${ApiService().firstname}', 'https://picsum.photos/200?r3'),
          _buildSquareItem('Nouveautés camerounaises', 'Playlist • Jos...', 'https://picsum.photos/200?r4'),
        ],
      ),
    );
  }

  Widget _buildSquareCarousel(String type) {
    if (type == 'your_playlists') {
      if (_isLoadingPlaylists) {
        return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen)),
        );
      }
      if (_userPlaylists.isEmpty) {
        return const SizedBox(
          height: 220,
          child: Center(child: Text('No playlists yet. Create one!', style: TextStyle(color: AppColors.secondaryText))),
        );
      }
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _userPlaylists.length,
          itemBuilder: (context, index) {
            final playlist = _userPlaylists[index];
            return _buildSquareItem(
              playlist.name,
              'Playlist',
              playlist.coverUrl,
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildSquareItem(
            'Item ${index + 1}',
            'Subtitle for item ${index + 1}',
            'https://picsum.photos/200?random=$type$index',
          );
        },
      ),
    );
  }

  Widget _buildPlaylistCarousel(String type) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildSpotifyPlaylistCard(
            'Playlist ${index + 1}',
            'Sample description for playlist ${index + 1} with artists...',
            'https://picsum.photos/400/400?p$index',
            color: index % 2 == 0 ? Colors.black : Colors.pink.withOpacity(0.5),
          );
        },
      ),
    );
  }

  Widget _buildSpotifyPlaylistCard(String title, String description, String imageUrl, {Color color = Colors.black}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(image: _getImageProvider(imageUrl), fit: BoxFit.cover),
              ),
              child: Stack(
                children: [
                  Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.album, color: Colors.white, size: 14))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Playlist', style: TextStyle(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildMixesCarousel() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          final titles = ['Afrobeats Mix', 'French Rap Mix', 'GIMS Mix', 'R&B Mix', 'Chill Mix', 'Party Mix', 'Workout Mix', 'Sleep Mix', 'Focus Mix', 'Jazz Mix'];
          final colors = [Colors.red, Colors.green, Colors.teal, Colors.blue, Colors.orange, Colors.pink, Colors.purple, Colors.indigo, Colors.brown, Colors.grey];
          return _buildMixItem(titles[index], 'Artist and sample track list description...', colors[index], 'https://picsum.photos/200?m$index');
        },
      ),
    );
  }

  Widget _buildMixItem(String title, String subtitle, Color tagColor, String imageUrl) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: ImageHelper.imageWidget(imageUrl, width: 160, height: 160, fit: BoxFit.cover)),
                Positioned(bottom: 12, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: tagColor, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildMadeForYouCard(String title, String author, String description, String imageUrl, {Color color = const Color(0xFF1B2E2E), bool isRadio = false}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isRadio 
                    ? Container(
                        width: 120, height: 120,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Stack(
                          children: [
                            Center(child: CircleAvatar(radius: 50, backgroundImage: _getImageProvider(imageUrl))),
                            Positioned(top: 8, left: 8, child: Row(children: const [Icon(Icons.album, color: Colors.black, size: 10), SizedBox(width: 4), Text('RADIO', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold))])),
                          ],
                        ),
                      )
                    : ImageHelper.imageWidget(imageUrl, width: 120, height: 120, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!isRadio) const Icon(Icons.explicit, color: AppColors.secondaryText, size: 16),
                          const SizedBox(width: 4),
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Text(author, style: const TextStyle(color: AppColors.secondaryText)),
                      const SizedBox(height: 12),
                      Text(description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12), maxLines: 2),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: AppColors.secondaryText),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistScreen(title: title)));
                  },
                  icon: const Icon(Icons.keyboard_double_arrow_left, size: 18),
                  label: const Text('Preview playlist', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.secondaryText, size: 28),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Your Library'), backgroundColor: AppColors.spotifyGreen),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.play_circle_filled, color: Colors.white, size: 36),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing $title...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareItem(String title, String subtitle, String imageUrl, {bool isEpisode = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(4), child: ImageHelper.imageWidget(imageUrl, width: 120, height: 120, fit: BoxFit.cover)),
                if (isEpisode)
                  Positioned(
                    bottom: -6,
                    left: -6,
                    child: Container(
                      decoration: const BoxDecoration(color: AppColors.primaryBackground, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: AppColors.spotifyGreen, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.bookmark, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isEpisode) ...[
                  const Icon(Icons.check_circle, color: AppColors.spotifyGreen, size: 12),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http') || url.startsWith('blob:')) {
      return NetworkImage(url);
    }
    if (kIsWeb) {
      return NetworkImage(url); // Fallback for web paths
    }
    return FileImage(File(url));
  }

  Widget _buildRecentCard(String title, String subtitle, String imageUrl, {bool isCircular = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistScreen(title: title))),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
          children: [
            if (imageUrl == 'liked')
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.likedSongsGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 24),
              )
            else
              Container(
                width: 52, 
                height: 52, 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4), 
                  image: DecorationImage(
                    image: _getImageProvider(imageUrl), 
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  )
                )
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPodcastsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPodcastEpisode('Rich Dad, Poor Dad - 1 of 4 (Audiobook)', 'Rich Dad Poor Dad by Robert Kiyosaki (Full Audiobook) • 1...', 'https://picsum.photos/200?p1', const Color(0xFF4A2B4D)),
        _buildPodcastEpisode('PROCRASTINATION IS STEALING YOUR LIFE – Stop Delaying Your Gr...', 'Denzel Washington Motivational Speech • 16 Fe...', 'https://picsum.photos/200?p2', const Color(0xFF2E2E2E)),
        _buildPodcastEpisode('The Joe Rogan Experience', 'Joe Rogan • 3h 12m', 'https://picsum.photos/200?p3', const Color(0xFF1B3B2B)),
        _buildPodcastEpisode('The Daily', 'The New York Times • 25m', 'https://picsum.photos/200?p4', const Color(0xFF1B1B4A)),
        _buildPodcastEpisode('Crime Junkie', 'audiochuck • 45m', 'https://picsum.photos/200?p5', const Color(0xFF4A1B1B)),
        _buildPodcastEpisode('Stuff You Should Know', 'iHeartPodcasts • 50m', 'https://picsum.photos/200?p6', const Color(0xFF4A4A1B)),
        _buildPodcastEpisode('The Psychology of Your 20s', 'Jemma Sbeg • 40m', 'https://picsum.photos/200?p7', const Color(0xFF1B4A4A)),
      ],
    );
  }

  Widget _buildPodcastEpisode(String title, String author, String imageUrl, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Episodes you might like', style: TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: ImageHelper.imageWidget(imageUrl, width: 90, height: 90, fit: BoxFit.cover)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(author, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle), child: const Icon(Icons.keyboard_double_arrow_left, color: Colors.white, size: 20)),
                    const SizedBox(width: 8),
                    const Text('Preview episode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 28),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Your Library'), backgroundColor: AppColors.spotifyGreen),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled, color: Colors.white, size: 36),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing: $title')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
