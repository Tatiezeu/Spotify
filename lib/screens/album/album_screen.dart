import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/song_row.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../utils/song_options_helper.dart';
import '../../providers/player_provider.dart';
import 'package:provider/provider.dart';
import '../player/now_playing_screen.dart';
import '../../services/api_service.dart';

class AlbumScreen extends StatefulWidget {
  final String? albumId;
  final String? title;
  final String? artistName;
  final String? coverUrl;

  const AlbumScreen({super.key, this.albumId, this.title, this.artistName, this.coverUrl});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  bool _isSaved = false;
  bool _isLoading = true;
  List<Song> _tracks = [];
  String? _savedPlaylistId;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    if (widget.albumId == null) return;
    try {
      final songs = await ApiService().getAlbumTracks(widget.albumId!);
      final playlists = await ApiService().getPlaylists();
      final albumPlaylist = playlists.firstWhere(
        (p) => p.name == widget.title && p.description == 'ALBUM_SAVED',
        orElse: () => Playlist(id: '', name: '', description: '', coverUrl: '', creatorName: '', tracks: []),
      );

      if (mounted) {
        setState(() {
          _tracks = songs;
          _isSaved = albumPlaylist.id.isNotEmpty;
          _savedPlaylistId = albumPlaylist.id.isNotEmpty ? albumPlaylist.id : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaved && _savedPlaylistId != null) {
      final success = await ApiService().deletePlaylist(_savedPlaylistId!);
      if (success && mounted) {
        setState(() {
          _isSaved = false;
          _savedPlaylistId = null;
        });
      }
    } else {
      if (_tracks.isEmpty) return;
      final success = await ApiService().saveFullAlbum(
        widget.title ?? 'Unknown Album',
        _tracks.first.coverUrl,
        _tracks,
      );
      if (success && mounted) {
        _fetchTracks(); // Refetch to get the new playlist ID
      }
    }
  }

  String get _totalDuration {
    final total = _tracks.fold<Duration>(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );
    return '${total.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.primaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.withOpacity(0.6),
                      AppColors.primaryBackground,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          widget.coverUrl ?? (_tracks.isNotEmpty ? _tracks.first.coverUrl : 'https://picsum.photos/400'),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.cardBackground,
                              child: const Icon(
                                Icons.album,
                                size: 80,
                                color: AppColors.secondaryText,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            widget.title ?? 'Album Title',
                            style: AppTextStyles.headingLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.cardBackground,
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.artistName ?? (_tracks.isNotEmpty ? _tracks.first.artist : 'Artist Name'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Album • ${_tracks.length} songs • $_totalDuration',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          color: _isSaved
                              ? AppColors.spotifyGreen
                              : AppColors.primaryText,
                        ),
                        onPressed: _toggleSave,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          color: AppColors.secondaryText.withOpacity(0.3),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Upgrade to Premium to download'),
                              backgroundColor: AppColors.panelBackground,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (_tracks.isEmpty) return;
                          final player = context.read<PlayerProvider>();
                          final shuffled = List<Song>.from(_tracks)..shuffle();
                          player.playSong(shuffled.first);
                          player.setQueue(shuffled.sublist(1));
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NowPlayingScreen(song: shuffled.first)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.spotifyGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(500),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shuffle),
                            const SizedBox(width: 8),
                            Text(
                              'Shuffle Play',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                    return SongRow(
                      song: _tracks[index],
                      showAlbumArt: false,
                      showTrackNumber: true,
                      trackNumber: index + 1,
                      onTap: () {
                        final player = context.read<PlayerProvider>();
                        player.playSong(_tracks[index]);
                        // Add remaining tracks to queue
                        if (index < _tracks.length - 1) {
                          player.setQueue(_tracks.sublist(index + 1));
                        } else {
                          player.setQueue([]);
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (context) => NowPlayingScreen(song: _tracks[index])));
                      },
                      onMenuTap: () {
                        SongOptionsHelper.showSongOptions(context, _tracks[index]);
                      },
                    );
                  },
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
