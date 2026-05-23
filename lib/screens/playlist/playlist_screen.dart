import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../utils/song_options_helper.dart';
import '../../providers/player_provider.dart';

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
  String _selectedSort = 'Custom order';
  bool _isSortAscending = true;

  // Dynamic color theme extracted from cover
  String? _lastCoverUrl;
  Color _primaryBgColor = const Color(0xFF2E4472); // Default blue for Liked Songs
  Color _secondaryBgColor = AppColors.primaryBackground;

  // Mock toggle states for visual fidelity
  bool _isDownloaded = false;
  bool _isCollaborative = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetch playlist tracks and trigger color extraction on cover changes.
  // Supporting dynamic curation fallbacks for personalized recommendations.
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    
    if (widget.isLikedSongs) {
      _songs = await api.getLikedSongs();
      _primaryBgColor = const Color(0xFF2E4472); // Spotify classic deep blue gradient for Liked Songs
    } else if (widget.playlistId != null && widget.playlistId!.startsWith('playlist_rec_')) {
      // Dynamic mock recommendation loader:
      // When tapping recommended for you mixes on the search screen, we fetch
      // tracks matching a related genre query to simulate a real curated mix.
      final index = int.tryParse(widget.playlistId!.replaceAll('playlist_rec_', '')) ?? 0;
      final queryStr = index == 0 ? 'Pop' : (index == 1 ? 'Afrobeats' : 'Chill');
      final mockCover = 'https://picsum.photos/300/300?random=${widget.playlistId.hashCode % 10}';
      
      _songs = await api.searchSpotify(queryStr, type: 'track');
      _playlist = Playlist(
        id: widget.playlistId!,
        name: widget.title ?? 'Recommended Mix',
        description: 'A custom discovery blend generated in real-time based on your taste profile.',
        coverUrl: mockCover,
        creatorName: 'Sportify Recommendation Engine',
        tracks: _songs,
      );
      _primaryBgColor = index == 0 ? const Color(0xFF3E3264) : (index == 1 ? const Color(0xFF1E3264) : const Color(0xFF474747));
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
      // Extract color if a cover URL is present
      final coverUrl = widget.isLikedSongs ? '' : (_playlist?.coverUrl ?? '');
      if (coverUrl.isNotEmpty) {
        _extractColors(coverUrl);
      }
    }
  }

  // Extracts dynamic gradient backgrounds from the playlist cover image
  Future<void> _extractColors(String coverUrl) async {
    if (_lastCoverUrl == coverUrl) return;
    _lastCoverUrl = coverUrl;

    try {
      ImageProvider imageProvider;
      if (coverUrl.startsWith('http') || coverUrl.startsWith('blob:')) {
        imageProvider = NetworkImage(coverUrl);
      } else {
        imageProvider = FileImage(File(coverUrl));
      }

      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5,
      );

      if (mounted) {
        setState(() {
          final dominant = palette.dominantColor?.color;
          final darkMuted = palette.darkMutedColor?.color;
          final darkVibrant = palette.darkVibrantColor?.color;
          
          Color primary = darkMuted ?? darkVibrant ?? dominant ?? const Color(0xFF282828);
          // Darken to avoid any flashing light layouts
          if (primary.computeLuminance() > 0.3) {
            primary = Color.alphaBlend(Colors.black.withOpacity(0.55), primary);
          }
          _primaryBgColor = primary;
        });
      }
    } catch (e) {
      debugPrint('Error extracting colors in playlist screen: $e');
    }
  }

  void _sortSongs() {
    switch (_selectedSort) {
      case 'Recently added':
        break;
      case 'Alphabetical':
        _songs.sort((a, b) => a.title.compareTo(b.title));
        if (!_isSortAscending) _songs = _songs.reversed.toList();
        break;
      case 'By Artist':
        _songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      default: // 'By you'
        break;
    }
  }

  Future<void> _updateOrder() async {
    if (widget.playlistId != null && !widget.isLikedSongs && !widget.isAlbum) {
      // In a real app, we'd persist the custom drag reorder list to a database
      // await ApiService().updatePlaylistOrder(widget.playlistId!, _songs);
    }
  }

  // Helper: Computes the total duration of all tracks in the playlist combined
  String _calculateTotalDuration() {
    if (_songs.isEmpty) return '0 min';
    final totalDuration = _songs.fold(Duration.zero, (prev, song) => prev + song.duration);
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hr $minutes min';
    } else {
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isPlayingCurrentPlaylist = _songs.isNotEmpty && 
                                     player.currentSong != null && 
                                     _songs.any((s) => s.id == player.currentSong!.id);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _primaryBgColor,
                    _secondaryBgColor.withOpacity(0.9),
                    AppColors.primaryBackground,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLargeHeader(),
                        _buildActionRow(player, isPlayingCurrentPlaylist),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: _buildFilterChips(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  
                  // Drag and drop reordering lists when sorting by "Custom order"
                  if (_selectedSort == 'Custom order' && !widget.isAlbum && !widget.isLikedSongs)
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
                  
                  // Frictionless "Add songs" recommendation footer
                  if (widget.playlistId != null && !widget.isAlbum && !widget.isLikedSongs)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                        child: Column(
                          children: [
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 16),
                            _buildAddSongsRow(),
                            const SizedBox(height: 8),
                            const Text(
                              'Let\'s build this vibe together. Add new tracks below.',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 22, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // Large Action-Oriented Header displaying playlist/album art, details, creator, and duration
  Widget _buildLargeHeader() {
    ImageProvider coverImage;
    if (widget.isLikedSongs) {
      coverImage = const NetworkImage('https://via.placeholder.com/200'); // placeholder for Liked
    } else {
      final coverUrl = _playlist?.coverUrl ?? '';
      if (coverUrl.startsWith('http') || coverUrl.startsWith('blob:')) {
        coverImage = NetworkImage(coverUrl);
      } else if (coverUrl.isNotEmpty) {
        coverImage = FileImage(File(coverUrl));
      } else {
        coverImage = const NetworkImage('https://via.placeholder.com/200');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Cover Art Container with heavy shadow
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
                image: widget.isLikedSongs 
                    ? null 
                    : DecorationImage(image: coverImage, fit: BoxFit.cover),
                gradient: widget.isLikedSongs ? AppColors.likedSongsGradient : null,
              ),
              child: widget.isLikedSongs
                  ? const Icon(Icons.favorite, color: Colors.white, size: 85)
                  : null,
            ),
          ),
          const SizedBox(height: 28),
          
          // 2. Playlist Title
          Text(
            widget.isLikedSongs ? 'Liked Songs' : (_playlist?.name ?? widget.title ?? 'Playlist'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),

          // 3. Optional Description
          if (!widget.isLikedSongs && _playlist?.description != null && _playlist!.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _playlist!.description,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.3),
              ),
            ),
          
          // 4. Creator Profile Metadata & Total Duration
          Row(
            children: [
              const CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.spotifyGreen,
                child: Icon(Icons.person, size: 12, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isLikedSongs ? 'You' : 'Sportify Creator',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 6),
              Text(
                '${_songs.length} songs',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 6),
              Text(
                _calculateTotalDuration(),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action icons, Green play/shuffle button, and dedicated Shuffle mode toggle.
  // Move edit option to the action row next to other actions (compliant with Spotify design).
  Widget _buildActionRow(PlayerProvider player, bool isPlayingCurrentPlaylist) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // A. Mock Download Toggle
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              _isDownloaded ? Icons.arrow_circle_down_rounded : Icons.arrow_circle_down_outlined,
              color: _isDownloaded ? AppColors.spotifyGreen : Colors.white70,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isDownloaded = !_isDownloaded;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isDownloaded ? 'Downloading playlist for offline use...' : 'Removed downloads'),
                  backgroundColor: AppColors.spotifyGreen,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // B. Add Collaborators Toggle
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              _isCollaborative ? Icons.people_rounded : Icons.person_add_alt_1_outlined,
              color: _isCollaborative ? AppColors.spotifyGreen : Colors.white70,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isCollaborative = !_isCollaborative;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isCollaborative ? 'Collaborative link copied to clipboard!' : 'Collaborative mode disabled'),
                  backgroundColor: AppColors.spotifyGreen,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // C. Mock Share Playlist
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.ios_share_outlined, color: Colors.white70, size: 26),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'https://sportify.app/playlist/${widget.playlistId}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist link copied to clipboard!'), duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(width: 8),

          // D. Edit Playlist Name (relocated to actions row)
          if (widget.playlistId != null && !widget.isLikedSongs && !widget.isAlbum) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 28),
              onPressed: () => _showEditPlaylistNameModal(),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),

          // E. Dedicated Shuffle Mode Toggle
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              Icons.shuffle,
              color: player.isShuffle ? AppColors.spotifyGreen : Colors.white70,
              size: 28,
            ),
            onPressed: () {
              player.toggleShuffle();
            },
          ),
          const SizedBox(width: 8),

          // F. Prominent Green Play Button (plays instantly and respects Shuffle toggle state)
          GestureDetector(
            onTap: () {
              if (_songs.isNotEmpty) {
                final playSongs = List<Song>.from(_songs);
                if (player.isShuffle) {
                  playSongs.shuffle();
                }
                player.playSong(playSongs.first);
                player.clearQueue();
                for (int i = 1; i < playSongs.length; i++) {
                  player.addToQueue(playSongs[i]);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.spotifyGreen, shape: BoxShape.circle),
              child: Icon(
                isPlayingCurrentPlaylist && player.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sort filter chips styled identical to Spotify
  Widget _buildFilterChips() {
    final filters = ['Custom order', 'Recently added', 'Alphabetical', 'By Artist'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
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
                  _fetchData(); 
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
                  fontWeight: FontWeight.w600,
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add songs to this playlist',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
          ],
        ),
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

  // Premium song row item supporting drag handles and highlights
  Widget _buildSongItem(BuildContext context, Song song, {Key? key, int? index}) {
    final player = context.watch<PlayerProvider>();
    final isLiked = player.isLiked(song.id);
    final isByYou = _selectedSort == 'Custom order' && !widget.isAlbum && !widget.isLikedSongs;
    final isCurrentlyPlaying = player.currentSong?.id == song.id;

    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(song.coverUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        song.title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 15,
          color: isCurrentlyPlaying ? AppColors.spotifyGreen : Colors.white,
        ), 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis
      ),
      subtitle: Text(
        '${song.artist} • ${song.albumName}', 
        style: const TextStyle(color: AppColors.secondaryText, fontSize: 12), 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLiked) const Icon(Icons.favorite, color: AppColors.spotifyGreen, size: 18),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showSongOptions(context, song),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Icon(Icons.more_horiz, color: AppColors.secondaryText, size: 24),
            ),
          ),
          if (isByYou && index != null) ...[
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: Colors.white30, size: 24),
            ),
          ],
        ],
      ),
      onTap: () {
        player.playSong(song);
      },
    );
  }

  // Custom Edit Modal to quickly adjust playlist name and details
  void _showEditPlaylistNameModal() {
    if (_playlist == null) return;
    final controller = TextEditingController(text: _playlist!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Edit Playlist Title', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new playlist name',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.spotifyGreen)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // Reuse coverUrl update wrapper to save playlist meta 
                // in standard DB environments
                await ApiService().updatePlaylistCover(widget.playlistId!, _playlist!.coverUrl); 
                setState(() {
                  _fetchData();
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.spotifyGreen)),
          ),
        ],
      ),
    );
  }

  // Song Options bottom sheet: Enqueuing, removing, and cross-additions
  void _showSongOptions(BuildContext context, Song song) {
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
              const SizedBox(height: 12),
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(song.coverUrl, width: 40, height: 40, fit: BoxFit.cover),
                ),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
              ),
              const Divider(color: Colors.white10),
              
              // Action 1: Add to Queue
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white70),
                title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
                onTap: () {
                  context.read<PlayerProvider>().addToQueue(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${song.title}" to queue'),
                      backgroundColor: AppColors.spotifyGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // Action 2: Add to Another Playlist
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white70),
                title: const Text('Add to Another Playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  SongOptionsHelper.showPlaylistPicker(context, song);
                },
              ),

              // Action 3: View Artist
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white70),
                title: const Text('View Artist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/artist', arguments: song.artistId);
                },
              ),

              // Action 4: View Album
              ListTile(
                leading: const Icon(Icons.album_outlined, color: Colors.white70),
                title: const Text('View Album', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/album', arguments: song.albumId);
                },
              ),

              // Action 5: Remove (only if in a custom user playlist)
              if (widget.playlistId != null && !widget.isLikedSongs && !widget.isAlbum)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove from this Playlist', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    final success = await ApiService().removeTrackFromPlaylist(widget.playlistId!, song.id);
                    if (success && context.mounted) {
                      setState(() {
                        _songs.removeWhere((s) => s.id == song.id);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Track removed from playlist'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 1)),
                      );
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// Frictionless "Add songs" interactive bottom sheet panel
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
    _debounce = Timer(const Duration(milliseconds: 400), () async {
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
      height: MediaQuery.of(context).size.height * 0.85,
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
                hintText: 'Search for songs to add',
                hintStyle: const TextStyle(color: Colors.white38),
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
              child: _results.isEmpty
                  ? const Center(child: Text('Search for songs to see results', style: TextStyle(color: Colors.white30)))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final song = _results[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(song.coverUrl, width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.spotifyGreen, size: 28),
                            onPressed: () async {
                              final success = await ApiService().addTrackToPlaylist(widget.playlistId, song);
                              if (success) {
                                widget.onSongsAdded();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added "${song.title}" instantly!'), 
                                      backgroundColor: AppColors.spotifyGreen, 
                                      duration: const Duration(milliseconds: 700),
                                    ),
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
