import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../playlist/playlist_screen.dart';
import '../player/now_playing_screen.dart';
import '../playlist/create_playlist_screen.dart';
import '../artist/artist_screen.dart';
import '../album/album_screen.dart';
import '../../services/api_service.dart';
import '../../models/song.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/profile_avatar.dart';
import '../../models/playlist.dart';
import '../../utils/song_options_helper.dart';
import '../../utils/image_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  List<Song> _searchResults = [];
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  final List<String> _searchFilters = ['All', 'Songs', 'Podcasts & Shows', 'Artists', 'Playlists', 'Albums'];
  String _activeFilter = 'All';
  List<String> _recentSearches = [];
  
  // Adapting placeholder text list that cycles to encourage user exploration
  final List<String> _placeholders = [
    'What do you want to listen to?',
    'Songs, artists, or albums...',
    'Explore new genres and mixes...',
    'Afrobeats, Pop, Hip-Hop...',
    'What is your vibe today?',
  ];
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;

  // Trending search suggestions that trigger query execution on tap
  final List<String> _trendingSearches = [
    'Taylor Swift',
    'Afrobeats',
    'Lofi Sleep',
    'Chill Vibes',
    'Gym Workout',
    'Daily Mix 2026'
  ];

  // Curated horizontal cards mapping personalized mix recommendations
  final List<Map<String, String>> _mockRecommendations = [
    {
      'title': 'Discover Weekly',
      'desc': 'Your weekly mixtape of fresh vibes.',
      'coverUrl': 'https://picsum.photos/300/300?random=200',
      'color': '0xFF3E3264',
    },
    {
      'title': 'Release Radar',
      'desc': 'Catch all the newest releases.',
      'coverUrl': 'https://picsum.photos/300/300?random=201',
      'color': '0xFF1E3264',
    },
    {
      'title': 'Daily Mix 1',
      'desc': 'Dadju, Tayc, and more.',
      'coverUrl': 'https://picsum.photos/300/300?random=202',
      'color': '0xFF474747',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _startPlaceholderAnimation();
  }

  void _startPlaceholderAnimation() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_isSearching && _searchController.text.isEmpty) {
        setState(() {
          _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
        });
      }
    });
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

  void _showCodeScanner() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => const _SportifyCodeScannerDialog(),
    );
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
    _placeholderTimer?.cancel();
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
                      if (!_hasSubmitted) ...[
                        _buildSuggestionsDropdown(),
                      ] else ...[
                        _buildSearchFilters(),
                        const SizedBox(height: 24),
                        _buildSearchResults(),
                      ],
                    ] else ...[
                      const SizedBox(height: 24),
                      if (_recentSearches.isNotEmpty) _buildSearchHistory(),
                      _buildTrendingSearches(),
                      _buildRecommendations(),
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

  // Filters tab row above search results to restrict categories and re-rank results
  Widget _buildSearchFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _searchFilters.map((filter) {
          final isSelected = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = filter;
              });
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
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
    
    final ranked = _rankResults(_searchResults, _activeFilter);

    if (ranked.isEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: AppColors.secondaryText)));
    }
    
    final tracks = ranked.where((s) => s.type == 'track').toList();
    final artists = ranked.where((s) => s.type == 'artist').toList();
    final albums = ranked.where((s) => s.type == 'album').toList();
    final podcasts = ranked.where((s) => s.type == 'podcast').toList();
    final playlists = ranked.where((s) => s.type == 'playlist').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_activeFilter == 'All' && ranked.isNotEmpty) ...[
          const Text('Top result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTopResult(ranked.first),
          const SizedBox(height: 32),
        ],

        if (artists.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Artists')) ...[
          const Text('Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...artists.map((artist) => _buildArtistTile(artist)),
          const SizedBox(height: 24),
        ],

        if (tracks.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Songs')) ...[
          const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...tracks.map((song) => _buildTrackTile(song)),
          const SizedBox(height: 24),
        ],

        if (albums.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Albums')) ...[
          const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...albums.map((album) => _buildAlbumTile(album)),
          const SizedBox(height: 24),
        ],
        
        if (podcasts.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Podcasts & Shows')) ...[
          const Text('Podcasts & Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...podcasts.map((podcast) => _buildPodcastTile(podcast)),
          const SizedBox(height: 24),
        ],
        
        if (playlists.isNotEmpty && (_activeFilter == 'All' || _activeFilter == 'Playlists')) ...[
          const Text('Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...playlists.map((playlist) => _buildAlbumTile(playlist)),
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
              child: ImageHelper.imageWidget(topResult.coverUrl, width: 80, height: 80, fit: BoxFit.cover),
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
        child: ImageHelper.imageWidget(artist.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
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
      leading: ImageHelper.imageWidget(album.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
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
      leading: ImageHelper.imageWidget(song.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: SizedBox(
        width: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final isLiked = player.isLiked(song.id);
                return GestureDetector(
                  onTap: () => player.toggleLike(song),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.spotifyGreen : AppColors.secondaryText,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showSongOptions(context, song),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.more_vert,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
              ),
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




  // Prominent query search bar that matches typing queries and dynamically swaps
  // suffix actions between cancel/clear and camera/scanning icons.
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
            _hasSubmitted = false; // Show suggestions overlay while typing
          });
          
          if (value.isNotEmpty) {
            _updateSuggestions(value);
          } else {
            setState(() {
              _suggestions = [];
            });
          }
          
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (value.isNotEmpty) {
              _performSearch(value);
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
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            setState(() {
              _isSearching = true;
              _hasSubmitted = true;
              _isLoading = true;
            });
            _performSearch(value);
          }
        },
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 28),
          hintText: _placeholders[_placeholderIndex],
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontWeight: FontWeight.w500, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _isSearching 
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _hasSubmitted = false;
                      _searchResults = [];
                      _suggestions = [];
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.black54, size: 24),
                  onPressed: _showCodeScanner, // Open modern Sportify code scanning mockup
                ),
        ),
      ),
    );
  }

  // Generates real-time suggestions by blending lexical matching with user-history and trending signals
  void _updateSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    
    final lowerQuery = query.toLowerCase().trim();
    final List<Map<String, dynamic>> candidates = [];
    
    // 1. User History Matches (from PlayerProvider history and liked songs)
    final history = context.read<PlayerProvider>().history;
    final liked = context.read<PlayerProvider>().likedSongs;
    
    for (var song in history) {
      if (song.title.toLowerCase().contains(lowerQuery) || song.artist.toLowerCase().contains(lowerQuery)) {
        candidates.add({
          'title': song.title,
          'subtitle': 'Song • ${song.artist} (From history)',
          'type': 'history',
          'song': song,
          'score': 100.0,
        });
      }
    }
    
    for (var song in liked) {
      if (song.title.toLowerCase().contains(lowerQuery) || song.artist.toLowerCase().contains(lowerQuery)) {
        if (!candidates.any((c) => c['song']?.id == song.id)) {
          candidates.add({
            'title': song.title,
            'subtitle': 'Liked Song • ${song.artist}',
            'type': 'liked',
            'song': song,
            'score': 90.0,
          });
        }
      }
    }
    
    // 2. Regional / Trending Matches (combines popularity + regional weights)
    final trendingSongs = [
      {'title': 'Anti-Hero', 'artist': 'Taylor Swift', 'genre': 'Pop', 'popularity': 95},
      {'title': 'Last Last', 'artist': 'Burna Boy', 'genre': 'Afrobeats', 'popularity': 92},
      {'title': 'Calm Down', 'artist': 'Rema', 'genre': 'Afrobeats', 'popularity': 90},
      {'title': 'Starboy', 'artist': 'The Weeknd', 'genre': 'Pop', 'popularity': 88},
      {'title': 'Mockingbird', 'artist': 'Eminem', 'genre': 'Hip-Hop', 'popularity': 85},
    ];
    
    for (var ts in trendingSongs) {
      final tTitle = ts['title'] as String;
      final tArtist = ts['artist'] as String;
      if (tTitle.toLowerCase().contains(lowerQuery) || tArtist.toLowerCase().contains(lowerQuery)) {
        double score = (ts['popularity'] as int).toDouble();
        if (ts['genre'] == 'Afrobeats') {
          score += 15.0; // Boost regional Afrobeats trending weight
        }
        
        if (!candidates.any((c) => c['title'].toLowerCase() == tTitle.toLowerCase())) {
          candidates.add({
            'title': tTitle,
            'subtitle': 'Trending in your Region • $tArtist',
            'type': 'trending',
            'song': Song(
              id: 'trending_${tTitle.hashCode}',
              title: tTitle,
              artist: tArtist,
              albumId: '',
              albumName: 'Single',
              coverUrl: 'https://picsum.photos/150/150?random=${tTitle.hashCode.abs() % 100}',
              duration: const Duration(minutes: 3),
              artistId: '',
              previewUrl: '',
              type: 'track',
            ),
            'score': score,
          });
        }
      }
    }

    // 3. Common Search Autocomplete Intents
    final autocompleteSuggestions = [
      'Taylor Swift hits',
      'Afrobeats Mix 2026',
      'Lofi Sleep Chillout',
      'Gym Workout hip hop',
      'Chill vibes playlist',
    ];
    for (var sug in autocompleteSuggestions) {
      if (sug.toLowerCase().contains(lowerQuery)) {
        candidates.add({
          'title': sug,
          'subtitle': 'Search intent',
          'type': 'intent',
          'score': 50.0,
        });
      }
    }
    
    // Sort combined suggestion candidates by hybrid score descending
    candidates.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    setState(() {
      _suggestions = candidates.take(6).toList();
    });
  }

  // Renders the real-time suggestions drop down list
  Widget _buildSuggestionsDropdown() {
    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Keep typing to see suggestions...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Search Suggestions',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        ..._suggestions.map((sug) {
          IconData icon;
          Color iconColor;
          switch (sug['type']) {
            case 'history':
              icon = Icons.history;
              iconColor = AppColors.spotifyGreen;
              break;
            case 'liked':
              icon = Icons.favorite;
              iconColor = AppColors.spotifyGreen;
              break;
            case 'trending':
              icon = Icons.trending_up;
              iconColor = Colors.orangeAccent;
              break;
            default:
              icon = Icons.search;
              iconColor = Colors.white54;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(icon, color: iconColor, size: 20),
              title: Text(
                sug['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                sug['subtitle'],
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: const Icon(Icons.north_west, color: Colors.white30, size: 16),
              onTap: () {
                _searchController.text = sug['title'];
                _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                setState(() {
                  _isSearching = true;
                  _hasSubmitted = true;
                  _isLoading = true;
                });
                _performSearch(sug['title']);
              },
            ),
          );
        }),
      ],
    );
  }

  // Ranks the search results using a hybrid scoring algorithm combining lexical and behavioral signals
  List<Song> _rankResults(List<Song> results, String filter) {
    if (results.isEmpty) return [];
    
    final query = _searchController.text.toLowerCase().trim();
    final player = context.read<PlayerProvider>();
    final history = player.history;
    final liked = player.likedSongs;

    // First, filter candidate matches strictly by category if tab is selected
    List<Song> filtered = [];
    if (filter == 'All') {
      filtered = List.from(results);
    } else if (filter == 'Songs') {
      filtered = results.where((s) => s.type == 'track').toList();
    } else if (filter == 'Artists') {
      filtered = results.where((s) => s.type == 'artist').toList();
    } else if (filter == 'Albums') {
      filtered = results.where((s) => s.type == 'album').toList();
    } else if (filter == 'Playlists') {
      filtered = results.where((s) => s.type == 'playlist').toList();
    } else if (filter == 'Podcasts & Shows') {
      filtered = results.where((s) => s.type == 'podcast').toList();
    }

    // Score and rank candidates based on multiple signals
    final List<Map<String, dynamic>> scored = filtered.map((song) {
      double score = 0;
      
      final title = song.title.toLowerCase();
      final artist = song.artist.toLowerCase();

      // 1. Lexical Matching Weights
      if (title == query || artist == query) {
        score += 100.0; // Exact match bonus
      } else if (title.startsWith(query) || artist.startsWith(query)) {
        score += 50.0; // Phrase starts-with bonus
      } else if (title.contains(query) || artist.contains(query)) {
        score += 25.0; // Substring keyword match
      }

      // 2. Behavioral/Personal taste profile boost
      bool artistPlayedBefore = history.any((s) => s.artist.toLowerCase() == artist);
      bool songPlayedBefore = history.any((s) => s.id == song.id);
      bool isLikedTrack = liked.any((s) => s.id == song.id);

      if (songPlayedBefore) score += 40.0;
      if (artistPlayedBefore) score += 20.0;
      if (isLikedTrack) score += 30.0;

      // 3. Global Popularity mock weight
      double globalPopularity = 50.0;
      if (song.id.startsWith('trending_')) {
        globalPopularity = 90.0;
      } else {
        globalPopularity = (song.title.length % 5) * 10.0 + 50.0;
      }
      score += globalPopularity * 0.2;

      // 4. Behavioral Skip Rate Discount
      final int hash = song.id.hashCode.abs();
      final double mockSkipRate = (hash % 100) / 100.0;
      score -= (mockSkipRate * 15.0);

      return {
        'song': song,
        'score': score,
      };
    }).toList();

    // Sort descending by relevance score
    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return scored.map((item) => item['song'] as Song).toList();
  }

  // Triggers the hybrid search logic. 
  // Lexical search (via API matching what was typed) is executed asynchronously,
  // and we overlay mock podcasts for podcasts & shows category matches.
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    
    String searchType = 'track';
    if (_activeFilter == 'Artists') searchType = 'artist';
    if (_activeFilter == 'Albums') searchType = 'album';
    if (_activeFilter == 'Playlists') searchType = 'playlist';
    if (_activeFilter == 'Podcasts & Shows') searchType = 'show';
    if (_activeFilter == 'All') searchType = 'track,artist,album';

    try {
      final spotifyFuture = ApiService().searchSpotify(query, type: searchType).catchError((e) => <Song>[]);
      final deezerFuture = ApiService().searchDeezer(query).catchError((e) => <Song>[]);

      final results = await Future.wait([spotifyFuture, deezerFuture]);
      final combinedResults = [...results[0], ...results[1]];
      
      // Inject mock podcasts if current filter matches
      if (_activeFilter == 'All' || _activeFilter == 'Podcasts & Shows') {
        final mockPodcasts = _getMockPodcasts(query);
        combinedResults.addAll(mockPodcasts);
      }

      if (mounted) {
        setState(() {
          _searchResults = combinedResults;
          _isLoading = false;
        });
        _saveSearchHistory(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Generates high-fidelity mock podcasts matching lexical input
  List<Song> _getMockPodcasts(String query) {
    final lowerQuery = query.toLowerCase();
    final List<Map<String, String>> allMock = [
      {
        'id': 'podcast_rogan',
        'title': 'The Joe Rogan Experience',
        'artist': 'Joe Rogan',
        'coverUrl': 'https://picsum.photos/150/150?random=100',
      },
      {
        'id': 'podcast_lex',
        'title': 'Lex Fridman Podcast',
        'artist': 'Lex Fridman',
        'coverUrl': 'https://picsum.photos/150/150?random=101',
      },
      {
        'id': 'podcast_huberman',
        'title': 'Huberman Lab',
        'artist': 'Dr. Andrew Huberman',
        'coverUrl': 'https://picsum.photos/150/150?random=102',
      },
      {
        'id': 'podcast_daily',
        'title': 'The Daily',
        'artist': 'The New York Times',
        'coverUrl': 'https://picsum.photos/150/150?random=103',
      }
    ];

    return allMock
        .where((p) => p['title']!.toLowerCase().contains(lowerQuery) || p['artist']!.toLowerCase().contains(lowerQuery))
        .map((p) => Song(
              id: p['id']!,
              title: p['title']!,
              artist: p['artist']!,
              albumId: '',
              albumName: 'Podcast',
              coverUrl: p['coverUrl']!,
              duration: const Duration(minutes: 45),
              artistId: '',
              previewUrl: '',
              type: 'podcast',
            ))
        .toList();
  }

  // Renders trending search suggestion wrap chips
  Widget _buildTrendingSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending searches',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingSearches.map((tag) => InkWell(
            onTap: () {
              _searchController.text = tag;
              setState(() {
                _isSearching = true;
                _isLoading = true;
              });
              _performSearch(tag);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.08),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.white.withOpacity(0.12)),
               ),
              child: Text(
                tag,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Renders horizontal personalized recommended mix cards
  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for you',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _mockRecommendations.length,
            itemBuilder: (context, index) {
              final item = _mockRecommendations[index];
              final colorHex = int.parse(item['color']!);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistScreen(
                        title: item['title']!,
                        playlistId: 'playlist_rec_$index',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Color(colorHex).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        child: ImageHelper.imageWidget(
                          item['coverUrl']!,
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['title']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['desc']!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                       ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // Renders a podcast tile
  Widget _buildPodcastTile(Song podcast) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ImageHelper.imageWidget(podcast.coverUrl, width: 52, height: 52, fit: BoxFit.cover),
      ),
      title: Text(podcast.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${podcast.artist} • Podcast', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Streaming "${podcast.title}" trailer...'),
            backgroundColor: AppColors.spotifyGreen,
          ),
        );
      },
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
            setState(() { 
              _isSearching = true;
            });
            _performSearch(query);
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
            image: ImageHelper.getImageProvider(imageUrl) ?? const NetworkImage('https://via.placeholder.com/150'),
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
        _buildCategoryCard('Pop', const Color(0xFF148A08), 'https://picsum.photos/100?10'),
        _buildCategoryCard('Afrobeats', const Color(0xFFD84000), 'https://picsum.photos/100?8'),
        _buildCategoryCard('Hip-Hop', const Color(0xFFE8115B), 'https://picsum.photos/100?4'),
        _buildCategoryCard('Rock', const Color(0xFFE13300), 'https://picsum.photos/100?5'),
        _buildCategoryCard('Lofi', const Color(0xFF27856A), 'https://picsum.photos/100?1'),
        _buildCategoryCard('Electronic', const Color(0xFF8471F2), 'https://picsum.photos/100?2'),
        _buildCategoryCard('Podcasts', const Color(0xFF1E3264), 'https://picsum.photos/100?3'),
        _buildCategoryCard('Live Events', const Color(0xFF8D67AB), 'https://picsum.photos/100?9'),
        _buildCategoryCard('Made For You', const Color(0xFFB02897), 'https://picsum.photos/100?6'),
        _buildCategoryCard('New Releases', const Color(0xFFA56752), 'https://picsum.photos/100?7'),
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
                      image: ImageHelper.getImageProvider(imageUrl) ?? const NetworkImage('https://via.placeholder.com/150'),
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
            child: ImageHelper.imageWidget(imageUrl, fit: BoxFit.cover),
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
                  child: ImageHelper.imageWidget(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
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

class _GenreHubData {
  final List<Map<String, String>> playlists;
  final List<Song> topTracks;
  final List<Map<String, String>> artists;

  _GenreHubData({required this.playlists, required this.topTracks, required this.artists});

  factory _GenreHubData.getForGenre(String genre) {
    final cleanGenre = genre.trim();
    if (cleanGenre == 'Pop') {
      return _GenreHubData(
        playlists: [
          {'title': 'Today\'s Top Hits', 'coverUrl': 'https://picsum.photos/300/300?random=11'},
          {'title': 'Pop Rising', 'coverUrl': 'https://picsum.photos/300/300?random=12'},
          {'title': 'Pop Chill', 'coverUrl': 'https://picsum.photos/300/300?random=13'},
        ],
        topTracks: [
          Song(id: 'pop_track_1', title: 'Anti-Hero', artist: 'Taylor Swift', albumId: 'pop_alb_1', albumName: 'Midnights', coverUrl: 'https://picsum.photos/150/150?random=14', duration: const Duration(minutes: 3, seconds: 20), artistId: 'artist_swift', previewUrl: '', type: 'track'),
          Song(id: 'pop_track_2', title: 'Starboy', artist: 'The Weeknd', albumId: 'pop_alb_2', albumName: 'Starboy', coverUrl: 'https://picsum.photos/150/150?random=15', duration: const Duration(minutes: 3, seconds: 50), artistId: 'artist_weeknd', previewUrl: '', type: 'track'),
          Song(id: 'pop_track_3', title: 'Flowers', artist: 'Miley Cyrus', albumId: 'pop_alb_3', albumName: 'Endless Summer Vacation', coverUrl: 'https://picsum.photos/150/150?random=16', duration: const Duration(minutes: 3, seconds: 20), artistId: 'artist_cyrus', previewUrl: '', type: 'track'),
        ],
        artists: [
          {'name': 'Taylor Swift', 'avatarUrl': 'https://picsum.photos/150/150?random=17', 'id': 'artist_swift'},
          {'name': 'The Weeknd', 'avatarUrl': 'https://picsum.photos/150/150?random=18', 'id': 'artist_weeknd'},
          {'name': 'Miley Cyrus', 'avatarUrl': 'https://picsum.photos/150/150?random=19', 'id': 'artist_cyrus'},
        ],
      );
    } else if (cleanGenre == 'Afrobeats') {
      return _GenreHubData(
        playlists: [
          {'title': 'Afrobeats Essentials', 'coverUrl': 'https://picsum.photos/300/300?random=21'},
          {'title': 'African Heat', 'coverUrl': 'https://picsum.photos/300/300?random=22'},
          {'title': 'Amapiano Grooves', 'coverUrl': 'https://picsum.photos/300/300?random=23'},
        ],
        topTracks: [
          Song(id: 'afro_track_1', title: 'Last Last', artist: 'Burna Boy', albumId: 'afro_alb_1', albumName: 'Love, Damini', coverUrl: 'https://picsum.photos/150/150?random=24', duration: const Duration(minutes: 2, seconds: 52), artistId: 'artist_burna', previewUrl: '', type: 'track'),
          Song(id: 'afro_track_2', title: 'Calm Down', artist: 'Rema', albumId: 'afro_alb_2', albumName: 'Rave & Roses', coverUrl: 'https://picsum.photos/150/150?random=25', duration: const Duration(minutes: 3, seconds: 39), artistId: 'artist_rema', previewUrl: '', type: 'track'),
          Song(id: 'afro_track_3', title: 'Essence', artist: 'Wizkid', albumId: 'afro_alb_3', albumName: 'Made in Lagos', coverUrl: 'https://picsum.photos/150/150?random=26', duration: const Duration(minutes: 4, seconds: 08), artistId: 'artist_wizkid', previewUrl: '', type: 'track'),
        ],
        artists: [
          {'name': 'Burna Boy', 'avatarUrl': 'https://picsum.photos/150/150?random=27', 'id': 'artist_burna'},
          {'name': 'Rema', 'avatarUrl': 'https://picsum.photos/150/150?random=28', 'id': 'artist_rema'},
          {'name': 'Wizkid', 'avatarUrl': 'https://picsum.photos/150/150?random=29', 'id': 'artist_wizkid'},
        ],
      );
    } else if (cleanGenre == 'Hip-Hop') {
      return _GenreHubData(
        playlists: [
          {'title': 'RapCaviar', 'coverUrl': 'https://picsum.photos/300/300?random=31'},
          {'title': 'Realest Rap', 'coverUrl': 'https://picsum.photos/300/300?random=32'},
          {'title': 'Gold School', 'coverUrl': 'https://picsum.photos/300/300?random=33'},
        ],
        topTracks: [
          Song(id: 'hip_track_1', title: 'Mockingbird', artist: 'Eminem', albumId: 'hip_alb_1', albumName: 'Encore', coverUrl: 'https://picsum.photos/150/150?random=34', duration: const Duration(minutes: 4, seconds: 11), artistId: 'artist_eminem', previewUrl: '', type: 'track'),
          Song(id: 'hip_track_2', title: 'God\'s Plan', artist: 'Drake', albumId: 'hip_alb_2', albumName: 'Scorpion', coverUrl: 'https://picsum.photos/150/150?random=35', duration: const Duration(minutes: 3, seconds: 18), artistId: 'artist_drake', previewUrl: '', type: 'track'),
          Song(id: 'hip_track_3', title: 'HUMBLE.', artist: 'Kendrick Lamar', albumId: 'hip_alb_3', albumName: 'DAMN.', coverUrl: 'https://picsum.photos/150/150?random=36', duration: const Duration(minutes: 2, seconds: 57), artistId: 'artist_kendrick', previewUrl: '', type: 'track'),
        ],
        artists: [
          {'name': 'Eminem', 'avatarUrl': 'https://picsum.photos/150/150?random=37', 'id': 'artist_eminem'},
          {'name': 'Drake', 'avatarUrl': 'https://picsum.photos/150/150?random=38', 'id': 'artist_drake'},
          {'name': 'Kendrick Lamar', 'avatarUrl': 'https://picsum.photos/150/150?random=39', 'id': 'artist_kendrick'},
        ],
      );
    } else {
      return _GenreHubData(
        playlists: [
          {'title': '$genre Mix', 'coverUrl': 'https://picsum.photos/300/300?random=41'},
          {'title': 'Best of $genre', 'coverUrl': 'https://picsum.photos/300/300?random=42'},
          {'title': 'Chill $genre', 'coverUrl': 'https://picsum.photos/300/300?random=43'},
        ],
        topTracks: [
          Song(id: 'gen_track_1', title: '$genre Hits Vol. 1', artist: 'Popular Artist', albumId: 'gen_alb_1', albumName: 'Album Vol 1', coverUrl: 'https://picsum.photos/150/150?random=44', duration: const Duration(minutes: 3, seconds: 15), artistId: 'gen_art_1', previewUrl: '', type: 'track'),
          Song(id: 'gen_track_2', title: '$genre Sessions', artist: 'Trending Project', albumId: 'gen_alb_2', albumName: 'Sessions Live', coverUrl: 'https://picsum.photos/150/150?random=45', duration: const Duration(minutes: 3, seconds: 45), artistId: 'gen_art_2', previewUrl: '', type: 'track'),
        ],
        artists: [
          {'name': 'Popular Artist', 'avatarUrl': 'https://picsum.photos/150/150?random=46', 'id': 'gen_art_1'},
          {'name': 'Trending Project', 'avatarUrl': 'https://picsum.photos/150/150?random=47', 'id': 'gen_art_2'},
        ],
      );
    }
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final Color color;

  const CategoryDetailScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final hubData = _GenreHubData.getForGenre(title);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: color,
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, AppColors.primaryBackground],
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Text(title, style: const TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Featured Playlists', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: hubData.playlists.length,
                      itemBuilder: (context, index) {
                        final pl = hubData.playlists[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistScreen(
                                  title: pl['title']!,
                                  playlistId: 'playlist_genre_${title.toLowerCase()}_$index',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: ImageHelper.imageWidget(
                                    pl['coverUrl']!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pl['title']!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text('Top Tracks in $title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  ...hubData.topTracks.map((song) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ImageHelper.imageWidget(song.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
                      ),
                      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_filled, color: AppColors.spotifyGreen, size: 36),
                        onPressed: () {
                          context.read<PlayerProvider>().playSong(song);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NowPlayingScreen(song: song)),
                          );
                        },
                      ),
                      onTap: () {
                        context.read<PlayerProvider>().playSong(song);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NowPlayingScreen(song: song)),
                        );
                      },
                    ),
                  )),
                  const SizedBox(height: 32),

                  const Text('Featured Artists', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: hubData.artists.length,
                      itemBuilder: (context, index) {
                        final art = hubData.artists[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtistScreen(
                                  artistId: art['id']!,
                                  artistName: art['name']!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundImage: ImageHelper.getImageProvider(art['avatarUrl']!),
                                  backgroundColor: Colors.white12,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  art['name']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final success = await ApiService().addTrackToPlaylist(playlist.id, widget.song);
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(success ? 'Added to ${playlist.name}' : 'Failed to add'), backgroundColor: success ? AppColors.spotifyGreen : Colors.red),
                );
              },
            )),
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

class _SportifyCodeScannerDialog extends StatefulWidget {
  const _SportifyCodeScannerDialog();

  @override
  State<_SportifyCodeScannerDialog> createState() => _SportifyCodeScannerDialogState();
}

class _SportifyCodeScannerDialogState extends State<_SportifyCodeScannerDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 200.0).animate(_animController);

    _scanTimer = Timer(const Duration(milliseconds: 1800), () async {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        
        // Mock a successfully scanned song
        final mockScannedSong = Song(
          id: 'scanned_track_1',
          title: 'Last Last',
          artist: 'Burna Boy',
          albumId: 'album_burna_1',
          albumName: 'Love, Damini',
          coverUrl: 'https://picsum.photos/300/300?random=88',
          duration: const Duration(minutes: 2, seconds: 52),
          artistId: 'artist_burna',
          previewUrl: '',
          type: 'track',
        );

        // Play song
        final player = Provider.of<PlayerProvider>(context, listen: false);
        player.playSong(mockScannedSong);
        
        // Navigate to player screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NowPlayingScreen(song: mockScannedSong)),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.qr_code_scanner, color: Colors.black),
                SizedBox(width: 8),
                Text('Sportify Code scanned: Burna Boy - Last Last!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.spotifyGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scan Sportify Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.spotifyGreen.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.15), size: 64),
                        const SizedBox(height: 8),
                        Text('Initializing camera...', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                // Scanning Line Animation
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: 10 + _animation.value,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.spotifyGreen,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.spotifyGreen.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Corner guides
                Positioned(top: 8, left: 8, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.spotifyGreen, width: 3), left: BorderSide(color: AppColors.spotifyGreen, width: 3))))),
                Positioned(top: 8, right: 8, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.spotifyGreen, width: 3), right: BorderSide(color: AppColors.spotifyGreen, width: 3))))),
                Positioned(bottom: 8, left: 8, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.spotifyGreen, width: 3), left: BorderSide(color: AppColors.spotifyGreen, width: 3))))),
                Positioned(bottom: 8, right: 8, child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.spotifyGreen, width: 3), right: BorderSide(color: AppColors.spotifyGreen, width: 3))))),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Align a Sportify Code or QR Code in the frame to automatically scan and play.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
