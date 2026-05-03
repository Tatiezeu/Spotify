import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../utils/song_options_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import 'dart:async';

class PlaylistScreen extends StatefulWidget {
  final bool isLikedSongs;
  final String? title;
  final String? playlistId;
  final bool isAlbum;

  const PlaylistScreen({
    super.key, 
    this.isLikedSongs = false, 
    this.title,
    this.playlistId,
    this.isAlbum = false,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isLoading = true;
  Playlist? _playlist;
  List<Song> _songs = [];
  String _selectedSort = 'By you';
  bool _isSortAscending = true;

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
    } else if (widget.isAlbum && widget.playlistId != null) {
      _songs = await api.getAlbumTracks(widget.playlistId!);
    } else if (widget.playlistId != null) {
      _playlist = await api.getPlaylist(widget.playlistId!);
      if (_playlist != null) {
        _songs = _playlist!.tracks;
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _sortSongs();
      });
    }
  }

  void _sortSongs() {
    switch (_selectedSort) {
      case 'Recently added':
        // Default from DB
        break;
      case 'Alphabetical':
        _songs.sort((a, b) => a.title.compareTo(b.title));
        if (!_isSortAscending) _songs = _songs.reversed.toList();
        break;
      case 'By Artist':
        _songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      default: // 'By you'
        // Keep as is or load custom order if implemented
        break;
    }
  }

  Future<void> _updateOrder() async {
    if (widget.playlistId != null && !widget.isLikedSongs && !widget.isAlbum) {
      // In a real app, we'd send the new order to the backend
      // await ApiService().updatePlaylistOrder(widget.playlistId!, _songs);
    }
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
                if (_selectedSort == 'By you' && !widget.isAlbum && !widget.isLikedSongs)
                  SliverReorderableList(
                    itemBuilder: (context, index) => _buildSongItem(context, _songs[index], key: ValueKey(_songs[index].id), index: index),
                    itemCount: _songs.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _songs.removeAt(oldIndex);
                        _songs.insert(newIndex, item);
                        _updateOrder();
                      });
                    },
                  )
                else
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
    final filters = ['By you', 'Recently added', 'Alphabetical', 'By Artist'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedSort == filter;
          return GestureDetector(
            onTap: () {
              if (filter == 'Alphabetical' && isSelected) {
                setState(() {
                  _isSortAscending = !_isSortAscending;
                  _sortSongs();
                });
              } else {
                setState(() {
                  _selectedSort = filter;
                  _isSortAscending = true;
                  _fetchData(); // Refetch to reset order for others
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.spotifyGreen : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter == 'Alphabetical' && isSelected 
                  ? 'Alphabetical ${_isSortAscending ? "↓" : "↑"}' 
                  : filter, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddSongsRow() {
    return GestureDetector(
      onTap: widget.playlistId != null ? () => _showAddSongsSearch(context) : null,
      child: Row(
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
      ),
    );
  }

  void _showAddSongsSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _AddSongsSearchSheet(
        playlistId: widget.playlistId!,
        onSongsAdded: () {
          _fetchData();
          ApiService().notifyPlaylistsChanged();
        },
      ),
    );
  }

  Widget _buildSongItem(BuildContext context, Song song, {Key? key, int? index}) {
    final player = context.watch<PlayerProvider>();
    final isLiked = player.isLiked(song.id);
    final isByYou = _selectedSort == 'By you' && !widget.isAlbum && !widget.isLikedSongs;

    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(song.coverUrl, width: 52, height: 52, fit: BoxFit.cover),
      ),
      title: Text(song.title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: player.currentSong?.id == song.id ? AppColors.spotifyGreen : Colors.white,
        ), 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis
      ),
      subtitle: Text(song.artist, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLiked) const Icon(Icons.favorite, color: AppColors.spotifyGreen, size: 20),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.secondaryText),
            onPressed: () => _showSongOptions(context, song),
          ),
          if (isByYou && index != null)
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.menu, color: Colors.white54),
            ),
        ],
      ),
      onTap: () {
        context.read<PlayerProvider>().playSong(song);
      },
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    SongOptionsHelper.showSongOptions(
      context, 
      song,
      playlistId: (widget.isLikedSongs || widget.isAlbum) ? null : widget.playlistId,
      onRemove: () {
        setState(() {
          _songs.removeWhere((s) => s.id == song.id);
        });
      },
    );
  }

  void _showPlaylistPicker(BuildContext context, Song song) {
    SongOptionsHelper.showPlaylistPicker(context, song);
  }
}

class _AddSongsSearchSheet extends StatefulWidget {
  final String playlistId;
  final VoidCallback onSongsAdded;

  const _AddSongsSearchSheet({required this.playlistId, required this.onSongsAdded});

  @override
  State<_AddSongsSearchSheet> createState() => _AddSongsSearchSheetState();
}

class _AddSongsSearchSheetState extends State<_AddSongsSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Song> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _results = []);
        return;
      }
      setState(() => _isLoading = true);
      try {
        final results = await Future.wait([
          ApiService().searchSpotify(query, type: 'track'),
          ApiService().searchDeezer(query),
        ]);
        if (mounted) setState(() => _results = [...results[0], ...results[1]]);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for songs',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final song = _results[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(song.coverUrl, width: 44, height: 44, fit: BoxFit.cover),
                    ),
                    title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(song.artist),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                      onPressed: () async {
                        final success = await ApiService().addTrackToPlaylist(widget.playlistId, song);
                        if (success) {
                          widget.onSongsAdded();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${song.title}'), backgroundColor: AppColors.spotifyGreen, duration: const Duration(seconds: 1)),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
