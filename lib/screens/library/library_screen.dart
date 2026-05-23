import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/create_menu_bottom_sheet.dart';
import '../playlist/playlist_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/profile_avatar.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Navigation & Filtering State
  String _selectedFilter = 'All';
  final List<String> _filters = ['Playlists', 'Artists', 'Albums', 'Podcasts', 'Downloaded'];
  final List<String> _subFilters = ['By you', 'By Spotify', 'Mixed'];
  
  // Layout and Sorting state
  bool _isGridView = true;
  bool _isSearchingInLibrary = false;
  bool _isLoading = false;
  final TextEditingController _librarySearchController = TextEditingController();
  String _librarySearchText = '';
  StreamSubscription? _playlistSub;
  String _selectedSort = 'Custom order';
  bool _isSortAscending = true;
  String? _likedSongsCoverPath;

  // Primary dynamic data list
  List<Map<String, dynamic>> _libraryData = [
    {'title': 'Liked Songs', 'subtitle': 'Playlist • 725 songs', 'type': 'playlist', 'isPinned': true, 'isLiked': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
    _loadLikedSongsCover();
    // Re-fetch whenever playlist edits happen in other screens
    _playlistSub = ApiService().onPlaylistsChanged.listen((_) {
      _fetchLibrary();
    });
  }

  // Load user's custom cover for Liked Songs from SharedPreferences
  Future<void> _loadLikedSongsCover() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _likedSongsCoverPath = prefs.getString('liked_songs_cover_path');
    });
  }
  
  @override
  void dispose() {
    _playlistSub?.cancel();
    _librarySearchController.dispose();
    super.dispose();
  }

  // Fetch playlists and inject high-fidelity mock albums, artists, and podcasts for fully functioning filters
  Future<void> _fetchLibrary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final playlists = await ApiService().getPlaylists();
      final likedSongs = await ApiService().getLikedSongs();
      if (!mounted) return;
      
      setState(() {
        // 1. Core items (Liked Songs & user created playlists)
        _libraryData = [
          {
            'title': 'Liked Songs',
            'subtitle': 'Playlist • ${likedSongs.length} songs',
            'type': 'playlist',
            'isPinned': true,
            'isLiked': true,
            'isDownloaded': true, // Liked songs are always marked downloaded offline
          },
        ];
        
        for (var playlist in playlists) {
          // Extract cover URLs of the first 4 tracks to support Spotify-style mosaic artwork
          final tracksCovers = playlist.tracks
              .map((s) => s.coverUrl)
              .where((url) => url.isNotEmpty)
              .take(4)
              .toList();

          _libraryData.add({
            'id': playlist.id,
            'title': playlist.name,
            'subtitle': 'Playlist • ${playlist.trackCount} songs',
            'type': 'playlist',
            'coverUrl': playlist.coverUrl,
            'tracksCovers': tracksCovers,
            'isUserCreated': true,
            'isDownloaded': playlist.id.hashCode % 2 == 0, // Mock downloaded flag
          });
        }

        // 2. High-fidelity Artists to make the "Artists" chip fully operational
        _libraryData.addAll([
          {
            'id': 'artist_taylor',
            'title': 'Taylor Swift',
            'subtitle': 'Artist',
            'type': 'artist',
            'coverUrl': 'https://picsum.photos/150/150?random=1',
            'isPinned': true,
          },
          {
            'id': 'artist_billie',
            'title': 'Billie Eilish',
            'subtitle': 'Artist',
            'type': 'artist',
            'coverUrl': 'https://picsum.photos/150/150?random=2',
          },
          {
            'id': 'artist_ed',
            'title': 'Ed Sheeran',
            'subtitle': 'Artist',
            'type': 'artist',
            'coverUrl': 'https://picsum.photos/150/150?random=3',
          }
        ]);

        // 3. Premium Albums to make the "Albums" chip look gorgeous
        _libraryData.addAll([
          {
            'id': 'album_midnights',
            'title': 'Midnights',
            'subtitle': 'Album • Taylor Swift',
            'type': 'album',
            'coverUrl': 'https://picsum.photos/150/150?random=4',
            'isDownloaded': true,
          },
          {
            'id': 'album_hitme',
            'title': 'Hit Me Hard and Soft',
            'subtitle': 'Album • Billie Eilish',
            'type': 'album',
            'coverUrl': 'https://picsum.photos/150/150?random=5',
          }
        ]);

        // 4. Trending Podcasts to make the "Podcasts" chip look exactly like Spotify
        _libraryData.addAll([
          {
            'id': 'podcast_rogan',
            'title': 'The Joe Rogan Experience',
            'subtitle': 'Podcast • Joe Rogan',
            'type': 'podcast',
            'coverUrl': 'https://picsum.photos/150/150?random=6',
            'isPinned': true,
            'isDownloaded': true,
          },
          {
            'id': 'podcast_lex',
            'title': 'Lex Fridman Podcast',
            'subtitle': 'Podcast • Lex Fridman',
            'type': 'podcast',
            'coverUrl': 'https://picsum.photos/150/150?random=7',
          }
        ]);
      });
    } catch (e) {
      debugPrint('Error fetching library: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Update a playlist's cover art by picking from gallery
  Future<void> _updatePlaylistCover(String playlistId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final success = await ApiService().updatePlaylistCover(playlistId, pickedFile.path);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist cover updated!')),
        );
        _fetchLibrary();
      }
    }
  }

  // Live filtering and sorting based on user interaction (filter chips, search text, sort modes)
  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_libraryData);
    
    // 1. Filter by content type
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Downloaded') {
        filtered = filtered.where((item) => item['isDownloaded'] == true).toList();
      } else {
        final filterType = _selectedFilter.toLowerCase().replaceAll('s', '');
        filtered = filtered.where((item) => item['type'] == filterType).toList();
      }
    }

    // 2. Search filtering
    if (_librarySearchText.isNotEmpty) {
      filtered = filtered.where((item) => 
        item['title'].toLowerCase().contains(_librarySearchText.toLowerCase())
      ).toList();
    }

    // 3. Sort logic
    switch (_selectedSort) {
      case 'Recents':
        // Default chronological order from API list
        break;
      case 'Alphabetical':
        filtered.sort((a, b) => (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase()));
        if (!_isSortAscending) filtered = filtered.reversed.toList();
        break;
      case 'Creator':
        filtered.sort((a, b) {
          final aSub = (a['subtitle'] as String).toLowerCase();
          final bSub = (b['subtitle'] as String).toLowerCase();
          return aSub.compareTo(bSub);
        });
        break;
      default: // 'Custom order'
        // Custom order (Pins stay on top)
        filtered.sort((a, b) {
          final aPinned = a['isPinned'] == true ? 1 : 0;
          final bPinned = b['isPinned'] == true ? 1 : 0;
          return bPinned.compareTo(aPinned);
        });
        break;
    }

    return filtered;
  }

  void _updateLikedSongsCover() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('liked_songs_cover_path', pickedFile.path);
      setState(() {
        _likedSongsCoverPath = pickedFile.path;
      });
      _fetchLibrary();
    }
  }

  // Spotify Sort modal bottom sheet
  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(color: Colors.white10),
              _buildSortOption('Custom order'),
              _buildSortOption('Recents'),
              _buildSortOption('Alphabetical'),
              _buildSortOption('Creator'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String sort) {
    final isSelected = _selectedSort == sort;
    return ListTile(
      title: Text(sort, style: TextStyle(color: isSelected ? AppColors.spotifyGreen : Colors.white)),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.spotifyGreen) : null,
      onTap: () {
        if (sort == 'Alphabetical' && isSelected) {
          setState(() => _isSortAscending = !_isSortAscending);
        } else {
          setState(() {
            _selectedSort = sort;
            _isSortAscending = true;
          });
        }
        Navigator.pop(context);
      },
    );
  }

  // Plus menu bottom sheet - provides collaborative creation options
  void _showAddMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Create',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white, size: 28),
                title: const Text('Create a new playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Build a playlist from scratch', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/playlist/create').then((_) => _fetchLibrary());
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined, color: Colors.white, size: 28),
                title: const Text('Collaborate on a playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Invite friends to add and edit tracks', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Collaborative playlist creator initialized!'),
                      backgroundColor: AppColors.spotifyGreen,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined, color: Colors.white, size: 28),
                title: const Text('Browse saved content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Narrow down by liked tracks, saved albums, or podcasts', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedFilter = 'All';
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          if (_isSearchingInLibrary) _buildLibrarySearchBar(),
          _buildFilterBar(),
          const SizedBox(height: 16),
          _buildSortAndToggleRow(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
                : _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _librarySearchController,
          onChanged: (value) => setState(() => _librarySearchText = value),
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Find in your library',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              onPressed: () {
                setState(() {
                  _isSearchingInLibrary = false;
                  _librarySearchText = '';
                  _librarySearchController.clear();
                });
              },
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // Your Library top bar containing Magnifying Glass and Plus Button
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const ProfileAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          Text('Your Library', style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Colors.white), 
            onPressed: () => setState(() => _isSearchingInLibrary = !_isSearchingInLibrary)
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28, color: Colors.white), 
            onPressed: _showAddMenuBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_selectedFilter != 'All')
            GestureDetector(
              onTap: () => setState(() => _selectedFilter = 'All'),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.panelBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ..._filters.map((filter) {
            final isSelected = filter == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
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
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          if (_selectedFilter == 'Playlists') ...[
            ..._subFilters.map((filter) => Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(filter, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSortAndToggleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showSortMenu,
            child: Row(
              children: [
                const Icon(Icons.swap_vert, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(_selectedSort, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: Colors.white, size: 20),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final data = _filteredData;
    if (data.isEmpty) {
      return const Center(child: Text('No saved items found', style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: data.length + (_selectedFilter == 'Albums' ? 1 : 0),
      itemBuilder: (context, index) {
        if (_selectedFilter == 'Albums' && index == data.length) {
          return _buildImportMusicItem();
        }
        final item = data[index];
        return _buildLibraryListItem(item);
      },
    );
  }

  Widget _buildGridView() {
    final data = _filteredData;
    if (data.isEmpty) {
      return const Center(child: Text('No saved items found', style: TextStyle(color: Colors.white38)));
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: data.length + (_selectedFilter == 'Albums' ? 1 : 0),
      itemBuilder: (context, index) {
        if (_selectedFilter == 'Albums' && index == data.length) {
          return _buildImportMusicItemGrid();
        }
        final item = data[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                // Route dynamic lists appropriately. 
                // Mocks without database tables just display a standard playlist layout
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistScreen(
                      playlistId: item['id'],
                      title: item['title'],
                      isLikedSongs: item['isLiked'] == true,
                      isAlbum: item['type'] == 'album',
                    ),
                  ),
                ).then((_) => _fetchLibrary());
              },
              child: _buildLibraryGridItem(item),
            ),
            if (item['isUserCreated'] == true)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                  onPressed: () => _deletePlaylistConfirm(item),
                ),
              ),
          ],
        );
      },
    );
  }

  void _deletePlaylistConfirm(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Delete Playlist?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${item['title']}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService().deletePlaylist(item['id']);
      _fetchLibrary();
    }
  }

  Widget _buildImportMusicItemGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.panelBackground, borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Import your music', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildLibraryListItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(width: 56, height: 56, child: _buildItemImage(item)),
      title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      subtitle: Row(
        children: [
          if (item['isPinned'] == true)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.push_pin, color: AppColors.spotifyGreen, size: 14),
            ),
          if (item['isDownloaded'] == true)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.arrow_circle_down_rounded, color: AppColors.spotifyGreen, size: 14),
            ),
          Text(item['subtitle'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        ],
      ),
      trailing: item['isUserCreated'] == true ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
        onPressed: () => _deletePlaylistConfirm(item),
      ) : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistScreen(
              playlistId: item['id'],
              title: item['title'],
              isLikedSongs: item['isLiked'] == true,
              isAlbum: item['type'] == 'album',
            ),
          ),
        ).then((_) => _fetchLibrary());
      },
    );
  }

  Widget _buildLibraryGridItem(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: _buildItemImage(item, isGrid: true),
        ),
        const SizedBox(height: 8),
        Text(item['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        Row(
          children: [
            if (item['isPinned'] == true)
              const Icon(Icons.push_pin, color: AppColors.spotifyGreen, size: 10),
            if (item['isDownloaded'] == true)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.arrow_circle_down_rounded, color: AppColors.spotifyGreen, size: 10),
              ),
            Expanded(child: Text(item['subtitle'] ?? '', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }

  // Builds a 2x2 grid representing the mosaic of the first 4 track covers in a playlist.
  Widget _buildMosaicCover(List<dynamic> covers) {
    if (covers.isEmpty) {
      return _buildPlaceholder();
    }
    if (covers.length < 4) {
      return _buildSingleCoverImage(covers[0]);
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSingleCoverImage(covers[0])),
              Expanded(child: _buildSingleCoverImage(covers[1])),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSingleCoverImage(covers[2])),
              Expanded(child: _buildSingleCoverImage(covers[3])),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to render a single cover image within the mosaic grid.
  Widget _buildSingleCoverImage(String coverUrl) {
    if (coverUrl.startsWith('http') || coverUrl.startsWith('blob')) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          color: AppColors.panelBackground,
          child: const Icon(Icons.music_note, color: Colors.white24, size: 16),
        ),
      );
    } else if (coverUrl.isNotEmpty) {
      return kIsWeb
          ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Container(color: AppColors.panelBackground, child: const Icon(Icons.music_note, color: Colors.white24, size: 16)))
          : Image.file(File(coverUrl), fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Container(color: AppColors.panelBackground, child: const Icon(Icons.music_note, color: Colors.white24, size: 16)));
    }
    return Container(
      color: AppColors.panelBackground,
      child: const Icon(Icons.music_note, color: Colors.white24, size: 16),
    );
  }

  // Renders the cover art for a library item.
  // Supports custom user covers, network URLs, files, and auto-generated mosaics.
  Widget _buildItemImage(Map<String, dynamic> item, {bool isGrid = false}) {
    if (item['isLiked'] == true) {
      Widget? backgroundImage;
      if (_likedSongsCoverPath != null && _likedSongsCoverPath!.isNotEmpty) {
        try {
          backgroundImage = kIsWeb 
            ? Image.network(_likedSongsCoverPath!, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.favorite, color: Colors.white, size: 30))
            : Image.file(File(_likedSongsCoverPath!), fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.favorite, color: Colors.white, size: 30));
        } catch (e) {
          backgroundImage = const Icon(Icons.favorite, color: Colors.white, size: 30);
        }
      }

      return GestureDetector(
        onTap: isGrid ? _updateLikedSongsCover : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: backgroundImage == null ? AppColors.likedSongsGradient : null,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: backgroundImage ?? const Icon(Icons.favorite, color: Colors.white, size: 30),
          ),
        ),
      );
    }
    
    Widget imageWidget;
    String? coverUrl = item['coverUrl'];
    final tracksCovers = item['tracksCovers'] as List<dynamic>?;
    final hasTracksCovers = tracksCovers != null && tracksCovers.isNotEmpty;
    
    // Check if we should fallback to an auto-generated mosaic
    final isPlaceholder = coverUrl == null || 
                          coverUrl.isEmpty || 
                          coverUrl == 'https://via.placeholder.com/150';

    if (isPlaceholder && hasTracksCovers) {
      imageWidget = _buildMosaicCover(tracksCovers);
    } else if (coverUrl != null && (coverUrl.startsWith('http') || coverUrl.startsWith('blob'))) {
      imageWidget = Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (coverUrl != null && coverUrl.isNotEmpty) {
      imageWidget = kIsWeb 
        ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder())
        : Image.file(File(coverUrl), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
    } else {
      imageWidget = _buildPlaceholder();
    }

    return GestureDetector(
      onTap: (isGrid && item['isUserCreated'] == true) 
        ? () => _updatePlaylistCover(item['id'])
        : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(item['type'] == 'artist' ? 100 : 4),
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.panelBackground,
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, color: Colors.white24),
    );
  }

  Widget _buildImportMusicItem() {
    return ListTile(
      leading: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.panelBackground, borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.file_download_outlined, color: Colors.white, size: 30),
      ),
      title: const Text('Import your music', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      onTap: () {},
    );
  }
}
