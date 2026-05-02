import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/create_menu_bottom_sheet.dart';
import '../playlist/playlist_screen.dart';
import '../../services/api_service.dart';

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

  List<Map<String, dynamic>> _libraryData = [
    {'title': 'Liked Songs', 'subtitle': 'Playlist • 725 songs', 'type': 'playlist', 'isPinned': true, 'isLiked': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
  }

  Future<void> _fetchLibrary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final playlists = await ApiService().getPlaylists();
      if (!mounted) return;
      setState(() {
        _libraryData = [
          {'title': 'Liked Songs', 'subtitle': 'Playlist • 725 songs', 'type': 'playlist', 'isPinned': true, 'isLiked': true},
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

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_libraryData);
    
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Downloaded') {
        filtered = filtered.where((item) => item['type'] == 'downloaded').toList();
      } else {
        final filterType = _selectedFilter.toLowerCase().replaceAll('s', '');
        filtered = filtered.where((item) => item['type'] == filterType).toList();
      }
    }

    if (_librarySearchText.isNotEmpty) {
      filtered = filtered.where((item) => 
        item['title'].toLowerCase().contains(_librarySearchText.toLowerCase())
      ).toList();
    }

    return filtered;
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
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.panelBackground,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryBackground, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
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
          Row(
            children: [
              const Icon(Icons.swap_vert, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_selectedFilter == 'Downloaded' ? 'Recently added' : 'Recents', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
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
        Expanded(child: _buildItemImage(item)),
        const SizedBox(height: 8),
        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        Row(
          children: [
            if (item['isPinned'] == true)
              const Icon(Icons.push_pin, color: AppColors.spotifyGreen, size: 10),
            if (item['isMixed'] == true)
              const Icon(Icons.tune, color: Colors.white70, size: 10),
            const SizedBox(width: 4),
            Expanded(child: Text(item['subtitle'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemImage(Map<String, dynamic> item) {
    if (item['isLiked'] == true) {
      return Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.likedSongsGradient,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 30),
      );
    }
    if (item['isLocal'] == true) {
      return Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: const Color(0xFF1B2A4A), borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.folder, color: AppColors.spotifyGreen, size: 30),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(item['type'] == 'artist' ? 100 : 4),
      child: Image.network(
        item['coverUrl'] ?? 'https://picsum.photos/200?random=${item['title']}',
        width: 64, height: 64, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 64, height: 64,
          color: AppColors.panelBackground,
          child: const Icon(Icons.music_note, color: Colors.white24),
        ),
      ),
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
