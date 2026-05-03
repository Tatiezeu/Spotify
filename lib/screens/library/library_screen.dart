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
  String _selectedFilter = 'All';
  final List<String> _filters = ['Playlists', 'Artists', 'Albums', 'Downloaded'];
  final List<String> _subFilters = ['By you', 'By Spotify', 'Mixed'];
  bool _isGridView = true;
  bool _isSearchingInLibrary = false;
  bool _isLoading = false;
  final TextEditingController _librarySearchController = TextEditingController();
  String _librarySearchText = '';
  StreamSubscription? _playlistSub;
  String _selectedSort = 'By you';
  bool _isSortAscending = true;
  String? _likedSongsCoverPath;

  List<Map<String, dynamic>> _libraryData = [
    {'title': 'Liked Songs', 'subtitle': 'Playlist • 725 songs', 'type': 'playlist', 'isPinned': true, 'isLiked': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
    _loadLikedSongsCover();
    _playlistSub = ApiService().onPlaylistsChanged.listen((_) {
      _fetchLibrary();
    });
  }

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

  Future<void> _fetchLibrary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final playlists = await ApiService().getPlaylists();
      final likedSongs = await ApiService().getLikedSongs();
      if (!mounted) return;
      setState(() {
        _libraryData = [
          {'title': 'Liked Songs', 'subtitle': 'Playlist • ${likedSongs.length} songs', 'type': 'playlist', 'isPinned': true, 'isLiked': true},
        ];
        
        for (var playlist in playlists) {
          _libraryData.add({
            'id': playlist.id,
            'title': playlist.name,
            'subtitle': 'Playlist • ${playlist.trackCount} songs',
            'type': 'playlist',
            'coverUrl': playlist.coverUrl,
            'isUserCreated': true,
          });
        }
      });
    } catch (e) {
      debugPrint('Error fetching library: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePlaylistCover(String playlistId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      // For now, we'll use the path as the coverUrl. 
      // In a real app, you'd upload this to a server (e.g. S3, Cloudinary).
      final success = await ApiService().updatePlaylistCover(playlistId, pickedFile.path);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist cover updated!')),
        );
        _fetchLibrary();
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_libraryData);
    
    // 1. Filter by type
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Downloaded') {
        filtered = filtered.where((item) => item['type'] == 'downloaded').toList();
      } else {
        final filterType = _selectedFilter.toLowerCase().replaceAll('s', '');
        filtered = filtered.where((item) => item['type'] == filterType).toList();
      }
    }

    // 2. Search
    if (_librarySearchText.isNotEmpty) {
      filtered = filtered.where((item) => 
        item['title'].toLowerCase().contains(_librarySearchText.toLowerCase())
      ).toList();
    }

    // 3. Sort
    switch (_selectedSort) {
      case 'Recently added':
        // Default order from API/DB is usually chronological (reverse of insertion)
        break;
      case 'Alphabetical':
        filtered.sort((a, b) => (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase()));
        if (!_isSortAscending) filtered = filtered.reversed.toList();
        break;
      case 'By Artist':
        filtered.sort((a, b) {
          final aSub = (a['subtitle'] as String).toLowerCase();
          final bSub = (b['subtitle'] as String).toLowerCase();
          return aSub.compareTo(bSub);
        });
        break;
      default: // 'By you'
        // Keep original order
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

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(color: Colors.white10),
            _buildSortOption('By you'),
            _buildSortOption('Recently added'),
            _buildSortOption('Alphabetical'),
            _buildSortOption('By Artist'),
            const SizedBox(height: 24),
          ],
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

  void _showCreateMenu() {
    CreateMenuBottomSheet.show(context);
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
            child: _isGridView ? _buildGridView() : _buildListView(),
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
          borderRadius: BorderRadius.circular(4),
        ),
        child: TextField(
          controller: _librarySearchController,
          onChanged: (value) => setState(() => _librarySearchText = value),
          style: const TextStyle(fontSize: 14),
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
            icon: const Icon(Icons.search, size: 28), 
            onPressed: () => setState(() => _isSearchingInLibrary = !_isSearchingInLibrary)
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28), 
            onPressed: () {
              Navigator.pushNamed(context, '/playlist/create').then((_) => _fetchLibrary());
            }
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
              child: Text(filter, style: const TextStyle(fontSize: 13)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistScreen(
                      playlistId: item['id'],
                      title: item['title'],
                      isLikedSongs: item['isLiked'] == true,
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
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF282828),
                        title: const Text('Delete Playlist?'),
                        content: Text('Are you sure you want to delete "${item['title']}"?'),
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
                  },
                ),
              ),
          ],
        );
      },
    );
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
        const Text('Import your music', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildLibraryListItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildItemImage(item),
      title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Row(
        children: [
          if (item['isPinned'] == true)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.push_pin, color: AppColors.spotifyGreen, size: 14),
            ),
          Text(item['subtitle'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        ],
      ),
      trailing: item['isUserCreated'] == true ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF282828),
              title: const Text('Delete Playlist?'),
              content: Text('Are you sure you want to delete "${item['title']}"?'),
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
        },
      ) : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistScreen(
              playlistId: item['id'],
              title: item['title'],
              isLikedSongs: item['isLiked'] == true,
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
        Text(item['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        Row(
          children: [
            if (item['isPinned'] == true)
              const Icon(Icons.push_pin, color: AppColors.spotifyGreen, size: 10),
            if (item['isMixed'] == true)
              const Icon(Icons.tune, color: Colors.white70, size: 10),
            const SizedBox(width: 4),
            Expanded(child: Text(item['subtitle'] ?? '', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: backgroundImage ?? const Icon(Icons.favorite, color: Colors.white, size: 30),
          ),
        ),
      );
    }
    
    Widget imageWidget;
    String? coverUrl = item['coverUrl'];
    
    if (coverUrl != null && (coverUrl.startsWith('http') || coverUrl.startsWith('blob'))) {
      imageWidget = Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (coverUrl != null && coverUrl.isNotEmpty) {
      // Local file path
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
      title: const Text('Import your music', style: TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {},
    );
  }
}
