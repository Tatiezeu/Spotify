import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../playlist/playlist_screen.dart';
import '../player/now_playing_screen.dart';
import '../playlist/create_playlist_screen.dart';
import '../artist/artist_screen.dart';
import '../album/album_screen.dart';
import '../home/recently_played_screen.dart';
import '../../services/api_service.dart';
import '../../models/song.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/profile_avatar.dart';
import '../../models/playlist.dart';
import '../../utils/song_options_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  List<Song> _searchResults = [];
  Timer? _debounce;
  final List<String> _searchFilters = ['All', 'Music', 'Podcasts & Shows', 'Artists', 'Playlists', 'Albums'];
  String _activeFilter = 'All';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await ApiService().updateProfileImage(pickedFile.path);
      setState(() {}); // Trigger rebuild to show new image in ProfileAvatar
    }
  }



  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) _recentSearches.removeLast();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _recentSearches);
    }
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _recentSearches = [];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
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
              title: const Text(
                'Search',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _showShareMenu(context),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: _pickImage,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    if (_isSearching) ...[
                      const SizedBox(height: 16),
                      _buildSearchFilters(),
                      const SizedBox(height: 24),
                      _buildSearchResults(),
                    ] else ...[
                      const SizedBox(height: 24),
                      if (_recentSearches.isNotEmpty) _buildSearchHistory(),
                      const Text(
                        'Discover something new',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildDiscoverSection(),
                      const SizedBox(height: 32),
                      const Text(
                        'Browse all',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildBrowseGrid(),
                    ],
                    const SizedBox(height: 180),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share via', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Other Apps'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.white),
                title: const Text('Print'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _searchFilters.map((filter) {
          final isSelected = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = filter;
                if (_searchController.text.isNotEmpty) {
                  _isLoading = true;
                }
              });
              if (_searchController.text.isNotEmpty) {
                // Trigger immediate search with new filter
                String searchType = 'track';
                if (filter == 'Artists') searchType = 'artist';
                if (filter == 'Albums') searchType = 'album';
                if (filter == 'All') searchType = 'track,artist,album';
                
                ApiService().searchSpotify(_searchController.text, type: searchType).then((res) {
                  if (mounted) setState(() { _searchResults = res; _isLoading = false; });
                });
              }
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
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen));
    }
    
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: AppColors.secondaryText)));
    }

    final tracks = _searchResults.where((s) => s.type == 'track').toList();
    final artists = _searchResults.where((s) => s.type == 'artist').toList();
    final albums = _searchResults.where((s) => s.type == 'album').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_activeFilter == 'All' && _searchResults.isNotEmpty) ...[
          const Text('Top result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTopResult(_searchResults.first),
          const SizedBox(height: 32),
        ],

        if (artists.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Artists')) ...[
          const Text('Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...artists.map((artist) => _buildArtistTile(artist)).toList(),
          const SizedBox(height: 24),
        ],

        if (tracks.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Music' || _activeFilter == 'Songs')) ...[
          const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...tracks.map((song) => _buildTrackTile(song)).toList(),
          const SizedBox(height: 24),
        ],

        if (albums.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Albums')) ...[
          const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...albums.map((album) => _buildAlbumTile(album)).toList(),
          const SizedBox(height: 24),
        ],
        
        // Handle playlists if any (currently playlists are often returned as albums or special types)
        if (_activeFilter == 'Playlists') ...[
          const Text('Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._searchResults.where((s) => s.type == 'playlist').map((p) => _buildAlbumTile(p)).toList(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildTopResult(Song topResult) {
    bool isArtist = topResult.type == 'artist';
    return GestureDetector(
      onTap: () {
        if (!isArtist) {
          context.read<PlayerProvider>().playSong(topResult);
          Navigator.push(context, MaterialPageRoute(builder: (context) => NowPlayingScreen(song: topResult)));
        } else {
          _searchController.text = topResult.title;
          _activeFilter = 'Music';
          _debounce?.cancel();
          setState(() { _isSearching = true; _isLoading = true; });
          ApiService().searchSpotify(topResult.title, type: 'track').then((res) {
            if (mounted) setState(() { _searchResults = res; _isLoading = false; });
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.panelBackground, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isArtist ? 40 : 4),
              child: Image.network(topResult.coverUrl, width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topResult.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(isArtist ? 'Artist' : 'Song • ${topResult.artist}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                ],
              ),
            ),
            if (!isArtist)
              const Icon(Icons.play_circle_fill, color: AppColors.spotifyGreen, size: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistTile(Song artist) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(artist.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
      ),
      title: Text(artist.artist, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
      subtitle: const Text('Artist'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistScreen(artistId: artist.artistId, artistName: artist.artist)));
      },
    );
  }

  Widget _buildAlbumTile(Song album) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Image.network(album.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
      title: Text(album.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
      subtitle: Text('Album • ${album.artist}'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumScreen(
          albumId: album.albumId, 
          title: album.title,
          artistName: album.artist,
          coverUrl: album.coverUrl,
        )));
      },
    );
  }

  Widget _buildTrackTile(Song song) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Image.network(song.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist),
      trailing: SizedBox(
        width: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final isLiked = player.isLiked(song.id);
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? AppColors.spotifyGreen : AppColors.secondaryText, size: 20),
                  onPressed: () => player.toggleLike(song),
                );
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.more_vert, color: AppColors.secondaryText, size: 20),
              onPressed: () => _showSongOptions(context, song),
            ),
          ],
        ),
      ),
      onTap: () {
        context.read<PlayerProvider>().playSong(song);
        Navigator.push(context, MaterialPageRoute(builder: (context) => NowPlayingScreen(song: song)));
      },
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    SongOptionsHelper.showSongOptions(context, song);
  }

  void _showPlaylistPicker(BuildContext context, Song song) {
    SongOptionsHelper.showPlaylistPicker(context, song);
  }




  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: Colors.black,
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
            _isLoading = value.isNotEmpty;
          });
          
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () async {
            if (value.isNotEmpty) {
              String searchType = 'track';
              if (_activeFilter == 'Artists') searchType = 'artist';
              if (_activeFilter == 'Albums') searchType = 'album';
              if (_activeFilter == 'All') searchType = 'track,artist,album';
              
              final spotifyFuture = ApiService().searchSpotify(value, type: searchType).catchError((e) => <Song>[]);
              final deezerFuture = ApiService().searchDeezer(value).catchError((e) => <Song>[]);

              final results = await Future.wait([spotifyFuture, deezerFuture]);
              final combinedResults = [...results[0], ...results[1]];
              
              if (mounted) {
                setState(() {
                  _searchResults = combinedResults;
                  _isLoading = false;
                });
                if (combinedResults.isNotEmpty) {
                  _saveSearchHistory(value);
                }
              }
            } else {
              if (mounted) {
                setState(() {
                  _searchResults = [];
                  _isLoading = false;
                });
              }
            }
          });
        },
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 28),
          hintText: 'What do you want to listen to?',
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontWeight: FontWeight.w500, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _isSearching ? IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 24),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _isSearching = false;
              });
            },
          ) : null,
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _clearSearchHistory,
              child: const Text('Clear All', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSearches.map((query) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, color: Colors.white54),
          title: Text(query, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () {
              setState(() {
                _recentSearches.remove(query);
                SharedPreferences.getInstance().then((prefs) => prefs.setStringList('search_history', _recentSearches));
              });
            },
          ),
          onTap: () {
            _searchController.text = query;
            setState(() { _isSearching = true; _isLoading = true; });
            Future.wait([
              ApiService().searchSpotify(query, type: 'track,artist,album'),
              ApiService().searchDeezer(query)
            ]).then((res) {
              if (mounted) setState(() { _searchResults = [...res[0], ...res[1]]; _isLoading = false; });
            });
          },
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDiscoverSection() {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDiscoverCard('#pop urbaine', 'https://picsum.photos/400/600?random=1'),
          _buildDiscoverCard('#coupé décalé', 'https://picsum.photos/400/600?random=2'),
          _buildDiscoverCard('#clean girl', 'https://picsum.photos/400/600?random=3'),
        ],
      ),
    );
  }

  Widget _buildDiscoverCard(String tag, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscoveryDetailScreen(tag: tag, imageUrl: imageUrl),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.play_arrow_outlined, color: Colors.white, size: 40),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                tag,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildCategoryCard('Podcasts', const Color(0xFF27856A), 'https://picsum.photos/100?1'),
        _buildCategoryCard('Live Events', const Color(0xFF8471F2), 'https://picsum.photos/100?2'),
        _buildCategoryCard('Made For You', const Color(0xFF1E3264), 'https://picsum.photos/100?3'),
        _buildCategoryCard('New Releases', const Color(0xFFE8115B), 'https://picsum.photos/100?4'),
        _buildCategoryCard('Hindi', const Color(0xFFE13300), 'https://picsum.photos/100?5'),
        _buildCategoryCard('Punjabi', const Color(0xFFB02897), 'https://picsum.photos/100?6'),
        _buildCategoryCard('Tamil', const Color(0xFFA56752), 'https://picsum.photos/100?7'),
        _buildCategoryCard('Telugu', const Color(0xFFD84000), 'https://picsum.photos/100?8'),
        _buildCategoryCard('Charts', const Color(0xFF8D67AB), 'https://picsum.photos/100?9'),
        _buildCategoryCard('Pop', const Color(0xFF148A08), 'https://picsum.photos/100?10'),
      ],
    );
  }

  Widget _buildCategoryCard(String title, Color color, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(title: title, color: color),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              right: -15,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoveryDetailScreen extends StatelessWidget {
  final String tag;
  final String imageUrl;

  const DiscoveryDetailScreen({super.key, required this.tag, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 5,
        itemBuilder: (context, index) {
          final bgColor = index % 2 == 0 ? const Color(0xFF630D0D) : const Color(0xFF2E6B91);
          final artistName = index % 2 == 0 ? 'Dadju, Tayc' : 'Franglish';
          final songTitle = index % 2 == 0 ? 'Épouse-moi' : 'Bêtise';
          final albumArt = index % 2 == 0 ? 'https://picsum.photos/400?random=reel1' : 'https://picsum.photos/400?random=reel2';
          
          return Container(
            color: bgColor,
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
                            Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Icon(Icons.volume_up_outlined, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildProgressBar(),
                      const Spacer(),
                      _buildReelCenter(albumArt),
                      const Spacer(),
                      _buildReelFooter(context, artistName, songTitle, albumArt),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(5, (index) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index == 0 ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildReelCenter(String imageUrl) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVisualizerBar(20),
              const SizedBox(width: 4),
              _buildVisualizerBar(40),
              const SizedBox(width: 4),
              _buildVisualizerBar(30),
              const SizedBox(width: 150), // Gap for image
              _buildVisualizerBar(30),
              const SizedBox(width: 4),
              _buildVisualizerBar(40),
              const SizedBox(width: 4),
              _buildVisualizerBar(20),
            ],
          ),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerBar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white38,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildReelFooter(BuildContext context, String artist, String song, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://picsum.photos/100?avatar')),
              const SizedBox(width: 8),
              Text(artist, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.ios_share, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          const Text('#french r&b  #love  #french music', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(artist, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Your Library'), backgroundColor: AppColors.spotifyGreen),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final Color color;

  const CategoryDetailScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, AppColors.primaryBackground],
                ),
              ),
              child: Center(
                child: Text(title, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistScreen(title: 'Playlist ${index + 1}'),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Image.network('https://picsum.photos/200?random=$index', fit: BoxFit.cover, width: double.infinity)),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Playlist ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistPickerSheet extends StatefulWidget {
  final Song song;
  const _PlaylistPickerSheet({required this.song});

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return _PlaylistPickerSheet(song: song);
      },
    );
  }

  @override
  State<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<_PlaylistPickerSheet> {
  bool _loadingPlaylists = true;
  List<Playlist> _playlists = [];

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
        _loadingPlaylists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_loadingPlaylists)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.spotifyGreen),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.spotifyGreen),
              title: const Text('New Playlist'),
              onTap: () async {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, widget.song);
              },
            ),
            const Divider(color: Colors.white10),
            ..._playlists.map((playlist) => ListTile(
              leading: const Icon(Icons.music_note, color: Colors.white70),
              title: Text(playlist.name),
              onTap: () async {
                final success = await ApiService().addTrackToPlaylist(playlist.id, widget.song);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Added to ${playlist.name}' : 'Failed to add'), backgroundColor: success ? AppColors.spotifyGreen : Colors.red),
                  );
                }
              },
            )).toList(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistScreen(initialSong: song),
      ),
    ).then((created) {
      if (created == true && context.mounted) {
        _PlaylistPickerSheet.show(context, song);
      }
    });
  }
}
